---
canonical_path: "/01-RULES/03-SECURITY-RULES.md"
artifact_id: "security-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3", "C4", "C5", "C6", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/03-SECURITY-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[05-CONFIGURATIONS/validation/audit-secrets.sh]]"
  - "[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/03-SECURITY-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define las reglas inamovibles de seguridad en MANTIS AGENTIC, con foco en C3 (Zero Hardcode Secrets). Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de seguridad. **VIOLAR C3 = BLOQUEO INMEDIATO**. No inventes, no asumas, no omitas.


# 🔐 03-SECURITY-RULES: Contrato de Seguridad y Gestión de Secrets (C3 Enforcement)

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "contrato de seguridad" del proyecto MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que secrets, API keys, credenciales 
y datos sensibles NUNCA sean hardcodeados en código, configs o logs.

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de seguridad. 
> **VIOLAR C3 = BLOQUEO INMEDIATO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo garantizo que nunca expongo credenciales o datos sensibles?"
No es solo una lista de reglas. Es un sistema de contención que:
• Previene hardcodeo de secrets desde el diseño
• Garantiza que cada variable sensible use variables de entorno o secret managers
• Permite auditoría forense de accesos a secrets
• Scrubeea PII en logs automáticamente (C3 + C8)
-->

### 0.1 C3: Zero Hardcode Secrets – Definición Canónica

```
C3 (Zero Hardcode Secrets): NUNCA escribir secrets, API keys, credenciales, tokens 
o datos sensibles directamente en código, configs, logs o commits.

✅ Cumplimiento:
• Variables de entorno: ${VAR:?missing} (bash), os.environ["VAR"] (Python)
• Secret managers: AWS Secrets Manager, HashiCorp Vault, Doppler
• Inyección runtime: pasar secrets vía CLI flags o config files externos (no versionados)
• Logs scrubbed: ***REDACTED*** para campos sensibles

❌ Violación crítica:
• password = "supersecret123" en cualquier archivo
• API_KEY=sk-xxx hardcodeado en script o .env versionado
• Log que incluye token o password en texto plano
• Commit que expone .env o config con secrets
```

### 0.2 Mapeo C3 → Herramientas de Validación

| Herramienta | Propósito | Comando de Validación |
|------------|-----------|---------------------|
| `audit-secrets.sh` | Detectar secrets hardcodeados en código/configs | `bash 05-CONFIGURATIONS/validation/audit-secrets.sh --file artifact.md --json` |
| `verify-constraints.sh` | Verificar que artifacts declaran C3 en constraints_mapped | `bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file artifact.md --check-constraint C3 --json` |
| `orchestrator-engine.sh` | Validación integral con scoring y reporte JSON | `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file artifact.md --json` |

> 💡 **Consejo para principiantes**: No memorices todos los patrones. Usa `audit-secrets.sh` para escanear automáticamente en busca de secrets hardcodeados.

---

## 【1】🔒 REGLAS INAMOVIBLES DE SEGURIDAD (SEC-001 a SEC-012)

<!-- 
【EDUCATIVO】Estas 12 reglas son contractuales. 
Cualquier violación es blocking_issue en validación.
-->

### SEC-001: Secrets Solo en Variables de Entorno

```
【REGLA SEC-001】Nunca hardcodear secrets. Siempre usar variables de entorno.

✅ Cumplimiento por lenguaje:

【BASH ✅】
# Usar expansión con fallback explícito
DB_PASSWORD="${DB_PASSWORD:?Missing DB_PASSWORD env var}"
API_KEY="${API_KEY:?Missing API_KEY env var}"

# Validar que la variable existe antes de usar
if [ -z "$SECRET_TOKEN" ]; then
  echo "ERROR: SECRET_TOKEN not set" >&2
  exit 1
fi

❌ Bash ❌
# NUNCA USAR:
DB_PASSWORD="supersecret123"
API_KEY="sk-abc123..."

【PYTHON ✅】
import os

# Usar os.environ con manejo de error explícito
DB_PASSWORD = os.environ.get("DB_PASSWORD")
if not DB_PASSWORD:
    raise ValueError("Missing DB_PASSWORD environment variable")

# O con pydantic-settings para validación automática
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    db_password: str
    api_key: str
    
    class Config:
        env_file = ".env"  # Solo para desarrollo local, NO versionar

❌ Python ❌
# NUNCA USAR:
DB_PASSWORD = "supersecret123"
API_KEY = "sk-abc123..."

【GO ✅】
package main

import (
    "fmt"
    "os"
)

func getSecret(key string) (string, error) {
    val := os.Getenv(key)
    if val == "" {
        return "", fmt.Errorf("missing required env var: %s", key)
    }
    return val, nil
}

// Uso
dbPassword, err := getSecret("DB_PASSWORD")
if err != nil {
    log.Fatal(err)
}

❌ Go ❌
// NUNCA USAR:
dbPassword := "supersecret123"
apiKey := "sk-abc123..."
```

### SEC-002: .gitignore para Archivos Sensibles

```
【REGLA SEC-002】Nunca versionar archivos que contengan secrets.

✅ Archivos que DEBEN estar en .gitignore:
• .env, .env.local, .env.production
• *.pem, *.key, *.crt (certificados privados)
• config/secrets.yaml, config/credentials.json
• aws/credentials, gcp/service-account.json
• *.secret, *password*, *token*

✅ .gitignore canónico para MANTIS:
```
# Secrets y configs sensibles
.env
.env.local
.env.production
*.pem
*.key
*.crt
config/secrets.*
config/credentials.*
aws/credentials
gcp/*.json
*.secret
*password*
*token*
*api_key*

# Logs con posibles datos sensibles
*.log
logs/
08-LOGS/

# IDE y editor configs con posibles paths locales
.vscode/
.idea/
*.swp
*.swo
```

✅ Validación pre-commit:
```bash
# Añadir hook para detectar secrets antes de commit
# .git/hooks/pre-commit
if grep -rE '(password|secret|api[_-]?key|token)\s*=\s*["\'][^"\']+["\']' --include="*.md" --include="*.sh" --include="*.py" --include="*.go" .; then
  echo "❌ Possible hardcode secret detected. Use environment variables instead."
  exit 1
fi
```

❌ Violación crítica:
• Commit que incluye .env con valores reales
• Archivo de config versionado con API keys en texto plano
• Certificado privado (.pem) en el repositorio
```

### SEC-003: Secret Managers para Producción

```
【REGLA SEC-003】En producción, usar secret managers, no variables de entorno simples.

✅ Secret managers soportados:
| Manager | Comando de ejemplo | Integración |
|---------|------------------|-------------|
| AWS Secrets Manager | `aws secretsmanager get-secret-value --secret-id my-secret` | boto3, AWS SDK |
| HashiCorp Vault | `vault kv get -field=password secret/myapp` | vault CLI, HVAC Python |
| Doppler | `doppler secrets get DB_PASSWORD` | Doppler CLI, SDKs |
| Azure Key Vault | `az keyvault secret show --name DB_PASSWORD` | Azure SDK |

✅ Patrón de carga en producción (Go ejemplo):
```go
func loadSecrets(ctx context.Context) (*Config, error) {
    // Intentar cargar desde secret manager primero
    if os.Getenv("ENVIRONMENT") == "production" {
        vaultClient, err := vault.NewClient()
        if err != nil {
            return nil, fmt.Errorf("failed to init vault: %w", err)
        }
        
        dbPassword, err := vaultClient.GetSecret(ctx, "secret/data/myapp", "db_password")
        if err != nil {
            return nil, fmt.Errorf("failed to get db_password: %w", err)
        }
        
        return &Config{DBPassword: dbPassword}, nil
    }
    
    // Fallback a env vars solo para desarrollo
    return &Config{
        DBPassword: os.Getenv("DB_PASSWORD"),
    }, nil
}
```

✅ Rotación automática:
• Configurar TTL para secrets en Vault/AWS
• Implementar re-fetch de secrets cada N minutos
• Log de rotación sin exponer valores (C8 + C3)

❌ Violación crítica:
• Usar variables de entorno simples en producción sin secret manager
• Secrets con TTL infinito sin rotación
• Log que expone valor de secret durante rotación
```

### SEC-004: Scrubbing de PII en Logs (C3 + C8)

```
【REGLA SEC-004】Nunca loguear secrets, tokens, passwords o PII en texto plano.

✅ Patrón de scrubbing canónico:

【GO ✅ (slog con ReplaceAttr)】
logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
    ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
        sensitiveKeys := map[string]bool{
            "password": true, "secret": true, "token": true,
            "api_key": true, "apikey": true, "credential": true,
            "auth": true, "bearer": true, "jwt": true,
        }
        if sensitiveKeys[strings.ToLower(a.Key)] {
            return slog.String(a.Key, "***REDACTED***")
        }
        return a
    },
}))

// Uso: logger.Info("auth_attempt", "password", userPassword) 
// → Log: {"password":"***REDACTED***"}

【PYTHON ✅ (logging con filter)】
import logging
import re

class SecretFilter(logging.Filter):
    SENSITIVE_PATTERNS = [
        r'password["\']?\s*[:=]\s*["\'][^"\']+["\']',
        r'api[_-]?key["\']?\s*[:=]\s*["\'][^"\']+["\']',
        r'token["\']?\s*[:=]\s*["\'][^"\']+["\']',
    ]
    
    def filter(self, record):
        msg = str(record.msg)
        for pattern in self.SENSITIVE_PATTERNS:
            msg = re.sub(pattern, r'\g<0>***REDACTED***', msg, flags=re.I)
        record.msg = msg
        return True

logger = logging.getLogger(__name__)
logger.addFilter(SecretFilter())

【BASH ✅ (sed para scrubbing)】
log_with_scrubbing() {
    local msg="$1"
    # Scrubear patrones comunes de secrets
    echo "$msg" | sed -E \
        -e 's/(password|secret|token|api_key)["\']?[:=]["\']?[^"'\'' ]+/&***REDACTED***/gi' \
        -e 's/sk-[a-zA-Z0-9]{20,}/***REDACTED***/g' \
        -e 's/ghp_[a-zA-Z0-9]{36,}/***REDACTED***/g'
}

# Uso: log_with_scrubbing "Connecting with password=supersecret"
# → Output: "Connecting with password=***REDACTED***"

❌ Violación crítica:
• Log que incluye password en texto plano: `logger.info(f"Login with {password}")`
• Error message que expone API key: `raise Exception(f"Auth failed for key {api_key}")`
• Debug log con token completo para troubleshooting
```

### SEC-005: Validación de Secrets en CI/CD

```
【REGLA SEC-005】Escanear secrets en cada commit y pull request.

✅ Integración con GitHub Actions:
```yaml
# .github/workflows/scan-secrets.yml
name: Scan for Secrets

on: [push, pull_request]

jobs:
  detect-secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run audit-secrets.sh
        run: |
          bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
            --dir . \
            --strict \
            --json > /tmp/secrets-scan.json
      
      - name: Fail if secrets found
        run: |
          if jq -e '.secrets_found > 0' /tmp/secrets-scan.json; then
            echo "❌ Hardcoded secrets detected!"
            jq '.findings[]' /tmp/secrets-scan.json
            exit 1
          fi
```

✅ Patrones detectados por audit-secrets.sh:
| Patrón | Ejemplo detectado | Falso positivo común |
|--------|-----------------|---------------------|
| `password = "xxx"` | `DB_PASS = "super123"` | `password = ""` (vacío, OK) |
| `api_key = "sk-xxx"` | `OPENAI_KEY = "sk-abc..."` | `api_key = "${API_KEY}"` (env var, OK) |
| `token = "ghp_xxx"` | `GITHUB_TOKEN = "ghp_abc..."` | `token = ""` (vacío, OK) |
| `secret = "xxx"` | `JWT_SECRET = "my-secret"` | `secret = os.environ["SECRET"]` (OK) |
| AWS keys | `AKIA[0-9A-Z]{16}` | `AWS_PROFILE = "default"` (OK) |

✅ Configuración de patterns personalizados:
```bash
# patterns-custom.txt para audit-secrets.sh --patterns
# Añadir patrones específicos del proyecto
client_secret["\']?\s*[:=]\s*["\'][^"\']+["\']
webhook_secret["\']?\s*[:=]\s*["\'][^"\']+["\']
```

❌ Violación crítica:
• Commit que pasa CI/CD con secret hardcodeado
• Pattern personalizado que no detecta nuevo tipo de secret del proyecto
• Scan deshabilitado en rama principal
```

### SEC-006: Secrets en Docker y Kubernetes

```
【REGLA SEC-006】Nunca incluir secrets en Dockerfiles o manifests de Kubernetes.

✅ Dockerfile seguro:
```dockerfile
# ❌ NUNCA USAR:
# ENV DB_PASSWORD=supersecret123
# COPY .env /app/.env

# ✅ USAR:
# Secrets se inyectan en runtime vía docker-compose o Kubernetes
FROM python:3.11-slim

# Instalar dependencias sin secrets
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copiar código sin configs sensibles
COPY src/ /app/src/

# El container espera secrets via env vars o mounted secrets
CMD ["python", "-m", "src.main"]
```

✅ docker-compose.yml con secrets:
```yaml
version: '3.8'
services:
  app:
    image: myapp:latest
    environment:
      # Referenciar variables de entorno del host, NO hardcodear
      - DB_PASSWORD=${DB_PASSWORD:?Missing DB_PASSWORD}
      - API_KEY=${API_KEY:?Missing API_KEY}
    # O usar Docker secrets para producción
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    external: true  # Gestionado fuera de docker-compose
  api_key:
    external: true
```

✅ Kubernetes Secrets (con precaución):
```yaml
# ❌ NUNCA USAR en YAML versionado:
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
stringData:
  db-password: supersecret123  # ← Hardcodeado, NO versionar

# ✅ USAR: Crear secrets fuera de Git, referenciar en manifests
# Crear secret con kubectl (no versionar el YAML con valores):
# kubectl create secret generic app-secrets \
#   --from-literal=db-password=supersecret123 \
#   --from-literal=api-key=sk-abc123

# Manifest que referencia el secret (SÍ versionar):
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
```

✅ Alternativa moderna: External Secrets Operator + Vault/AWS
```yaml
# external-secret.yaml (SÍ versionar, sin valores)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: app-secrets
  data:
  - secretKey: db-password
    remoteRef:
      key: secret/data/myapp
      property: db_password
```

❌ Violación crítica:
• Dockerfile con ENV que hardcodea secret
• docker-compose.yml con valores reales de secrets
• Kubernetes manifest versionado con stringData que contiene secrets
• Imagen Docker que incluye .env con secrets
```

### SEC-007: Rotación y Revocación de Secrets

```
【REGLA SEC-007】Todo secret debe tener TTL definido y mecanismo de revocación.

✅ Política de rotación recomendada:
| Tipo de Secret | TTL Recomendado | Método de Rotación |
|---------------|----------------|-------------------|
| API Keys (externas) | 90 días | Renovar vía proveedor, actualizar en secret manager |
| Database passwords | 30 días | Generar nuevo, actualizar app, revocar antiguo |
| JWT signing keys | 180 días | Key rotation con overlap period |
| Webhook secrets | 180 días | Rotar en ambos extremos con coordinación |
| Service accounts | 365 días | Recrear cuenta, actualizar configs |

✅ Patrón de rotación en código (Python ejemplo):
```python
class SecretRotator:
    def __init__(self, secret_name: str, ttl_days: int):
        self.secret_name = secret_name
        self.ttl = timedelta(days=ttl_days)
        self._cache = None
        self._last_fetch = None
    
    def get(self) -> str:
        """Obtener secret, rotando si expiró"""
        now = datetime.utcnow()
        
        # Usar cache si aún válido
        if (self._cache and self._last_fetch and 
            now - self._last_fetch < self.ttl):
            return self._cache
        
        # Fetch nuevo desde secret manager
        self._cache = vault_client.get_secret(self.secret_name)
        self._last_fetch = now
        
        # Log de rotación sin exponer valor (C3 + C8)
        logger.info("secret_rotated", 
                   secret_name=self.secret_name, 
                   rotated_at=now.isoformat())
        
        return self._cache
```

✅ Revocación inmediata en caso de compromiso:
• Endpoint /admin/revoke-secret para invalidar secret específico
• Webhook para notificar a servicios cuando un secret es revocado
• Cache invalidation inmediato en todas las instancias

❌ Violación crítica:
• Secret con TTL infinito sin rotación
• No tener mecanismo para revocar secret comprometido
• Log que expone valor de secret durante proceso de rotación
```

### SEC-008: Secrets en Tests y Desarrollo

```
【REGLA SEC-008】Tests y desarrollo deben usar mocks o secrets de prueba, nunca producción.

✅ Patrón para tests:
```python
# tests/conftest.py - Fixtures con secrets mock
import pytest
from unittest.mock import patch

@pytest.fixture
def mock_secrets(monkeypatch):
    """Mock secrets para tests, nunca usar valores reales"""
    monkeypatch.setenv("DB_PASSWORD", "test_password_123")
    monkeypatch.setenv("API_KEY", "test_key_abc")
    monkeypatch.setenv("ENVIRONMENT", "testing")
    yield
    # Cleanup automático

@pytest.fixture
def mock_vault_client():
    """Mock de Vault client para tests"""
    with patch('myapp.vault.VaultClient') as mock:
        mock.return_value.get_secret.return_value = "mocked_secret_value"
        yield mock
```

✅ .env.example para desarrollo:
```bash
# .env.example (SÍ versionar - sin valores reales)
# Copiar a .env.local y rellenar con valores locales (NO versionar .env.local)

DB_PASSWORD=your_local_password_here
API_KEY=your_local_api_key_here
ENVIRONMENT=development

# Secrets de producción NUNCA van aquí:
# PRODUCTION_DB_PASSWORD=  ← Dejar vacío o comentar
```

✅ Validación en CI para evitar leaks de desarrollo:
```bash
# CI job para verificar que .env.example no tiene valores reales
check_env_example() {
    # Buscar patrones que sugieran valores reales (no placeholders)
    if grep -E '=[a-zA-Z0-9]{16,}' .env.example | grep -v '_here\|placeholder\|changeme'; then
        echo "❌ .env.example contains real-looking values. Use placeholders."
        exit 1
    fi
}
```

❌ Violación crítica:
• Test que hardcodea secret de producción "para que funcione"
• .env.example con valores reales en lugar de placeholders
• Commit que incluye .env.local con secrets de desarrollo real
• Mock en test que expone estructura de secret de producción
```

### SEC-009: Auditoría de Accesos a Secrets

```
【REGLA SEC-009】Todo acceso a secret debe ser auditado con tenant_id y actor.

✅ Log de auditoría canónico para acceso a secrets:
```json
{
  "timestamp": "2026-04-19T12:00:00Z",
  "level": "INFO",
  "tenant_id": "cliente_001",
  "actor": "service:api-gateway",
  "event": "secret_accessed",
  "secret_name": "db_password",
  "secret_store": "vault",
  "action": "read",
  "result": "success",
  "trace_id": "otel-trace-xyz",
  "note": "secret_value_not_logged"
}
```

✅ Integración con OpenTelemetry para trazabilidad distribuida:
```go
func getSecretWithAudit(ctx context.Context, secretName string) (string, error) {
    // Start trace span
    ctx, span := tracer.Start(ctx, "get_secret")
    defer span.End()
    
    // Get secret from vault
    value, err := vaultClient.GetSecret(ctx, secretName)
    
    // Audit log (C3: nunca loguear value)
    slog.InfoContext(ctx, "secret_accessed",
        "secret_name", secretName,
        "result", map[bool]string{true: "success", false: "failed"}[err == nil],
        "trace_id", span.SpanContext().TraceID().String(),
    )
    
    return value, err
}
```

✅ Dashboard de auditoría recomendado:
• Gráfico de accesos a secrets por tenant/hora
• Alerta si un tenant accede a secret de otro tenant
• Reporte semanal de rotaciones y accesos inusuales

❌ Violación crítica:
• Acceso a secret sin log de auditoría
• Log de auditoría que incluye valor del secret
• Auditoría sin tenant_id o trace_id para correlación
```

### SEC-010: Secrets en Webhooks y APIs Externas

```
【REGLA SEC-010】Validar y proteger secrets en integraciones con APIs externas.

✅ Patrón para webhooks entrantes:
```python
# Validar firma HMAC para integridad del webhook
import hmac
import hashlib

def verify_webhook_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verificar firma HMAC-SHA256 de webhook"""
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)

# Uso en handler de webhook
@app.post("/webhook/whatsapp")
async def whatsapp_webhook(request: Request):
    # Obtener secret desde env var, NO hardcodeado
    webhook_secret = os.environ["WHATSAPP_WEBHOOK_SECRET"]
    
    # Validar firma
    signature = request.headers.get("X-Hub-Signature-256")
    body = await request.body()
    
    if not verify_webhook_signature(body, signature, webhook_secret):
        logger.warning("webhook_signature_invalid", 
                      tenant_id=request.state.tenant_id)
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    # Procesar payload...
```

✅ Patrón para llamadas a APIs externas:
```go
// Go: Cliente HTTP con secret inyectado vía contexto
type APIClient struct {
    baseURL    string
    getAPIKey  func(context.Context) (string, error)  // Inyección dinámica
}

func (c *APIClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    // Obtener API key dinámicamente (desde Vault, env var, etc.)
    apiKey, err := c.getAPIKey(ctx)
    if err != nil {
        return nil, fmt.Errorf("failed to get API key: %w", err)
    }
    
    // Inyectar en header, nunca en URL o body visible
    req.Header.Set("Authorization", "Bearer " + apiKey)
    
    // Log sin exponer API key (C3 + C8)
    slog.DebugContext(ctx, "api_request",
        "url", req.URL.String(),
        "method", req.Method,
        // NO: "api_key", apiKey  ← ¡Violación C3!
    )
    
    return http.DefaultClient.Do(req)
}
```

✅ Rotación de webhook secrets:
• Soportar múltiples secrets válidos durante período de transición
• Endpoint /admin/rotate-webhook-secret para iniciar rotación
• Notificar a proveedor externo cuando secret cambia

❌ Violación crítica:
• Webhook secret hardcodeado en código
• API key expuesta en URL query params o logs
• No validar firma HMAC en webhooks entrantes
• Log que expone secret durante debugging de integración
```

### SEC-011: Educación y Concienciación de Seguridad

```
【REGLA SEC-011】Todo desarrollador debe completar entrenamiento en manejo de secrets.

✅ Checklist de onboarding de seguridad:
- [ ] Completar módulo "C3: Zero Hardcode Secrets" en plataforma de training
- [ ] Ejecutar audit-secrets.sh en proyecto de práctica y corregir hallazgos
- [ ] Configurar pre-commit hook con scan de secrets en entorno local
- [ ] Revisar y firmar política de manejo de secrets del proyecto

✅ Recursos de entrenamiento recomendados:
• `01-RULES/03-SECURITY-RULES.md` (este documento) ← Lectura obligatoria
• `05-CONFIGURATIONS/validation/audit-secrets.sh --help` ← Práctica con herramienta
• `02-SKILLS/SEGURIDAD/security-hardening-vps.md` ← Contexto de infraestructura
• Simulacro de "secret leak" en sandbox de prueba

✅ Evaluación periódica:
• Quiz trimestral sobre patrones seguros de manejo de secrets
• Revisión de código aleatoria enfocada en detección de C3 violations
• Simulacro de respuesta a incidente de secret comprometido

❌ Violación crítica:
• Desarrollador con acceso a producción sin completar training de seguridad
• No actualizar materiales de training cuando se añaden nuevos patrones de detección
```

### SEC-012: Respuesta a Incidentes de Seguridad

```
【REGLA SEC-012】Procedimiento definido para respuesta a leaks de secrets.

✅ Playbook de respuesta a secret leak:
```
FASE 1 – DETECCIÓN (0-15 min)
├─ Alerta automática: audit-secrets.sh en CI detecta secret en commit
├─ O reporte manual: desarrollador nota secret expuesto en log/repo
├─ Acción inmediata: revocar acceso al commit/branch afectado

FASE 2 – CONTENCIÓN (15-60 min)
├─ Rotar secret comprometido en secret manager
├─ Invalidar tokens/API keys expuestos en proveedores externos
├─ Notificar a tenants afectados si aplica (C4 + transparencia)

FASE 3 – ERRADICACIÓN (1-24 h)
├─ Reescribir historial Git si secret fue commiteado (git filter-branch o BFG)
├─ Actualizar audit-secrets.sh patterns si el leak evadió detección
├─ Revisar logs de auditoría para determinar alcance del acceso no autorizado

FASE 4 – RECUPERACIÓN (24-72 h)
├─ Desplegar nueva versión con secrets rotados
├─ Verificar que todos los servicios funcionan con nuevos secrets
├─ Documentar lecciones aprendidas en post-mortem

FASE 5 – MEJORA (1-2 semanas)
├─ Actualizar este documento con nuevo patrón de detección si aplica
├─ Añadir test de regresión para prevenir leak similar
├─ Actualizar training de seguridad con caso de estudio
```

✅ Contactos de emergencia:
• Security lead: security@mantis-agentic.dev (PGP key en README.md)
• Incident response channel: #security-incidents en Slack/Telegram
• Escalación externa: reportar a proveedores afectados según sus políticas

✅ Plantilla de post-mortem:
```markdown
# Post-Mortem: Secret Leak - {fecha}

## Resumen Ejecutivo
{Breve descripción del incidente y impacto}

## Cronología
- {timestamp}: Detección inicial
- {timestamp}: Contención aplicada
- {timestamp}: Erradicación completada
- {timestamp}: Recuperación verificada

## Causa Raíz
{Análisis de por qué ocurrió el leak}

## Acciones Correctivas
- [ ] Pattern añadido a audit-secrets.sh: {pattern}
- [ ] Test de regresión añadido: {test_name}
- [ ] Training actualizado: {module}

## Métricas
- Tiempo de detección: {X} minutos
- Tiempo de contención: {Y} minutos
- Secrets afectados: {N}
- Tenants notificados: {M}
```

❌ Violación crítica:
• No tener playbook definido para respuesta a leaks
• No rotar secret comprometido dentro de 1 hora de detección
• No documentar post-mortem para prevenir recurrencia
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE C3 (Toolchain Integration)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de C3.
Úsalas en CI/CD y pre-commit para prevenir deuda técnica.
-->

### 2.1 audit-secrets.sh – Detección de Secrets Hardcodeados

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/audit-secrets.sh

# 🎯 Propósito
Escanear artefactos en busca de secrets, API keys, credenciales o tokens hardcodeados.
Cumple con constraint C3: Zero Hardcode Secrets.

# 📦 Flags Principales
--file <ruta>              # Artefacto a escanear
--dir <directorio>         # Escanear todo un directorio
--patterns <archivo>       # Archivo con patrones regex personalizados (opcional)
--strict                   # Modo estricto: fallar ante cualquier posible secreto
--json                     # Salida en formato JSON

# ✅ Ejemplo: Escanear archivo individual
bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
  --file 06-PROGRAMMING/python/langchain-integration.md \
  --json

# ✅ Ejemplo: Escanear directorio completo (pre-commit hook)
bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
  --dir 06-PROGRAMMING/ \
  --strict \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/python/config.py.md",
  "secrets_found": 0,
  "patterns_checked": [
    "password\\s*=\\s*['\"][^'\"]+['\"]",
    "api[_-]?key\\s*=\\s*['\"][^'\"]+['\"]",
    "sk-[a-zA-Z0-9]{20,}",
    "ghp_[a-zA-Z0-9]{36,}",
    "\\$\\{[^}]+\\}"  # Variables de entorno (permitidas)
  ],
  "findings": [],
  "passed": true,
  "recommendation": "✅ No se detectaron secrets hardcodeados. Usar variables de entorno para configuración sensible."
}

# ⚠️ Patrones Detectados por Defecto
| Patrón | Ejemplo Detectado | Alternativa Segura |
|--------|-----------------|-------------------|
| `password = "xxx"` | `DB_PASSWORD = "supersecret123"` | `DB_PASSWORD = "${DB_PASSWORD:?missing}"` |
| `api_key = "sk-xxx"` | `OPENAI_API_KEY = "sk-abc123..."` | `OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]` |
| `token = "ghp_xxx"` | `GITHUB_TOKEN = "ghp_abc123..."` | `GITHUB_TOKEN = process.env.GITHUB_TOKEN` |
| `secret = "xxx"` | `JWT_SECRET = "my-secret-key"` | `JWT_SECRET = config.get("JWT_SECRET")` |
| AWS Access Key | `AKIAIOSFODNN7EXAMPLE` | Usar IAM roles o AWS Secrets Manager |
| Private Key header | `-----BEGIN RSA PRIVATE KEY-----` | Mount de secret en runtime, nunca en código |

# 🔐 Regla de Oro C3
NUNCA escribir secrets en código. Siempre usar:
• Variables de entorno: `${VAR:?missing}` (bash), `os.environ["VAR"]` (Python)
• Secret managers: AWS Secrets Manager, HashiCorp Vault, Doppler
• Inyección runtime: pasar secrets vía CLI flags o config files externos (no versionados)
```

### 2.2 verify-constraints.sh – Validación de Declaración de C3

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/verify-constraints.sh

# 🎯 Propósito
Validar que artifacts declaran C3 en constraints_mapped cuando aplican.

# ✅ Ejemplo: Validar artifact Markdown
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
  --file 06-PROGRAMMING/python/langchain-integration.md \
  --check-constraint C3 \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/python/langchain-integration.md",
  "constraint_checked": "C3",
  "declared_in_frontmatter": true,
  "applies_to_domain": true,
  "passed": true
}
```

### 2.3 orchestrator-engine.sh – Validación Integral con Scoring

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validación completa con scoring, incluyendo C3 enforcement.

# ✅ Ejemplo: Validar artifact para Tier 2
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/python/config-example.md \
  --mode headless \
  --json

# 📤 Criterios de Aceptación para C3
| Tier | C3 Enforcement Requerido | blocking_issue si falla |
|------|-------------------------|------------------------|
| 1    | Advertencia si falta C3 en frontmatter | No (solo warning) |
| 2    | C3 obligatorio + audit-secrets.sh clean | ✅ Sí (blocking) |
| 3    | C3 + secret manager integration + audit logs | ✅ Sí (blocking) |
```

---

## 【3】🧭 PROTOCOLO DE IMPLEMENTACIÓN DE C3 (PASO A PASO)

<!-- 
【EDUCATIVO】Este es el flujo determinista para implementar seguridad de secrets.
Mismos inputs → mismos outputs. Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】INVENTARIO DE SECRETS                        │
├─────────────────────────────────────────────────────────┤
│ 1. Listar todos los secrets usados en el proyecto      │
│ 2. Clasificar por tipo: API keys, DB passwords, tokens │
│ 3. Documentar en frontmatter: constraints_mapped: ["C3"]│
│ 4. Definir TTL y método de rotación para cada tipo     │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】MIGRACIÓN A VARIABLES DE ENTORNO             │
├─────────────────────────────────────────────────────────┤
│ 1. Reemplazar hardcodeado por ${VAR:?missing} (bash)   │
│ 2. Reemplazar por os.environ["VAR"] (Python)           │
│ 3. Reemplazar por os.Getenv("VAR") (Go)                │
│ 4. Añadir validación de existencia antes de usar       │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】INTEGRACIÓN CON SECRET MANAGER (Producción)  │
├─────────────────────────────────────────────────────────┤
│ 1. Configurar Vault/AWS Secrets Manager/Doppler        │
│ 2. Implementar cliente para fetch dinámico de secrets  │
│ 3. Añadir cache con TTL para reducir llamadas          │
│ 4. Log de acceso sin exponer valores (C3 + C8)         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】VALIDACIÓN AUTOMÁTICA EN CI/CD               │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir audit-secrets.sh al pipeline de CI           │
│ 2. Configurar pre-commit hook con scan de secrets      │
│ 3. Fallar build si se detecta secret hardcodeado       │
│ 4. Notificar al autor con sugerencia de corrección     │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】AUDITORÍA FORENSE CON LOGS ESTRUCTURADOS     │
├─────────────────────────────────────────────────────────┤
│ 1. Configurar logging estructurado JSON a stderr       │
│ 2. Scrubear secrets/PII antes de loguear (C3 + C8)     │
│ 3. Incluir tenant_id y trace_id en logs de acceso      │
│ 4. Exportar logs a SIEM/OpenTelemetry para monitoreo   │
└─────────────────────────────────────────────────────────┘
```

### 3.1 Ejemplo de Traza de Implementación de C3

```
【TRAZA DE IMPLEMENTACIÓN C3】
Tarea: "Asegurar configuración de API de OpenAI en módulo de IA"

Fase 0 - Inventario de secrets:
  • Secret identificado: OPENAI_API_KEY (tipo: API key externa) ✅
  • TTL definido: 90 días, rotación manual vía proveedor ✅
  • Documentar en frontmatter: constraints_mapped: ["C3", "C4"] ✅

Fase 1 - Migración a variables de entorno:
  • Reemplazar en código: api_key="sk-xxx" → os.environ["OPENAI_API_KEY"] ✅
  • Añadir validación: if not api_key: raise ValueError("Missing OPENAI_API_KEY") ✅
  • Actualizar .env.example con placeholder: OPENAI_API_KEY=your_key_here ✅

Fase 2 - Integración con secret manager (producción):
  • Configurar fetch desde Vault: vault_client.get_secret("openai/api_key") ✅
  • Implementar cache con TTL 1h para reducir llamadas ✅
  • Log de acceso: logger.info("secret_accessed", secret_name="openai/api_key") ✅

Fase 3 - Validación automática en CI/CD:
  • Añadir audit-secrets.sh al workflow de GitHub Actions ✅
  • Configurar pre-commit hook local con scan de secrets ✅
  • Test: commit con api_key hardcodeado → CI falla con mensaje claro ✅

Fase 4 - Auditoría forense:
  • Configurar slog JSON handler con scrubbing de secrets ✅
  • Incluir tenant_id y trace_id en logs de acceso a API ✅
  • Exportar logs a OpenTelemetry para dashboard de seguridad ✅

Resultado: ✅ Módulo de IA con seguridad de secrets certificada C3.
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **C3 (Zero Hardcode Secrets)** | Regla que prohíbe escribir credenciales directamente en código | `DB_PASSWORD = os.environ["DB_PASSWORD"]` en lugar de `DB_PASSWORD = "secret123"` |
| **Secret manager** | Servicio seguro para almacenar y rotar credenciales | AWS Secrets Manager, HashiCorp Vault, Doppler |
| **Variable de entorno** | Valor configurado fuera del código, accesible en runtime | `export API_KEY=xxx` antes de ejecutar el programa |
| **Scrubbing** | Reemplazar datos sensibles por `***REDACTED***` en logs | Log: `password=***REDACTED***` en lugar de valor real |
| **HMAC signature** | Firma criptográfica para verificar integridad de webhooks | Validar que un webhook viene de fuente legítima |
| **TTL (Time To Live)** | Tiempo máximo que un secret es válido antes de rotar | API key con TTL 90 días debe renovarse trimestralmente |
| **Pre-commit hook** | Script que se ejecuta automáticamente antes de cada commit | Scan de secrets para prevenir leaks en Git |
| **Audit log** | Registro estructurado de accesos para trazabilidad forense | JSON con timestamp, tenant_id, secret_name, result |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: SECURITY-RULES VALIDATION】
Prompt de prueba: "Validar configuración de API key para módulo de IA"

Respuesta esperada de la IA:
1. Identificar que la tarea requiere manejo seguro de secrets (C3)
2. Consultar 01-RULES/03-SECURITY-RULES.md para reglas SEC-001 a SEC-012
3. Validar configuración con audit-secrets.sh:
   • Verificar que NO hay api_key hardcodeado
   • Verificar que usa os.environ["API_KEY"] o similar
   • Verificar que .env.example tiene placeholder, no valor real
4. Si configuración es válida → retornar con frontmatter: constraints_mapped: ["C3", "C4"]
5. Si configuración es inválida → retornar error estructurado:
   "❌ BLOCKING_ISSUE: API key hardcodeada. Corrección: usar os.environ['API_KEY']"
6. Incluir validation_command: audit-secrets.sh --file <config> --json

Si la IA retorna configuración con api_key="sk-xxx", omite validación con audit-secrets.sh, 
o no declara C3 en constraints_mapped → FALLA DE SEGURIDAD C3.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[00-STACK-SELECTOR]]` → Motor de decisión: ruta → lenguaje → constraints
- `[[AI-NAVIGATION-CONTRACT]]` → Reglas inamovibles: C3 es fail-fast
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers: C3 obligatorio para Tier 2+
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo C3 por carpeta
- `[[05-CONFIGURATIONS/validation/audit-secrets.sh]]` → Detección automática de secrets hardcodeados
- `[[02-SKILLS/SEGURIDAD/security-hardening-vps.md]]` → Hardening de infraestructura
- `[[06-PROGRAMMING/python/secrets-management-patterns.md]]` → Patrones de gestión de secrets en Python
- `[[06-PROGRAMMING/go/secrets-management-c3.go.md]]` → Patrones de gestión de secrets en Go

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_security_rule": {
      "requires_files_update": [
        "01-RULES/03-SECURITY-RULES.md: add rule with format ## SEC-XXX: <TÍTULO>",
        "05-CONFIGURATIONS/validation/audit-secrets.sh: update patterns if rule affects detection",
        "norms-matrix.json: update constraint mapping if rule introduces new requirement",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if rule affects validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new rules must not invalidate existing artifacts that comply with current C3 definition"
    },
    "new_secret_manager_support": {
      "requires_files_update": [
        "01-RULES/03-SECURITY-RULES.md: add section for new secret manager",
        "06-PROGRAMMING/: add language-specific integration patterns",
        "05-CONFIGURATIONS/templates/: add example config for new manager",
        "Human approval required: true"
      ],
      "backward_compatibility": "new secret manager support must not break existing Vault/AWS patterns"
    }
  },
  "compatibility_rule": "Nuevas reglas de seguridad no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【7】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las reglas se aplican en orden SEC-001 → SEC-012.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "security_rules_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/03-SECURITY-RULES.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraint_primary": "C3",
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "SEC-001": {
      "title": "Secrets Solo en Variables de Entorno",
      "constraint": "C3",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "audit-secrets.sh",
      "applicable_domains": ["bash", "python", "go", "javascript", "yaml"],
      "doc_description": "Nunca hardcodear secrets. Siempre usar variables de entorno con validación de existencia."
    },
    "SEC-002": {
      "title": ".gitignore para Archivos Sensibles",
      "constraint": "C3",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "pre-commit hook + audit-secrets.sh",
      "applicable_domains": ["git", "ci-cd"],
      "doc_description": "Nunca versionar .env, certificados privados, configs con secrets."
    },
    "SEC-003": {
      "title": "Secret Managers para Producción",
      "constraint": "C3",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "manual audit + vault integration test",
      "applicable_domains": ["production", "vault", "aws-secrets"],
      "doc_description": "En producción, usar secret managers con rotación automática, no env vars simples."
    },
    "SEC-004": {
      "title": "Scrubbing de PII en Logs",
      "constraint": "C3 + C8",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "orchestrator-engine.sh --check-logging",
      "applicable_domains": ["logging", "observability"],
      "doc_description": "Nunca loguear secrets, tokens, passwords o PII en texto plano."
    },
    "SEC-005": {
      "title": "Validación de Secrets en CI/CD",
      "constraint": "C3 + C6",
      "priority": "high",
      "blocking_if_violated": true,
      "validation_tool": "audit-secrets.sh en GitHub Actions",
      "applicable_domains": ["ci-cd", "git-hooks"],
      "doc_description": "Escanear secrets en cada commit y pull request con patterns actualizados."
    },
    "SEC-006": {
      "title": "Secrets en Docker y Kubernetes",
      "constraint": "C3",
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_tool": "docker scan + kubectl audit",
      "applicable_domains": ["docker", "kubernetes", "containers"],
      "doc_description": "Nunca incluir secrets en Dockerfiles o manifests versionados."
    },
    "SEC-007": {
      "title": "Rotación y Revocación de Secrets",
      "constraint": "C3 + C7",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "secret rotation test",
      "applicable_domains": ["secret-management", "operations"],
      "doc_description": "Todo secret debe tener TTL definido y mecanismo de revocación inmediata."
    },
    "SEC-008": {
      "title": "Secrets en Tests y Desarrollo",
      "constraint": "C3",
      "priority": "medium",
      "blocking_if_violated": false,
      "validation_tool": "test suite + env validation",
      "applicable_domains": ["testing", "development"],
      "doc_description": "Tests y desarrollo deben usar mocks o secrets de prueba, nunca producción."
    },
    "SEC-009": {
      "title": "Auditoría de Accesos a Secrets",
      "constraint": "C3 + C8",
      "priority": "high",
      "blocking_if_violated": false,
      "validation_tool": "orchestrator-engine.sh --check-audit-logs",
      "applicable_domains": ["logging", "observability", "compliance"],
      "doc_description": "Todo acceso a secret debe ser auditado con tenant_id y actor."
    },
    "SEC-010": {
      "title": "Secrets en Webhooks y APIs Externas",
      "constraint": "C3",
      "priority": "high",
      "blocking_if_violated": true,
      "validation_tool": "webhook signature validation test",
      "applicable_domains": ["webhooks", "api-integration"],
      "doc_description": "Validar y proteger secrets en integraciones con APIs externas."
    },
    "SEC-011": {
      "title": "Educación y Concienciación de Seguridad",
      "constraint": "C3",
      "priority": "medium",
      "blocking_if_violated": false,
      "validation_tool": "training completion check",
      "applicable_domains": ["onboarding", "training"],
      "doc_description": "Todo desarrollador debe completar entrenamiento en manejo de secrets."
    },
    "SEC-012": {
      "title": "Respuesta a Incidentes de Seguridad",
      "constraint": "C3 + C7",
      "priority": "critical",
      "blocking_if_violated": false,
      "validation_tool": "incident response drill",
      "applicable_domains": ["incident-response", "operations"],
      "doc_description": "Procedimiento definido para respuesta a leaks de secrets."
    }
  },
  
  "validation_integration": {
    "audit-secrets.sh": {
      "purpose": "Detectar secrets hardcodeados en código/configs",
      "flags": ["--file", "--dir", "--patterns", "--strict", "--json"],
      "exit_codes": {"0": "no_secrets_found", "1": "secrets_detected"},
      "output_format": "JSON con secrets_found, patterns_checked, findings"
    },
    "verify-constraints.sh": {
      "purpose": "Validar declaración de C3 en frontmatter",
      "flags": ["--file", "--check-constraint", "--json"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con constraint_checked, declared_in_frontmatter, passed"
    },
    "orchestrator-engine.sh": {
      "purpose": "Validación integral con scoring y C3 enforcement",
      "flags": ["--file", "--mode", "--json", "--checks"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con score, passed, blocking_issues, constraints_applied"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear C3 como fail-fast constraint", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección automática de secrets hardcodeados", "load_order": 2},
      {"file": "02-SKILLS/SEGURIDAD/security-hardening-vps.md", "purpose": "Contexto de hardening de infraestructura", "load_order": 3}
    ],
    "implementation_patterns": [
      {"file": "06-PROGRAMMING/python/secrets-management-patterns.md", "purpose": "Patrones de gestión de secrets en Python", "load_order": 1},
      {"file": "06-PROGRAMMING/go/secrets-management-c3.go.md", "purpose": "Patrones de gestión de secrets en Go", "load_order": 2},
      {"file": "06-PROGRAMMING/bash/secrets-management-c3.md", "purpose": "Patrones de gestión de secrets en Bash", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "hardcoded_secret_detected": "Secret hardcodeado detectado en archivo '{file}': '{pattern}'. Usar variable de entorno: {suggested_fix}.",
    "missing_env_validation": "Variable de entorno '{var}' usada sin validación de existencia. Añadir: if [ -z \"$VAR\" ]; then exit 1; fi",
    "gitignore_missing": "Archivo sensible '{file}' no está en .gitignore. Añadir patrón para prevenir commit accidental.",
    "log_exposes_secret": "Log en '{file}' expone valor de secret. Scrubear con ***REDACTED*** antes de loguear.",
    "dockerfile_has_secret": "Dockerfile en '{file}' incluye ENV con secret. Usar secrets de Docker o inyección en runtime.",
    "k8s_manifest_has_secret": "Kubernetes manifest en '{file}' incluye stringData con secret. Crear secret con kubectl, no versionar valores."
  },
  
  "expansion_hooks": {
    "new_secret_pattern": {
      "requires_files_update": [
        "01-RULES/03-SECURITY-RULES.md: add pattern to SEC-005 detection table",
        "05-CONFIGURATIONS/validation/audit-secrets.sh: add regex to default patterns",
        "Test suite: add regression test for new pattern",
        "Human approval required: true"
      ],
      "backward_compatibility": "new patterns must not cause false positives on existing valid code"
    },
    "new_secret_manager": {
      "requires_files_update": [
        "01-RULES/03-SECURITY-RULES.md: add section for new secret manager",
        "06-PROGRAMMING/: add language-specific integration patterns",
        "05-CONFIGURATIONS/templates/: add example config for new manager",
        "Human approval required: true"
      ],
      "backward_compatibility": "new secret manager support must not break existing Vault/AWS patterns"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "security-rules.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any security validation can be reproduced identically using this rule set + audit-secrets.sh"
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
# 1. Verificar que el frontmatter es YAML válido
yq eval '.canonical_path' 01-RULES/03-SECURITY-RULES.md
# Esperado: "/01-RULES/03-SECURITY-RULES.md"

# 2. Verificar que constraints_mapped incluye C3 (crítico)
yq eval '.constraints_mapped | contains(["C3"])' 01-RULES/03-SECURITY-RULES.md
# Esperado: true

# 3. Verificar que las 12 reglas SEC-001 a SEC-012 están presentes
grep -c "SEC-0[0-9][0-9]:" 01-RULES/03-SECURITY-RULES.md | awk '{if($1==12) print "✅ 12 reglas presentes"; else print "⚠️ Faltan reglas"}'

# 4. Verificar que audit-secrets.sh está referenciado para validación automática
grep -q "audit-secrets.sh" 01-RULES/03-SECURITY-RULES.md && echo "✅ Validación automática documentada"

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' 01-RULES/03-SECURITY-RULES.md | tail -1 | cut -d: -f1) 01-RULES/03-SECURITY-RULES.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en 01-RULES/? → SÍ
# - ¿El lenguaje es markdown con reglas de gobernanza? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C3 mandatory → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/01-RULES/03-SECURITY-RULES.md"`  
- ✅ `constraints_mapped` incluye C3 (fail-fast) + C4, C5, C6, C8  
- ✅ 12 reglas SEC-001 a SEC-012 documentadas con ejemplos ✅/❌/🔧  
- ✅ Integración con `audit-secrets.sh` para validación automática de secrets  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este contrato es tu garantía de seguridad. No es opcional.  
> **ENV → VALIDATE → SCRUB → AUDIT → ROTATE**.  
> Si sigues ese flujo, nunca expondrás credenciales.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
