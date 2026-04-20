---
canonical_path: "/05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md"
artifact_id: "validator-documentation-canonical"
artifact_type: "governance_documentation"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5", "C6", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]"
  - "[[TOOLCHAIN-REFERENCE.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[01-RULES/validation-checklist.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md – REGENERADO COMPLETO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el **"Manual de Operaciones del Toolchain"**. Explica QUÉ herramientas existen, CÓMO ejecutarlas, QUÉ parámetros usar y CÓMO interpretar los resultados. Es la referencia definitiva para asegurar que cada artefacto cumple con la gobernanza antes de ser entregado.  
>  
> **Para IAs:** Este es tu manual de referencia técnica. **EJECUTAR HERRAMIENTA INCORRECTAMENTE = VALIDACIÓN FALIDA**. No inventes, no asumas, no omitas.



# 🛠️ VALIDATOR-DOCUMENTATION: Manual de Ejecución del Toolchain de Validación

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "manual de instrucciones" para todas las herramientas de validación de MANTIS AGENTIC.
Te enseña a usar `orchestrator-engine.sh` y sus auxiliares para verificar que tus archivos cumplen con las normas (C1-C8).

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: salta a la Sección 【3】 para ejemplos de comandos.
-->

> **Instrucción crítica para la IA:** 
> Este es el manual de referencia técnica. 
> **EJECUTAR HERRAMIENTA INCORRECTAMENTE = VALIDACIÓN FALIDA**. 
> Consulta siempre esta documentación antes de correr scripts de validación complejos.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo valido que mi código es seguro, eficiente y correcto?"
No es solo una lista de comandos. Es una guía de resolución de problemas que:
• Explica el propósito de cada script en `05-CONFIGURATIONS/`.
• Muestra ejemplos de uso para validación local y remota.
• Define el formato de salida JSON para integración automática.
• Sirve como base para configurar tests de stress en CI/CD.
-->

### 0.1 Arquitectura del Toolchain

```mermaid
graph TD
    A[Input: Artifact] --> B{Orchestrator Engine}
    B --> C[Validate Frontmatter]
    B --> D[Check Wikilinks]
    B --> E[Audit Secrets (C3)]
    B --> F[Check RLS (C4)]
    B --> G[Check Language Lock]
    
    C --> H[Score Calculation]
    D --> H
    E --> H
    F --> H
    G --> H
    
    H --> I[Output: JSON Report]
    I --> J{Passed?}
    J -->|Yes| K[Delivery / Merge]
    J -->|No| L[Reject with Blocking Issues]
```

---

## 【1】🛠️ REFERENCIA DE HERRAMIENTAS (Toolchain Catalog)

### 1.1 `orchestrator-engine.sh` – El Motor Principal

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validador maestro. Ejecuta checks de estructura, constraints (C1-C8), LANGUAGE LOCK y calcula el Score de Calidad.

# 📦 Flags Principales
--file <ruta>          # Ruta del archivo a validar (Obligatorio)
--dir <carpeta>        # Validar recursivamente una carpeta (Opcional)
--mode <headless|interactive> # headless para scripts/CI, interactive para terminal
--json                 # Retorna salida en formato JSON parseable
--checks <C1,C2,...>   # Validar constraints específicas (Default: todas)
--bundle               # Validar estructura de paquete (para Tier 3)
--checksum             # Verificar checksums de archivos

# ✅ Ejemplo de Uso
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/example.go.md --json

# 📤 Salida JSON Esperada
{
  "score": 42,
  "passed": true,
  "blocking_issues": [],
  "constraints_validated": ["C1", "C3", "C5"],
  "recommendations": ["Consider adding C2 for resource limits"]
}
```

### 1.2 `verify-constraints.sh` – Validador de Reglas

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/verify-constraints.sh

# 🎯 Propósito
Validación granular de constraints específicas y enforcement de LANGUAGE LOCK. Útil para debug rápido.

# 📦 Flags Principales
--check-constraint <ID>  # Validar solo una constraint (ej: C3, V1)
--check-language-lock    # Validar aislamiento de operadores por stack
--file <ruta>            # Archivo objetivo

# ✅ Ejemplo: Validar si un archivo Go usa operadores vectoriales prohibidos
bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file main.go --check-language-lock --json
```

### 1.3 `audit-secrets.sh` – Escáner de Seguridad (C3)

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/audit-secrets.sh

# 🎯 Propósito
Buscar patrones de secretos (API keys, passwords, tokens) hardcodeados en código o config.

# 📦 Flags Principales
--strict                # Fallar ante cualquier patrón sospechoso
--patterns <file>       # Usar archivo de patrones personalizados

# ✅ Ejemplo
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --dir . --strict --json
```

### 1.4 `packager-assisted.sh` – Generador de Tier 3

```bash
# 📍 Ubicación
05-CONFIGURATIONS/scripts/packager-assisted.sh

# 🎯 Propósito
Empaqueta artefactos validados en un ZIP desplegable con `manifest.json`, scripts de deploy/rollback y checksums.

# 📦 Flags Principales
--source <archivo>      # El archivo Markdown (Tier 2) origen
--output <archivo.zip>  # Nombre del paquete destino
--dry-run               # Simular empaquetado sin crear archivos

# ✅ Ejemplo
bash 05-CONFIGURATIONS/scripts/packager-assisted.sh --source agent.md --output deploy/agent-v1.zip
```

---

## 【2】🔄 INTEGRACIÓN EN PIPELINES Y SANDBOX

### 2.1 Uso en CI/CD (GitHub Actions)

El toolchain se integra en `.github/workflows/validate-mantis.yml` mediante el siguiente bloque estándar:

```yaml
- name: Validate Artifacts
  run: |
    # Validar todos los archivos modificados
    git diff --name-only HEAD^ HEAD | grep '\.md$' | xargs -I {} \
      bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {} --json > result.json
    
    # Verificar si algún archivo falló (score < 30 o blocking_issues)
    if jq -e '.blocking_issues | length > 0 or .score < 30' result.json; then
      echo "❌ Validation failed! See report for details."
      cat result.json
      exit 1
    fi
```

### 2.2 Sincronización con Sandboxes

Para actualizar los entornos de prueba (Qwen, DeepSeek, MiniMax) con las nuevas reglas:

```bash
# Script de sincronización automática
bash 05-CONFIGURATIONS/scripts/sync-to-sandbox.sh --all
```

Esto copia `01-RULES/`, `norms-matrix.json`, y `orchestrator-engine.sh` a las carpetas `09-TEST-SANDBOX/`.

---

## 【3】📚 GUÍA DE RESOLUCIÓN DE ERRORES (Troubleshooting)

### 3.1 Errores Comunes y Soluciones

| Código de Error | Significado | Solución Recomendada |
|-----------------|-------------|----------------------|
| `SCORE_TOO_LOW` | El artefacto tiene score < 30. | Revisar warnings en el JSON de salida. Añadir ejemplos o mejorar frontmatter. |
| `BLOCKING_ISSUE: C3_VIOLATION` | Se detectaron secretos en el código. | Eliminar API keys/passwords. Usar variables de entorno (`.env`). |
| `BLOCKING_ISSUE: WIKILINK_NOT_CANONICAL` | Enlace relativo detectado (ej: `[[../...]]`). | Cambiar a ruta absoluta desde raíz: `[[01-RULES/norma.md]]`. |
| `BLOCKING_ISSUE: LANGUAGE_LOCK` | Operador prohibido (ej: `<->` en Go). | Mover lógica vectorial a `06-PROGRAMMING/postgresql-pgvector/`. |
| `FILE_NOT_FOUND` | El archivo especificado no existe. | Verificar la ruta `canonical_path` en el frontmatter. |

### 3.2 Validación Local Rápida

Para validar tu propio trabajo antes de commitear:

```bash
# Validar el archivo en el que estás trabajando
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file . --interactive

# Verificar solo que no hay secretos
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --dir . --strict
```

---

## 【4】📦 METADATOS DE EXPANSIÓN

<!-- 
【PARA MANTENEDORES】
Este documento debe actualizarse cada vez que se añade un nuevo script a la carpeta `05-CONFIGURATIONS/scripts/` o `validation/`.
-->

```json
{
  "expansion_registry": {
    "new_validator_script": {
      "description": "Si se añade un nuevo script de validación (ej: `check-performance.sh`)",
      "action_required": [
        "Añadir entrada en Sección 【1】 con Propósito, Flags y Ejemplo.",
        "Actualizar Sección 【2】 si requiere integración en CI/CD.",
        "Actualizar JSON Tree al final del archivo."
      ]
    },
    "new_pipeline_step": {
      "description": "Si se añade un nuevo paso en el pipeline (ej: `deploy-stage`)",
      "action_required": [
        "Añadir snippet de código en Sección 【2.1】.",
        "Explicar flags necesarios para ese paso."
      ]
    }
  }
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO (Toolchain Reference)
═══════════════════════════════════════════════════════════
-->

```json
{
  "toolchain_documentation_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md",
    "artifact_type": "governance_documentation",
    "immutable": true,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true
    }
  },
  "tools_catalog": {
    "orchestrator-engine.sh": {
      "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh",
      "type": "orchestrator",
      "constraints_validated": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
      "usage_example": "bash orchestrator-engine.sh --file artifact.md --json"
    },
    "verify-constraints.sh": {
      "path": "05-CONFIGURATIONS/validation/verify-constraints.sh",
      "type": "constraint_validator",
      "usage_example": "bash verify-constraints.sh --file artifact.md --check-constraint C3 --json"
    },
    "audit-secrets.sh": {
      "path": "05-CONFIGURATIONS/validation/audit-secrets.sh",
      "type": "security_scanner",
      "usage_example": "bash audit-secrets.sh --dir . --strict --json"
    },
    "packager-assisted.sh": {
      "path": "05-CONFIGURATIONS/scripts/packager-assisted.sh",
      "type": "packager",
      "usage_example": "bash packager-assisted.sh --source artifact.md --output bundle.zip"
    }
  },
  "error_codes": {
    "C3_VIOLATION": "Secrets detected",
    "WIKILINK_NOT_CANONICAL": "Relative path found",
    "LANGUAGE_LOCK": "Forbidden operator used",
    "SCORE_TOO_LOW": "Quality score below threshold"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->
````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md | grep -q "/05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C5,C6,C8)
yq eval '.constraints_mapped | contains(["C5"]) and contains(["C6"]) and contains(["C8"])' 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md && echo "✅ C5, C6, C8 declaradas"

# 3. Herramientas documentadas
grep -c "orchestrator-engine.sh\|verify-constraints.sh\|audit-secrets.sh\|packager-assisted.sh" 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md | awk '{if($1>=4) print "✅ Herramientas clave documentadas"; else print "⚠️ Faltan herramientas"}'

# 4. JSON final parseable
tail -n +$(grep -n '```json' 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md | tail -1 | cut -d: -f1) 05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"
```
````
> 🎯 **Mensaje final para el lector humano**:  
> Este manual es tu guía de operaciones. Úsalo siempre antes de ejecutar una validación compleja.  
> **Entender → Ejecutar → Validar → Corregir**.  
> Si sigues ese flujo, nunca tendrás dudas sobre cómo validar tu trabajo.  

---
