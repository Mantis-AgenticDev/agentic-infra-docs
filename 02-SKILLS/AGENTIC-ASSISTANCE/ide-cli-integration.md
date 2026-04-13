---
title: ide-cli-integration.md
version: 1.0.0
date: 2025-06-10
status: PRODUCTION_READY
constraints_applied: [C1, C2, C3, C4, C5, C6, C7, C8]
inference_providers: [OpenRouter, DashScope, DeepSeek, MiniMax]
author: Mantis Agentic (SDD Hardened Standard)
category: AGENTIC-ASSISTANCE
---

# 🛠️ Integración IDE & CLI para Generación Asistida y Autogeneración SDD

## 🎯 OBJETIVO
Establecer el puente entre el entorno de desarrollo (VS Code, Cursor, Neovim) y la línea de comandos para orquestar la generación de código bajo estándares SDD Hardened. Este documento habilita flujos desde la **asistencia contextual** (snippets validados) hasta la **autogeneración completa** (empaquetado ZIP listo para deploy).

**Reglas Críticas**:
- 🔒 **C3**: Los scripts CLI nunca contienen secretos. Usan variables de entorno o inyección segura.
- 🏢 **C4**: Cada comando CLI debe recibir o inferir `tenant_id`. Sin él, el proceso aborta.
- ⏱️ **C1/C2**: Timeouts y límites de concurrencia configurables vía flags o `.env`.
- ☁️ **C6**: La generación de lógica de negocio usa modelos cloud (Qwen/DeepSeek) vía proxy.
- ✅❌ **C5**: Cada integración incluye validación binaria inmediata.

---

### Ejemplo 1: Inicialización de Contexto Agéntico (CLI)
**Objetivo**: Cargar `bootstrap-company.json` y validar `tenant_id` antes de cualquier generación | **Nivel**: 🟢 | **Constraints**: C3, C4, C5
```bash
#!/bin/bash
# scripts/init-agent-context.sh
set -euo pipefail

TENANT_ID=${1:?Error: C4 VIOLATION - tenant_id is required}
BOOTSTRAP_FILE="config/bootstrap-company.json"

if [ ! -f "$BOOTSTRAP_FILE" ]; then
  echo "❌ Error: $BOOTSTRAP_FILE not found. Run 'npm run generate:bootstrap' first."
  exit 1
fi

# Validar que el tenant_id del argumento coincide con el bootstrap
if ! grep -q "\"tenant_id\": \"$TENANT_ID\"" "$BOOTSTRAP_FILE"; then
  echo "❌ Error: C4 MISMATCH - Argument tenant_id ($TENANT_ID) does not match bootstrap file."
  exit 1
fi

export TENANT_ID
export MAX_RESULTS=$(jq -r '.infra_limits.maxResults' "$BOOTSTRAP_FILE")
export TIMEOUT_MS=$(jq -r '.infra_limits.timeout_ms' "$BOOTSTRAP_FILE")
export CONNECTION_LIMIT=$(jq -r '.infra_limits.connectionLimit' "$BOOTSTRAP_FILE")

echo "✅ Contexto agéntico cargado para tenant: $TENANT_ID (MaxResults: $MAX_RESULTS, Timeout: $TIMEOUT_MS)"
```
✅ Deberías ver: `✅ Contexto agéntico cargado para tenant: nexus-arg-01 ...`
❌ Si ves esto en su lugar: `Error: C4 VIOLATION - tenant_id is required` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | No se pasó argumento al script | `./init-agent-context.sh` | Ejecutar `./init-agent-context.sh mi-tenant-id` | C4 |
| `C4 MISMATCH` | El ID no está en el JSON de bootstrap | `cat config/bootstrap-company.json` | Actualizar JSON o usar el ID correcto | C4 |

---

### Ejemplo 2: VS Code Task para Generación de Skill RAG
**Objetivo**: Task de VS Code que genera un módulo RAG validado con C1-C6 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5, C6
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Generate RAG Skill (SDD Hardened)",
      "type": "shell",
      "command": "node scripts/generate-skill.js",
      "args": [
        "--type=rag",
        "--tenant=${input:tenantId}",
        "--model=qwen/qwen-2.5-72b-instruct"
      ],
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ],
  "inputs": [
    {
      "id": "tenantId",
      "type": "promptString",
      "description": "Ingrese Tenant ID (C4 Obligatorio)",
      "default": "nexus-arg-01"
    }
  ]
}
```
✅ Deberías ver: Panel de terminal nuevo ejecutando `generate-skill.js` con el tenant seleccionado.
❌ Si ves esto en su lugar: `Task not found` o `Input variable resolution failed` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Task not found` | Archivo `tasks.json` mal formado o en ruta incorrecta | `ls -la .vscode/tasks.json` | Verificar sintaxis JSON y ubicación en raíz del proyecto | C5 |
| `Input variable resolution failed` | VS Code no reconoce `${input:tenantId}` | Revisar sección `inputs` en `tasks.json` | Asegurar que `id` en `inputs` coincida con el uso en `args` | C4 |

---

### Ejemplo 3: Snippet de VS Code para Inyección Segura de Env Vars (C3)
**Objetivo**: Insertar patrón seguro de lectura de variables de entorno con validación temprana | **Nivel**: 🟢 | **Constraints**: C3, C4, C5
```json
// .vscode/snippets/typescript.code-snippets
{
  "Safe Env Var Injection (C3/C4)": {
    "prefix": "c3env",
    "body": [
      "const ${1:VAR_NAME} = process.env.${1:VAR_NAME};",
      "if (!${1:VAR_NAME}) throw new Error('C3/C4 VIOLATION: ${1:VAR_NAME} is mandatory');",
      "console.log(JSON.stringify({ event: 'env_loaded', var: '${1:VAR_NAME}', tenant_id: process.env.TENANT_ID }));"
    ],
    "description": "Inyecta variable de entorno con validación C3/C4 y log estructurado"
  }
}
```
✅ Deberías ver: Al escribir `c3env` y presionar Tab, se inserta el bloque con validación y log.
❌ Si ves esto en su lugar: `Snippet not showing` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Snippet not showing` | Extensión de snippets no recargada o error de sintaxis | `Developer: Reload Window` en VS Code | Verificar comillas escapadas en `body` del JSON | C3 |

---

### Ejemplo 4: Comando CLI para Validación de Constraints Pre-Commit
**Objetivo**: Script que verifica C1-C6 en archivos modificados antes de commit | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5, C6
```bash
#!/bin/bash
# scripts/validate-constraints-cli.sh
set -euo pipefail

echo "🔍 Validando constraints C1-C6 en cambios staged..."

# C3: No hardcodeo de credenciales
if git diff --cached -U0 | grep -iE "(api_key|secret|password)\s*=\s*['\"][^'\"]+['\"]"; then
  echo "❌ C3 VIOLATION: Posible hardcodeo de credenciales detectado."
  exit 1
fi

# C4: tenant_id en nuevos archivos TS/JS
NEW_FILES=$(git diff --cached --name-only --diff-filter=A | grep -E "\.(ts|js)$" || true)
if [ -n "$NEW_FILES" ]; then
  for file in $NEW_FILES; do
    if ! grep -q "tenant_id" "$file"; then
      echo "⚠️ C4 WARNING: Nuevo archivo $file no menciona tenant_id. Verificar aislamiento."
    fi
  done
fi

# C1/C2: Límites explícitos en fetch/DB calls
if git diff --cached -U0 | grep -E "(fetch|query|execute)" | grep -vE "(timeout|maxResults|limit)" > /dev/null; then
  echo "⚠️ C1/C2 WARNING: Llamadas DB/HTTP sin límites explícitos visibles en diff."
fi

echo "✅ Validación de constraints completada. Proceder con commit."
```
✅ Deberías ver: `✅ Validación de constraints completada. Proceder con commit.` o warnings específicos.
❌ Si ves esto en su lugar: `C3 VIOLATION: Posible hardcodeo...` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C3 VIOLATION` | Credencial literal en código staged | `git diff --cached` | Eliminar hardcodeo y usar `process.env` | C3 |
| `C4 WARNING` | Archivo nuevo sin referencia a tenant | Revisar archivo generado | Añadir `tenant_id` a logs/queries del archivo | C4 |

---

### Ejemplo 5: Integración Neovim con Lua para Generación Contextual
**Objetivo**: Función Lua en Neovim que envía selección de código a Qwen vía OpenRouter para refactorización C-Hardened | **Nivel**: 🟡 | **Constraints**: C3, C4, C5, C6
```lua
-- ~/.config/nvim/lua/agentic/generate.lua
local curl = require("plenary.curl")

function RefactorWithQwen()
  local tenant_id = vim.env.TENANT_ID
  if not tenant_id then
    vim.notify("C4 VIOLATION: Set TENANT_ID env var", vim.log.levels.ERROR)
    return
  end

  local visual_code = vim.fn.join(vim.fn.getregion(vim.fn.getpos("'<'"), vim.fn.getpos("'>"), {type = vim.fn.mode()}), "\n")
  local prompt = "Refactor this code to comply with SDD Hardened rules (C1-C6). Use process.env for secrets, add tenant_id to logs, and explicit timeouts. Model: qwen-2.5-72b."

  local res = curl.post({
    url = os.getenv("OPENROUTER_URL") .. "/chat/completions",
    headers = {
      ["Authorization"] = "Bearer " .. os.getenv("OPENROUTER_API_KEY"),
      ["Content-Type"] = "application/json"
    },
    body = vim.json.encode({
      model = "qwen/qwen-2.5-72b-instruct",
      messages = {{role = "user", content = prompt .. "\n\nCode:\n" .. visual_code}},
      max_tokens = 1024
    }),
    timeout = 30000
  })

  if res.status ~= 200 then
    vim.notify("API Error: " .. res.body, vim.log.levels.ERROR)
    return
  end

  local response = vim.json.decode(res.body)
  local new_code = response.choices[1].message.content:match("```typescript\n(.-)\n```") or response.choices[1].message.content
  
  vim.api.nvim_buf_set_lines(0, vim.fn.line("'<")-1, vim.fn.line("'>"), false, vim.split(new_code, "\n"))
  vim.notify("Refactoring complete with Qwen (Tenant: " .. tenant_id .. ")", vim.log.levels.INFO)
end

vim.keymap.set('v', '<leader>aq', RefactorWithQwen, {desc = 'Agentic Refactor with Qwen'})
```
✅ Deberías ver: Código seleccionado reemplazado por versión refactorizada y notificación de éxito.
❌ Si ves esto en su lugar: `C4 VIOLATION: Set TENANT_ID env var` o `API Error` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Variable de entorno no exportada en shell de Neovim | `:echo $TENANT_ID` en Neovim | Exportar `TENANT_ID` en `.bashrc`/`.zshrc` y reiniciar Neovim | C4 |
| `API Error` | Key inválida o timeout | Revisar `OPENROUTER_API_KEY` | Validar key y conectividad desde terminal | C3/C6 |

---

### Ejemplo 6: Generación de Dockerfile Multi-Stage Optimizado (CLI)
**Objetivo**: Script CLI que genera Dockerfile con multi-stage build y labels de tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```bash
#!/bin/bash
# scripts/generate-dockerfile.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
OUTPUT_FILE="Dockerfile"

cat > $OUTPUT_FILE <<EOF
# SDD Hardened Dockerfile for Tenant: $TENANT_ID
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV TENANT_ID=$TENANT_ID
ENV MAX_RESULTS=\${MAX_RESULTS:-50}
ENV TIMEOUT_MS=\${TIMEOUT_MS:-30000}
ENV CONNECTION_LIMIT=\${CONNECTION_LIMIT:-15}

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

LABEL com.mantis.tenant_id="$TENANT_ID"
LABEL com.mantis.sdd_version="3.0.0"

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD curl -f http://localhost:3000/healthz || exit 1
CMD ["node", "dist/index.js"]
EOF

echo "✅ Dockerfile generated for tenant: $TENANT_ID with C1/C2/C4 labels."
```
✅ Deberías ver: `✅ Dockerfile generated for tenant: ...` y archivo `Dockerfile` creado con labels y env vars.
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id required` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta argumento al ejecutar script | `./generate-dockerfile.sh` | Pasar tenant_id: `./generate-dockerfile.sh my-tenant` | C4 |

---

### Ejemplo 7: Validación de Schema JSON para Outputs de IA (Python CLI)
**Objetivo**: Script Python que valida que la salida de la IA cumpla con el schema SDD antes de guardar | **Nivel**: 🟡 | **Constraints**: C4, C5, C6
```python
# scripts/validate_ai_output.py
import json
import sys
import jsonschema

SCHEMA = {
    "type": "object",
    "required": ["tenant_id", "code", "validation_status"],
    "properties": {
        "tenant_id": {"type": "string"},
        "code": {"type": "string"},
        "validation_status": {"enum": ["pass", "fail"]},
        "constraints_applied": {"type": "array", "items": {"type": "string"}}
    }
}

def validate_output(file_path: str):
    try:
        with open(file_path, 'r') as f:
            data = json.load(f)
        
        jsonschema.validate(instance=data, schema=SCHEMA)
        
        if data['tenant_id'] != os.getenv('TENANT_ID'):
            raise ValueError(f"C4 MISMATCH: Output tenant {data['tenant_id']} != Env tenant {os.getenv('TENANT_ID')}")
            
        print(json.dumps({"event": "schema_validation_pass", "tenant_id": data['tenant_id']}))
    except Exception as e:
        print(json.dumps({"event": "schema_validation_fail", "error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python validate_ai_output.py <output_file.json>")
        sys.exit(1)
    validate_output(sys.argv[1])
```
✅ Deberías ver: `{"event": "schema_validation_pass", "tenant_id": "..."}` si el JSON es válido y coincide.
❌ Si ves esto en su lugar: `schema_validation_fail` o `C4 MISMATCH` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `schema_validation_fail` | JSON no cumple estructura requerida | `cat output.json \| python -m json.tool` | Corregir estructura del output de la IA | C5 |
| `C4 MISMATCH` | Tenant ID en JSON no coincide con entorno | `echo $TENANT_ID` | Alinear variables de entorno o regenerar output | C4 |

---

### Ejemplo 8: Generación de Terraform Module para RLS (CLI)
**Objetivo**: CLI que genera módulo Terraform para Row-Level Security en Postgres con tenant_id | **Nivel**: 🔴 | **Constraints**: C3, C4, C5
```bash
#!/bin/bash
# scripts/generate-tf-rls.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
MODULE_DIR="infra/modules/rls-${TENANT_ID}"

mkdir -p "$MODULE_DIR"

cat > "$MODULE_DIR/main.tf" <<EOF
resource "postgresql_role" "tenant_role" {
  name     = "role_${TENANT_ID}"
  login    = true
  password = var.db_password # C3: Usar variable, no hardcodear
}

resource "postgresql_grant" "tenant_grant" {
  role     = postgresql_role.tenant_role.name
  database = var.db_name
  schema   = "public"
  object_type = "table"
  objects  = ["rag_vectors", "sessions"]
  privileges = ["SELECT", "INSERT", "UPDATE"]
}

resource "postgresql_policy" "tenant_isolation" {
  name      = "policy_${TENANT_ID}_isolation"
  table     = "rag_vectors"
  role      = postgresql_role.tenant_role.name
  command   = "ALL"
  using     = "tenant_id = '${TENANT_ID}'"
  with_check = "tenant_id = '${TENANT_ID}'"
}
EOF

cat > "$MODULE_DIR/variables.tf" <<EOF
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_name" {
  type = string
}
EOF

echo "✅ Terraform RLS module generated for tenant: $TENANT_ID in $MODULE_DIR"
```
✅ Deberías ver: `✅ Terraform RLS module generated...` y archivos `.tf` creados con política RLS estricta.
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./generate-tf-rls.sh` | Ejecutar con argumento: `./generate-tf-rls.sh tenant-x` | C4 |

---

### Ejemplo 9: Webhook Listener para Trigger de Autogeneración (Node.js)
**Objetivo**: Servidor ligero que escucha webhooks de GitHub/GitLab y dispara pipeline de autogeneración | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5, C6
```typescript
// src/webhook-listener.ts
import express from 'express';
import { exec } from 'child_process';
import crypto from 'crypto';

const app = express();
const PORT = process.env.WEBHOOK_PORT || 3001;
const SECRET = process.env.WEBHOOK_SECRET;

app.use(express.json({ limit: '1mb' })); // C1/C2: Límite de payload

app.post('/trigger-generation', (req, res) => {
  const signature = req.headers['x-hub-signature-256'];
  const hmac = crypto.createHmac('sha256', SECRET!);
  const digest = 'sha256=' + hmac.update(JSON.stringify(req.body)).digest('hex');

  if (signature !== digest) {
    console.warn("C3 SECURITY: Invalid webhook signature");
    return res.status(401).json({ error: 'Invalid signature' });
  }

  const tenant_id = req.body.tenant_id;
  if (!tenant_id) {
    console.warn("C4 VIOLATION: Webhook missing tenant_id");
    return res.status(400).json({ error: 'C4 VIOLATION' });
  }

  console.log(JSON.stringify({ event: 'webhook_received', tenant_id, timestamp: Date.now() }));

  // Disparar script de autogeneración en background
  exec(`./scripts/packager-agentic.sh ${tenant_id}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Exec error: ${error.message}`);
      return;
    }
    console.log(`Autogeneration completed for ${tenant_id}: ${stdout}`);
  });

  res.status(200).json({ status: 'accepted', tenant_id });
});

app.listen(PORT, () => {
  console.log(`Webhook listener running on port ${PORT} with timeout ${process.env.TIMEOUT_MS}ms`);
});
```
✅ Deberías ver: Log `webhook_received` y ejecución en background de `packager-agentic.sh`.
❌ Si ves esto en su lugar: `Invalid signature` o `C4 VIOLATION` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Invalid signature` | Secreto de webhook no coincide | Verificar `WEBHOOK_SECRET` en entorno y plataforma | Alinear secretos en GitHub/GitLab y `.env` | C3 |
| `C4 VIOLATION` | Payload del webhook no tiene `tenant_id` | Inspeccionar cuerpo del webhook | Asegurar que el evento enviado incluya `tenant_id` | C4 |

---

### Ejemplo 10: Plugin de Cursor/Copilot para Inyección de Reglas C1-C6
**Objetivo**: Instrucción de sistema para plugins de IA en IDE que fuerza cumplimiento de reglas | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5, C6
```text
# .cursorrules o instrucción de sistema para Copilot

SIEMPRE sigue estas reglas SDD Hardened al generar código:

1. C3 SEGURIDAD: NUNCA hardcodees credenciales. Usa `process.env.VAR_NAME` o `os.getenv('VAR_NAME')`. Valida su existencia y lanza error si faltan.
2. C4 MULTI-TENANCY: TODAS las queries, logs y claves de caché DEBEN incluir `tenant_id`. Pásalo como argumento explícito.
3. C1/C2 LÍMITES: Define `maxResults`, `connectionLimit` y `timeout` en cada llamada a DB o API. Lee estos valores de variables de entorno con defaults seguros.
4. C6 INFERENCIA: Usa solo proxies cloud (OpenRouter/DashScope) para llamadas a LLM. No endpoints locales.
5. C5 VALIDACIÓN: Incluye bloques de comentario con `✅ Deberías ver:` y `❌ Si ves esto:` para cada función compleja.

Ejemplo de estructura de función:
async function miFuncion(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  // ... lógica ...
}
```
✅ Deberías ver: Código generado por el plugin que incluye validaciones de `tenant_id`, `process.env` y límites.
❌ Si ves esto en su lugar: Código con hardcodeo o sin `tenant_id` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| Hardcodeo en output | Reglas no cargadas o ignoradas por el modelo | Revisar `.cursorrules` o instrucciones | Reiniciar sesión de chat o verificar sintaxis de reglas | C3 |
| Falta `tenant_id` | Modelo no prioriza C4 | Reforzar prompt con "C4 OBLIGATORIO" | Añadir ejemplo negativo en reglas | C4 |

---

### Ejemplo 11: Generación de Documentación Automática desde Código (CLI)
**Objetivo**: Script que parsea código TS/Python y genera documentación Markdown con metadatos C1-C6 | **Nivel**: 🟡 | **Constraints**: C4, C5, C8
```bash
#!/bin/bash
# scripts/generate-docs-from-code.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
SRC_DIR="src"
DOC_DIR="docs/auto-generated"

mkdir -p "$DOC_DIR"

echo "# Documentación Autogenerada para Tenant: $TENANT_ID" > "$DOC_DIR/README.md"
echo "Generado el: $(date)" >> "$DOC_DIR/README.md"
echo "" >> "$DOC_DIR/README.md"

for file in $(find $SRC_DIR -name "*.ts" -o -name "*.py"); do
  echo "## Archivo: $file" >> "$DOC_DIR/README.md"
  echo '```' >> "$DOC_DIR/README.md"
  cat "$file" >> "$DOC_DIR/README.md"
  echo '```' >> "$DOC_DIR/README.md"
  echo "" >> "$DOC_DIR/README.md"
  
  # Extraer comentarios de validación C5
  if grep -q "✅ Deberías ver:" "$file"; then
    echo "### Validaciones C5 Detectadas:" >> "$DOC_DIR/README.md"
    grep -A 1 "✅ Deberías ver:" "$file" >> "$DOC_DIR/README.md"
    echo "" >> "$DOC_DIR/README.md"
  fi
done

echo "✅ Documentación generada en $DOC_DIR para tenant $TENANT_ID"
```
✅ Deberías ver: `✅ Documentación generada en docs/auto-generated...` y archivos Markdown con código y validaciones.
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #11
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta argumento | `./generate-docs-from-code.sh` | Ejecutar con tenant_id | C4 |

---

### Ejemplo 12: Integración con GitHub Actions para Validación Continua
**Objetivo**: Workflow que valida C1-C6 en cada PR usando scripts locales | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5, C6
```yaml
# .github/workflows/sdd-hardened-validation.yml
name: SDD Hardened Validation
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install Dependencies
        run: npm ci
      - name: Validate Constraints C1-C6
        env:
          TENANT_ID: 'ci-test-tenant'
          MAX_RESULTS: 10
          TIMEOUT_MS: 5000
          CONNECTION_LIMIT: 5
        run: |
          chmod +x scripts/validate-constraints-cli.sh
          ./scripts/validate-constraints-cli.sh
      - name: Validate AI Output Schema
        run: |
          python scripts/validate_ai_output.py test-output.json
```
✅ Deberías ver: Check verde en PR si todas las validaciones pasan.
❌ Si ves esto en su lugar: `Step "Validate Constraints C1-C6" failed` → Ve a Troubleshooting #12
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `failed` | Script de validación encontró violación | Revisar logs del job en GitHub Actions | Corregir código en PR para cumplir C1-C6 | C1-C6 |

---

### Ejemplo 13: CLI para Rotación de Credenciales (C3)
**Objetivo**: Script que rota claves de API en `.env` y servicios cloud de forma segura | **Nivel**: 🔴 | **Constraints**: C3, C4, C5
```bash
#!/bin/bash
# scripts/rotate-credentials.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
SERVICE=${2:?Error: Service name required (e.g., openrouter, qdrant)}

echo "🔄 Iniciando rotación de credenciales para $SERVICE en tenant $TENANT_ID"

# Simulación de rotación (en producción, integrar con AWS Secrets Manager/Vault)
NEW_KEY=$(openssl rand -hex 32)
OLD_KEY_VAR="${SERVICE^^}_API_KEY"

if [ -f ".env" ]; then
  sed -i.bak "s/^${OLD_KEY_VAR}=.*/${OLD_KEY_VAR}=${NEW_KEY}/" .env
  rm .env.bak
  echo "✅ Clave actualizada en .env local"
else
  echo "❌ Error: .env file not found"
  exit 1
fi

# Aquí iría llamada API para actualizar clave en proveedor cloud
echo "⚠️ Recuerda actualizar la clave en el dashboard de $SERVICE manualmente o vía API segura."
echo "{\"event\": \"credential_rotation_initiated\", \"tenant_id\": \"$TENANT_ID\", \"service\": \"$SERVICE\"}"
```
✅ Deberías ver: `✅ Clave actualizada en .env local` y log JSON de evento.
❌ Si ves esto en su lugar: `C4 VIOLATION` o `Error: Service name required` → Ve a Troubleshooting #13
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./rotate-credentials.sh` | Pasar tenant_id y servicio: `./rotate-credentials.sh tenant-x openrouter` | C4 |

---

### Ejemplo 14: Generación de Tests Unitarios con Mocks de Tenant (CLI)
**Objetivo**: Script que genera tests unitarios Jest/Pytest con mocks de `tenant_id` y límites | **Nivel**: 🟡 | **Constraints**: C4, C5
```bash
#!/bin/bash
# scripts/generate-unit-tests.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
COMPONENT=${2:?Error: Component name required}

TEST_FILE="tests/${COMPONENT}.test.ts"

cat > $TEST_FILE <<EOF
import { miFuncion } from '../src/$COMPONENT';

describe('$COMPONENT con SDD Hardened', () => {
  it('debe lanzar error C4 si falta tenant_id', async () => {
    await expect(miFuncion(undefined)).rejects.toThrow('C4 VIOLATION');
  });

  it('debe respetar maxResults y timeout', async () => {
    process.env.MAX_RESULTS = '5';
    process.env.TIMEOUT_MS = '1000';
    const result = await miFuncion('$TENANT_ID');
    expect(result.length).toBeLessThanOrEqual(5);
  });
});
EOF

echo "✅ Test unitario generado en $TEST_FILE para tenant $TENANT_ID"
```
✅ Deberías ver: `✅ Test unitario generado en tests/...` con casos de prueba C4 y límites.
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #14
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./generate-unit-tests.sh` | Ejecutar con argumentos correctos | C4 |

---

### Ejemplo 15: Dashboard de Observabilidad Local (CLI + HTML)
**Objetivo**: Generar reporte HTML simple con métricas de generación y validación C8 | **Nivel**: 🟡 | **Constraints**: C8, C5
```bash
#!/bin/bash
# scripts/generate-observability-report.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
REPORT_FILE="reports/observability-${TENANT_ID}-$(date +%Y%m%d).html"

mkdir -p reports

cat > $REPORT_FILE <<EOF
<html>
<head><title>Observability Report: $TENANT_ID</title></head>
<body>
<h1>Reporte de Observabilidad SDD Hardened</h1>
<p>Tenant ID: $TENANT_ID</p>
<p>Fecha: $(date)</p>
<h2>Métricas de Generación</h2>
<ul>
<li>Skills Generadas: $(grep -r "skill_generated" logs/ | wc -l)</li>
<li>Validaciones C5 Pasadas: $(grep -r "schema_validation_pass" logs/ | wc -l)</li>
<li>Violaciones C3 Detectadas: $(grep -r "C3 VIOLATION" logs/ | wc -l)</li>
</ul>
<h2>Logs Recientes</h2>
<pre>$(tail -n 50 logs/app.log)</pre>
</body>
</html>
EOF

echo "✅ Reporte de observabilidad generado en $REPORT_FILE"
open $REPORT_FILE # Abre en navegador (Mac/Linux)
```
✅ Deberías ver: `✅ Reporte de observabilidad generado...` y apertura de navegador con métricas.
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #15
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./generate-observability-report.sh` | Pasar tenant_id | C4 |

---

### Ejemplo 16: Integración con Slack para Notificaciones de Deploy
**Objetivo**: Script que envía resumen de generación y validación a canal de Slack | **Nivel**: 🟡 | **Constraints**: C3, C4, C5
```bash
#!/bin/bash
# scripts/notify-slack-deploy.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
ZIP_FILE=${2:?Error: Zip file path required}
SLACK_WEBHOOK_URL=$SLACK_DEPLOY_WEBHOOK_URL # C3: Variable de entorno

if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "❌ C3 VIOLATION: SLACK_DEPLOY_WEBHOOK_URL not set"
  exit 1
fi

PAYLOAD=$(cat <<EOF
{
  "text": "🚀 Deploy Ready for Tenant: $TENANT_ID",
  "attachments": [
    {
      "color": "#36a64f",
      "fields": [
        {"title": "Artifact", "value": "$ZIP_FILE", "short": true},
        {"title": "Generated At", "value": "$(date)", "short": true},
        {"title": "Constraints", "value": "C1-C6 Validated", "short": true}
      ]
    }
  ]
}
EOF
)

curl -X POST -H 'Content-type: application/json' --data "$PAYLOAD" $SLACK_WEBHOOK_URL
echo "✅ Notificación enviada a Slack para tenant $TENANT_ID"
```
✅ Deberías ver: `✅ Notificación enviada a Slack...` y mensaje en canal configurado.
❌ Si ves esto en su lugar: `C3 VIOLATION: SLACK_DEPLOY_WEBHOOK_URL not set` → Ve a Troubleshooting #16
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C3 VIOLATION` | Variable de entorno no definida | `echo $SLACK_DEPLOY_WEBHOOK_URL` | Exportar variable en entorno o CI/CD | C3 |

---

### Ejemplo 17: Limpieza de Artefactos Temporales (CLI)
**Objetivo**: Script seguro para limpiar directorios temporales de generación sin afectar producción | **Nivel**: 🟢 | **Constraints**: C5, C7
```bash
#!/bin/bash
# scripts/cleanup-temp-artifacts.sh
TEMP_DIRS=$(find . -type d -name ".temp_build_*" -mtime +1)

if [ -z "$TEMP_DIRS" ]; then
  echo "✅ No hay artefactos temporales antiguos para limpiar."
else
  echo "🧹 Limpiando artefactos temporales antiguos..."
  echo "$TEMP_DIRS" | xargs rm -rf
  echo "✅ Limpieza completada."
fi
```
✅ Deberías ver: `✅ Limpieza completada.` o mensaje de no acción.
❌ Si ves esto en su lugar: `rm: cannot remove...` (permisos) → Ve a Troubleshooting #17
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `cannot remove` | Permisos insuficientes | `ls -ld .temp_build_*` | Ejecutar con usuario propietario o `sudo` si es seguro | C7 |

---

### Ejemplo 18: Validación de Dependencias de Seguridad (CLI)
**Objetivo**: Auditar dependencias npm/pip en busca de vulnerabilidades conocidas | **Nivel**: 🔴 | **Constraints**: C3, C7
```bash
#!/bin/bash
# scripts/audit-dependencies.sh
echo "🔍 Auditando dependencias..."

if command -v npm &> /dev/null; then
  npm audit --production --json > audit-report.json
  HIGH_VULNS=$(jq '.metadata.vulnerabilities.high' audit-report.json)
  if [ "$HIGH_VULNS" -gt 0 ]; then
    echo "❌ Vulnerabilidades altas detectadas. Revisar audit-report.json"
    exit 1
  fi
fi

if command -v pip &> /dev/null; then
  pip check > pip-check.log
  if [ -s pip-check.log ]; then
    echo "❌ Conflictos de dependencias Python detectados. Revisar pip-check.log"
    exit 1
  fi
fi

echo "✅ Auditoría de dependencias completada. Sin vulnerabilidades críticas."
```
✅ Deberías ver: `✅ Auditoría de dependencias completada...`
❌ Si ves esto en su lugar: `Vulnerabilidades altas detectadas` → Ve a Troubleshooting #18
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Vulnerabilidades altas` | Paquete con CVE conocido | `cat audit-report.json` | Actualizar paquete vulnerable o aplicar parche | C7 |

---

### Ejemplo 19: Generación de CHANGELOG Automático (CLI)
**Objetivo**: Crear changelog basado en commits convencionales y tenant_id | **Nivel**: 🟡 | **Constraints**: C4, C8
```bash
#!/bin/bash
# scripts/generate-changelog.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
CHANGELOG_FILE="CHANGELOG-${TENANT_ID}.md"

echo "# Changelog para Tenant: $TENANT_ID" > $CHANGELOG_FILE
echo "" >> $CHANGELOG_FILE
git log --pretty=format:"- %s (%h)" --since="1 month ago" >> $CHANGELOG_FILE

echo "✅ Changelog generado en $CHANGELOG_FILE"
```
✅ Deberías ver: `✅ Changelog generado...` y archivo con lista de commits recientes.
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #19
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./generate-changelog.sh` | Pasar tenant_id | C4 |

---

### Ejemplo 20: Empaquetado Final ZIP con Firma Digital (CLI)
**Objetivo**: Crear ZIP final, firmarlo digitalmente y generar checksum para entrega segura | **Nivel**: 🔴 | **Constraints**: C3, C4, C5, C7
```bash
#!/bin/bash
# scripts/final-package-and-sign.sh
TENANT_ID=${1:?C4 VIOLATION: tenant_id required}
ZIP_NAME="release-${TENANT_ID}-$(date +%Y%m%d_%H%M).zip"

# 1. Empaquetar
zip -r $ZIP_NAME src/ config/ infra/ scripts/ -x "*.git/*" "*.env"

# 2. Generar Checksum
sha256sum $ZIP_NAME > ${ZIP_NAME}.sha256

# 3. Firmar (simulado con gpg, requiere clave configurada)
if command -v gpg &> /dev/null; then
  gpg --batch --yes --detach-sign --armor $ZIP_NAME
  echo "✅ Paquete firmado digitalmente: ${ZIP_NAME}.asc"
else
  echo "⚠️ GPG no instalado. Firma omitida. Solo checksum disponible."
fi

echo "{\"event\": \"package_signed\", \"tenant_id\": \"$TENANT_ID\", \"artifact\": \"$ZIP_NAME\", \"checksum\": \"$(cat ${ZIP_NAME}.sha256)\"}"
echo "✅ Entrega lista para deploy humano. Artifact: $ZIP_NAME"
```
✅ Deberías ver: `✅ Entrega lista para deploy humano...` con checksum y firma (si GPG está disponible).
❌ Si ves esto en su lugar: `C4 VIOLATION` → Ve a Troubleshooting #20
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Falta tenant_id | `./final-package-and-sign.sh` | Pasar tenant_id | C4 |
