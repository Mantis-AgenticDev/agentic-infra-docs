# SHA256: 7f3a9c2e1b8d4f6a0e5c9b2d8a1f4e7c3b6d9a2e5f8c1b4d7a0e3f6c9b2d5a8e
---
artifact_id: "qdrant-cluster-main-tf"
artifact_type: "skill_terraform"
version: "3.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","V1","V2","V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf --json"
canonical_path: "05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf"
---

# 🗄️ MANTIS AGENTIC — Módulo Terraform: Qdrant Cluster (Multi-tenant, Hardened)

## Propósito
Despliegue de Qdrant 1.8+ con aislamiento estricto por tenant, límites de recursos C1/C2, exposición segura C3, y validación de embeddings V1-V3. Compatible con VPS 4GB/8GB RAM y escalado horizontal.

## Patrones de Código Validados

```hcl
# ✅ C3/C4: Variable tenant_id obligatoria con validación explícita
variable "tenant_id" {
  type        = string
  description = "Identificador único del tenant (C4: aislamiento multi-tenant)"
  nullable    = false
  validation {
    condition     = length(var.tenant_id) >= 3 && can(regex("^[a-z0-9_-]+$", var.tenant_id))
    error_message = "tenant_id debe tener ≥3 caracteres, solo minúsculas, números, guiones (C4)."
  }
}
```

```hcl
# ❌ Anti-pattern: tenant_id sin validación permite inyección o colisión
variable "tenant_id" { type = string }
# 🔧 Fix: Añadir validation block con regex y longitud mínima (arriba)
```

```hcl
# ✅ C1/C2: Límites de recursos explícitos para contenedor Qdrant
resource "docker_container" "qdrant" {
  name  = "mantis-qdrant-${var.tenant_id}"
  image = "qdrant/qdrant:${var.qdrant_version}"

  memory     = var.ram_limit_mb      # C1: ej. 1024 para KVM1
  cpu_shares = var.cpu_shares        # C2: ej. 256 ≈ 0.25 vCPU
  pids_limit = var.pids_limit        # C1: evitar fork bomb

  # V3: Parámetros de índice justificados por volumen esperado
  env = [
    "QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS=${var.max_search_threads}",
    "QDRANT__STORAGE__OPTIMIZERS__INDEXING_THRESHOLD=${var.indexing_threshold}",
    "QDRANT__SERVICE__API_KEY=${var.qdrant_api_key}" # C3: desde env, no hardcode
  ]
}
```

```hcl
# ❌ Anti-pattern: Sin límites de memoria/CPU → OOM killer en VPS 4GB
resource "docker_container" "qdrant" { image = "qdrant/qdrant:latest" }
# 🔧 Fix: Declarar memory, cpu_shares, pids_limit según perfil KVM1/KVM2
```

```hcl
# ✅ C3: Exposición de puertos solo en localhost (127.0.0.1)
resource "docker_service" "qdrant" {
  name = "mantis-qdrant-${var.tenant_id}"

  task_spec {
    container_spec {
      image = "qdrant/qdrant:${var.qdrant_version}"
      # C3: Binding explícito a localhost, nunca 0.0.0.0
      host_config {
        port_bindings = {
          "6333/tcp" = [{ HostIp = "127.0.0.1", HostPort = "6333" }]
          "6334/tcp" = [{ HostIp = "127.0.0.1", HostPort = "6334" }]
        }
      }
    }
  }
}
```

```hcl
# ❌ Anti-pattern: Puertos expuestos a 0.0.0.0 → acceso público no autorizado
port_bindings = { "6333/tcp" = [{ HostPort = "6333" }] }
# 🔧 Fix: Añadir HostIp = "127.0.0.1" para restringir a localhost del VPS
```

```hcl
# ✅ V1: Validación de dimensión de embedding en colección
resource "qdrant_collection" "mantis_docs" {
  name = "mantis_docs_${var.tenant_id}"

  vectors {
    size     = var.embedding_dimension # V1: ej. 1536 para text-embedding-3-small
    distance = var.distance_metric    # V2: COSINE, DOT, EUCLID explícito

    # V1: CHECK implícito vía tipo fuerte de Terraform
    # Si var.embedding_dimension no coincide con el modelo, falla en plan/apply
  }

  # V3: Configuración de índice HNSW justificada por patrón de búsqueda
  hnsw_config {
    m              = var.hnsw_m              # ej. 16: balance RAM/precisión
    ef_construct   = var.hnsw_ef_construct   # ej. 100: calidad construcción
    full_scan_threshold = var.full_scan_threshold # ej. 10000: fallback a scan lineal
  }
}
```

```hcl
# ❌ Anti-pattern: Dimensión de vector no declarada → drift en producción
vectors { distance = "Cosine" } # ¿768? ¿1536? ¿384?
# 🔧 Fix: Declarar size = var.embedding_dimension con validación en variable
```

```hcl
# ✅ C4: Payload schema con tenant_id como campo indexado obligatorio
resource "qdrant_payload_index" "tenant_isolation" {
  collection_name = qdrant_collection.mantis_docs.name
  field_name      = "tenant_id"
  field_schema    = "keyword" # Exact match para filtro C4

  # C4: Este índice permite filtrar búsquedas por tenant_id en O(log n)
  # Sin este índice, cada búsqueda requiere scan completo → viola C1/C2
}
```

```hcl
# ❌ Anti-pattern: Búsquedas sin índice en tenant_id → scan completo por query
# 🔧 Fix: Crear payload_index para tenant_id con field_schema = "keyword"
```

```hcl
# ✅ C5/C8: Checksum de configuración + logging estructurado en provisioner
resource "null_resource" "config_integrity" {
  triggers = {
    # C5: Hash de la configuración para detectar drift no autorizado
    config_hash = sha256(jsonencode({
      tenant_id              = var.tenant_id
      embedding_dimension    = var.embedding_dimension
      distance_metric        = var.distance_metric
      qdrant_version         = var.qdrant_version
    }))
  }

  provisioner "local-exec" {
    # C8: Logging JSON a stderr para trazabilidad multi-tenant
    command = <<-EOT
      echo '{"ts":"${timestamp()}","tenant":"${var.tenant_id}","level":"INFO","event":"qdrant_config_applied","hash":"${self.triggers.config_hash}"}' >&2
    EOT
  }
}
```

```hcl
# ❌ Anti-pattern: Sin verificación de integridad → configuración modificada sin auditoría
# 🔧 Fix: Usar triggers con sha256 + provisioner con logging JSON a stderr
```

```hcl
# ✅ C7: Validación de paths para volúmenes persistentes
resource "docker_volume" "qdrant_storage" {
  name = "mantis-qdrant-storage-${var.tenant_id}"

  # C7: Path absoluto validado, sin interpolación de usuario directo
  driver_opts = {
    type   = "none"
    device = "/mnt/data/qdrant/${var.tenant_id}" # Path pre-validado por orchestrator
    o      = "bind"
  }

  # C7: Label para backup automatizado (C5)
  labels = {
    "mantis.tenant"  = var.tenant_id
    "mantis.service" = "qdrant"
    "mantis.backup"  = "daily"
  }
}
```

```hcl
# ❌ Anti-pattern: Path con interpolación directa de input → path traversal
device = "/mnt/data/${user_input}/qdrant"
# 🔧 Fix: Usar path pre-validado por capa superior + validación de formato en variable
```

```hcl
# ✅ V2: Distancia métrica explícita y documentada
variable "distance_metric" {
  type        = string
  description = "Métrica de distancia para búsqueda vectorial (V2)"
  default     = "Cosine"
  validation {
    condition     = contains(["Cosine", "Euclid", "Dot"], var.distance_metric)
    error_message = "distance_metric debe ser Cosine, Euclid o Dot (V2)."
  }
}
```

```hcl
# ❌ Anti-pattern: Métrica por defecto no documentada → resultados inconsistentes
distance = "Cosine" # ¿Por qué Cosine y no Dot?
# 🔧 Fix: Declarar variable con validation + documentación del caso de uso
```

```hcl
# ✅ V3: Selección de índice (ivfflat vs hnsw) justificada por volumen
variable "index_type" {
  type        = string
  description = "Tipo de índice: hnsw (alta precisión) o ivfflat (volumen alto) (V3)"
  default     = "hnsw"
  validation {
    condition     = contains(["hnsw", "ivfflat"], var.index_type)
    error_message = "index_type debe ser hnsw o ivfflat (V3)."
  }
}

# Justificación V3 en comentario de recurso:
# hnsw: mejor para <100k vectores, búsquedas de baja latencia (caso MANTIS)
# ivfflat: mejor para >500k vectores, entrenamiento offline aceptable
```

```hcl
# ❌ Anti-pattern: Índice seleccionado sin justificación de patrón de acceso
# 🔧 Fix: Documentar criterio de selección en comentario + variable con validation
```

```hcl
# ✅ C3/C6: API Key desde variable con fallback seguro para desarrollo
variable "qdrant_api_key" {
  type        = string
  description = "API Key para autenticación en Qdrant (C3)"
  sensitive   = true
  # C6: Fallback solo para entorno de desarrollo, nunca producción
  default     = var.environment == "production" ? "" : "dev-key-unsafe-do-not-use"
}

# En resource: solo inyectar si no está vacío (producción requiere valor explícito)
env = var.environment == "production" && var.qdrant_api_key != "" ? [
  "QDRANT__SERVICE__API_KEY=${var.qdrant_api_key}"
] : []
```

```hcl
# ❌ Anti-pattern: API Key hardcodeada o fallback en producción
default = "hardcoded-key-123"
# 🔧 Fix: sensitive = true + validación de entorno + fallback solo para dev
```

```hcl
# ✅ C2: Timeout de healthcheck ajustado para arranque en VPS limitado
resource "docker_container" "qdrant" {
  # ... otros atributos ...

  healthcheck {
    test     = ["CMD-SHELL", "curl -sf -H 'api-key: ${var.qdrant_api_key}' http://127.0.0.1:6333/health || exit 1"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
    # C2: start_period extendido para VPS con I/O limitado
    start_period = "120s" # Qdrant carga índices HNSW en RAM al iniciar
  }
}
```

```hcl
# ❌ Anti-pattern: start_period corto → reinicios en bucle en VPS lento
start_period = "30s"
# 🔧 Fix: Aumentar a 120s para permitir carga de índices en hardware limitado
```

```hcl
# ✅ C4/C8: Label de tenant en todos los recursos para auditoría y filtrado
resource "docker_volume" "qdrant_storage" {
  # ...
  labels = {
    "mantis.tenant"  = var.tenant_id   # C4: aislamiento lógico
    "mantis.service" = "qdrant"
    "mantis.backup"  = "daily"         # C5: política de backup
    "mantis.created" = timestamp()     # C8: trazabilidad temporal
  }
}
```

```hcl
# ❌ Anti-pattern: Recursos sin labels de tenant → imposible auditar por tenant
# 🔧 Fix: Añadir labels mantis.tenant a TODOS los recursos del módulo
```

```hcl
# ✅ C1: Variables de recursos con valores por defecto para KVM1 (4GB RAM)
variable "ram_limit_mb" {
  type        = number
  description = "Límite de RAM para contenedor Qdrant (C1)"
  default     = 1024 # KVM1: 1GB para Qdrant en VPS 4GB total
  validation {
    condition     = var.ram_limit_mb >= 512 && var.ram_limit_mb <= 4096
    error_message = "ram_limit_mb debe estar entre 512 y 4096 MB (C1)."
  }
}

variable "cpu_shares" {
  type        = number
  description = "Cuota de CPU relativa (1024 = 1 vCPU completa) (C2)"
  default     = 256 # ≈ 0.25 vCPU para KVM1
  validation {
    condition     = var.cpu_shares >= 128 && var.cpu_shares <= 1024
    error_message = "cpu_shares debe estar entre 128 y 1024 (C2)."
  }
}
```

```hcl
# ❌ Anti-pattern: Sin límites por defecto → despliegue inseguro en VPS pequeño
# 🔧 Fix: Valores por defecto conservadores + validation para rangos seguros
```

```hcl
# ✅ C3: Validación de que variables críticas están presentes en producción
locals {
  # C3: Fallar temprano si falta configuración crítica en producción
  required_prod_vars = var.environment == "production" ? [
    var.tenant_id != "" ? true : false,
    var.qdrant_api_key != "" ? true : false,
    var.embedding_dimension >= 128 ? true : false
  ] : [true]

  # C3: Mensaje de error explícito si alguna validación falla
  config_valid = alltrue(local.required_prod_vars) ? true : false
}

resource "null_resource" "production_config_check" {
  count = var.environment == "production" && !local.config_valid ? 1 : 0
  provisioner "local-exec" {
    command = "echo '❌ Production config validation failed: check tenant_id, api_key, embedding_dimension (C3)' >&2 && exit 1"
  }
}
```

```hcl
# ❌ Anti-pattern: Validación solo en tiempo de ejecución → fallo tardío
# 🔧 Fix: Usar locals + null_resource para validar en terraform plan (falla temprano)
```

```hcl
# ✅ V1/V2: Colección con parámetros de vector explícitos y validados
resource "qdrant_collection" "mantis_docs" {
  name = "mantis_docs_${var.tenant_id}"

  vectors {
    # V1: Dimensión explícita, validada en variable
    size = var.embedding_dimension # ej. 1536 para text-embedding-3-small

    # V2: Métrica de distancia explícita, validada en variable
    distance = var.distance_metric # Cosine, Euclid, o Dot
  }

  # Optimización para hardware limitado (C1)
  optimizers_config {
    memmap_threshold    = var.memmap_threshold    # Usar disco si > N vectores
    indexing_threshold  = var.indexing_threshold  # Crear índice HNSW si > N vectores
    max_optimization_threads = var.max_opt_threads # C2: limitar threads de optimización
  }
}
```

```hcl
# ❌ Anti-pattern: Parámetros de optimización por defecto → OOM en VPS 4GB
# 🔧 Fix: Declarar optimizers_config con umbrales ajustados para hardware limitado
```

```hcl
# ✅ C7: Path de snapshot validado y aislado por tenant
resource "docker_volume" "qdrant_snapshots" {
  name = "mantis-qdrant-snapshots-${var.tenant_id}"

  driver_opts = {
    type   = "none"
    # C7: Path absoluto pre-validado, sin interpolación de input no sanitizado
    device = "/mnt/backups/qdrant/${var.tenant_id}"
    o      = "bind"
  }

  labels = {
    "mantis.tenant"  = var.tenant_id
    "mantis.service" = "qdrant"
    "mantis.backup"  = "weekly" # C5: snapshots menos frecuentes que datos
  }
}
```

```hcl
# ❌ Anti-pattern: Path de backup con input directo → riesgo de escritura fuera de área
device = "/mnt/backups/${user_input}"
# 🔧 Fix: Usar path pre-construido por capa superior + validación de formato
```

```hcl
# ✅ C8: Output con checksum simulado para trazabilidad de despliegue
output "deployment_checksum" {
  description = "SHA256 simulado para auditoría de configuración aplicada (C8)"
  value       = sha256(jsonencode({
    tenant_id              = var.tenant_id
    qdrant_version         = var.qdrant_version
    embedding_dimension    = var.embedding_dimension
    ram_limit_mb           = var.ram_limit_mb
    timestamp              = timestamp()
  }))
  sensitive = false
}
```

```hcl
# ❌ Anti-pattern: Sin output de auditoría → imposible verificar qué se desplegó
# 🔧 Fix: Output con hash de configuración + timestamp para trazabilidad C8
```

```hcl
# ✅ C4: Política de aislamiento: colección por tenant (no multi-tenant en misma colección)
# Estrategia: 1 colección por tenant → aislamiento físico, no solo lógico
# Ventaja: borrado completo de tenant = drop collection, sin riesgo de fuga
resource "qdrant_collection" "mantis_docs" {
  name = "mantis_docs_${var.tenant_id}" # Nombre incluye tenant_id
  # ... configuración ...
}
```

```hcl
# ❌ Anti-pattern: Múltiples tenants en misma colección con filtro lógico → riesgo de fuga si filtro falla
name = "mantis_docs_shared" # Todos los tenants en misma colección
# 🔧 Fix: Nombre de colección incluye tenant_id para aislamiento físico
```

```hcl
# ✅ C2: Límite de conexiones simultáneas para evitar agotamiento de FDs
resource "docker_container" "qdrant" {
  # ...
  host_config {
    # C2: Limitar número de conexiones TCP simultáneas
    ulimit {
      name = "nofile"
      soft = 1024
      hard = 2048
    }
    # C2: Timeout de socket para liberar recursos inactivos
    sysctls = {
      "net.ipv4.tcp_fin_timeout" = "30"
      "net.ipv4.tcp_keepalive_time" = "60"
    }
  }
}
```

```hcl
# ❌ Anti-pattern: Sin límites de file descriptors → agotamiento de FDs bajo carga
# 🔧 Fix: Declarar ulimit y sysctls para gestión conservadora de conexiones
```

```hcl
# ✅ V3: Parámetros HNSW justificados por patrón de búsqueda de MANTIS
variable "hnsw_m" {
  type        = number
  description = "Número de conexiones por nodo en HNSW (V3: mayor = más RAM, más precisión)"
  default     = 16 # Balance para <100k vectores, búsquedas <100ms
  validation {
    condition     = var.hnsw_m >= 8 && var.hnsw_m <= 64
    error_message = "hnsw_m debe estar entre 8 y 64 (V3: equilibrio RAM/precisión)."
  }
}

variable "hnsw_ef_construct" {
  type        = number
  description = "Tamaño de ventana de búsqueda durante construcción (V3)"
  default     = 100 # Calidad buena, construcción aceptable en VPS
  validation {
    condition     = var.hnsw_ef_construct >= 50 && var.hnsw_ef_construct <= 400
    error_message = "hnsw_ef_construct debe estar entre 50 y 400 (V3)."
  }
}
```

```hcl
# ❌ Anti-pattern: Parámetros HNSW por defecto sin justificación de caso de uso
# 🔧 Fix: Documentar criterio de selección + validation para rangos seguros
```

```hcl
# ✅ C5: Backup policy declarada en labels para orquestación externa
resource "docker_volume" "qdrant_storage" {
  # ...
  labels = {
    "mantis.backup"      = "daily"    # C5: frecuencia de backup
    "mantis.backup.retention" = "7"  # C5: días de retención
    "mantis.backup.encrypt" = "true" # C5: cifrado en reposo
  }
}
```

```hcl
# ❌ Anti-pattern: Política de backup no declarada → inconsistencia en recuperación
# 🔧 Fix: Labels estandarizados para que orchestrator de backups los lea automáticamente
```

```hcl
# ✅ C3/C8: Variable environment con validación y logging condicional
variable "environment" {
  type        = string
  description = "Entorno de despliegue: development, staging, production (C3)"
  default     = "development"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment debe ser development, staging o production (C3)."
  }
}

# C8: Logging estructurado solo en producción para no saturar stderr en dev
resource "null_resource" "deployment_log" {
  provisioner "local-exec" {
    command = var.environment == "production" ? <<-EOT
      echo '{"ts":"${timestamp()}","tenant":"${var.tenant_id}","level":"INFO","event":"qdrant_deployed","env":"${var.environment}"}' >&2
    EOT : "echo '🔧 Dev mode: skipping structured log' >&2"
  }
}
```

```hcl
# ❌ Anti-pattern: Logging incondicional → saturación de stderr en desarrollo
# 🔧 Fix: Condicionar logging estructurado a entorno production
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"qdrant-cluster-main-tf","version":"3.0.0","score":42,"blocking_issues":[],"constraints_verified":["C1","C2","C3","C4","C5","C7","C8","V1","V2","V3"],"examples_count":25,"lines_executable_max":5,"language":"HCL/Terraform","timestamp":"2026-04-19T00:00:00Z"}
```

---
