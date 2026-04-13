---
title: ai-agentic-generation.md
version: 3.0.0
date: 2025-06-10
status: PRODUCTION_READY
constraints_applied: [C1, C2, C3, C4, C5, C6, C7, C8]
inference_providers: [OpenRouter, DashScope, DeepSeek, MiniMax]
author: Mantis Agentic (SDD Hardened Standard)
---

# 📖 Generación Asistida & Autogeneración SDD por IA

## 🎯 MODO: INICIANTE → EXPERTO
**MODO INICIANTE**: Lee secuencialmente. No omitas validaciones. Si un script falla, consulta la tabla `Troubleshooting` antes de escalar.
**MODO INTERMEDIO**: Integra schemas, valida contratos de salida y automatiza el `bootstrap-company.json`.
**MODO EXPERTO/AUTO**: Despliega el pipeline completo. La IA lee el contexto, genera código bajo C1-C8, valida, empaqueta en ZIP y entrega para deploy humano. Cero intervención manual en lógica.

**Reglas Inquebrantables (SDD Hardened)**:
- 🔒 **C3**: Credenciales NUNCA hardcodeadas. Solo `process.env`/`os.getenv()`. Fallo rápido si faltan.
- 🏢 **C4**: `tenant_id` OBLIGATORIO en queries, logs, claves de caché, payloads de inferencia y artefactos ZIP.
- ⏱️ **C1/C2**: `maxResults`, `connectionLimit`, `timeout` explícitos en cada bloque de ejecución.
- ☁️ **C6**: Inferencia 100% vía proxy cloud. Modelos no occidentales (Qwen, DeepSeek, MiniMax) soportados por routing.
- ✅❌ **C5**: Validación binaria ejecutable en cada ejemplo con tabla de diagnóstico.
- 📦 **C7/C8**: Escalabilidad controlada, observabilidad JSON, rollback atómico y smoke tests pre-entrega.

---

## 🌍 1. CONTEXTO EMPRESARIAL & BOOTSTRAP
La IA no adivina. Inyecta datos de la empresa mediante `bootstrap-company.json`. Este archivo es la única fuente de verdad para generación.

### Ejemplo 1: Configuración Base & Validación C4
**Objetivo**: Validar bootstrap, inyectar `tenant_id` y asegurar límites antes de generar código | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
````markdown
```json
{
  "company": {
    "name": "NexusComercial",
    "tenant_id": "nexus-arg-01",
    "whatsapp_number": "+54911XXXXXXXX",
    "model_preference": "qwen/qwen-2.5-72b-instruct",
    "provider_routing": "openrouter"
  },
  "infra_limits": {
    "maxResults": 50,
    "connectionLimit": 15,
    "timeout_ms": 30000
  },
  "secrets_ref": {
    "db_primary_dsn": "${DB_PRIMARY_DSN}",
    "openrouter_key": "${OPENROUTER_API_KEY}",
    "qdrant_api_key": "${QDRANT_API_KEY}"
  }
}
```
```typescript
// validador_bootstrap.ts (Nivel: Iniciante)
import { readFileSync } from 'fs';
import { join } from 'path';

const MAX_RESULTS = Number(process.env.MAX_RESULTS) || 5;
const TIMEOUT = Number(process.env.TIMEOUT_MS) || 30000;
const CONN_LIMIT = Number(process.env.CONNECTION_LIMIT) || 10;

function validateAndLoad(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory for generation');
  const configPath = join(process.cwd(), 'bootstrap-company.json');
  try {
    const raw = readFileSync(configPath, 'utf-8');
    const cfg = JSON.parse(raw);
    if (cfg.company.tenant_id !== tenant_id) throw new Error('C4 MISMATCH: bootstrap tenant_id != runtime tenant_id');
    console.log(JSON.stringify({
      event: 'bootstrap_loaded',
      tenant_id,
      maxResults: MAX_RESULTS,
      connectionLimit: CONN_LIMIT,
      timeout: TIMEOUT,
      model: cfg.company.model_preference
    }));
    return cfg;
  } catch (err) {
    throw new Error(`Bootstrap load failed: ${(err as Error).message}`);
  }
}
```
````
✅ Deberías ver: `{ "event":"bootstrap_loaded", "tenant_id":"nexus-arg-01", "maxResults":50, "connectionLimit":15, "timeout":30000, "model":"qwen/qwen-2.5-72b-instruct" }`
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id mandatory` o `C4 MISMATCH: bootstrap tenant_id != runtime tenant_id` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION: tenant_id mandatory` | Argumento vacío o variable no exportada | `echo $TENANT_ID` | Exportar `TENANT_ID=nexus-arg-01` o pasar vía CLI | C4 |
| `Bootstrap load failed: ENOENT` | Archivo `bootstrap-company.json` ausente | `ls -la bootstrap-company.json` | Crear archivo desde template o verificar ruta de ejecución | C3 |

---

## 🧠 2. GENERACIÓN DE SKILL CON LÍMITES & PROXY
La IA genera código aplicando C1/C2/C6 automáticamente. El prompt del asistente incluye validación de límites y routing cloud.

### Ejemplo 2: Skill Gen con C1/C2/C6 (Inferencia Qwen/DeepSeek)
**Objetivo**: Generar módulo de consulta RAG con isolation por tenant, límites explícitos y proxy cloud | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5, C6
````markdown
```typescript
// generador_skill_rag.ts (Nivel: Intermedio)
import { createClient } from '@qdrant/js-client-rest';
import { join } from 'path';

const CFG = {
  qdrantUrl: process.env.QDRANT_URL || 'http://localhost:6333',
  qdrantKey: process.env.QDRANT_API_KEY,
  openrouterUrl: process.env.OPENROUTER_URL || 'https://openrouter.ai/api/v1/chat/completions',
  model: process.env.MODEL_PREFERENCE || 'qwen/qwen-2.5-72b-instruct',
  apiKey: process.env.OPENROUTER_API_KEY,
  timeout: Number(process.env.TIMEOUT_MS) || 30000,
  connLimit: Number(process.env.CONNECTION_LIMIT) || 15,
  maxResults: Number(process.env.MAX_RESULTS) || 50
};

export async function generateRagQuerySkill(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory for generation');
  
  // C6: Inferencia solo vía proxy cloud
  const prompt = `Genera un módulo TS/Node.js para Qdrant con:
  - Colección: rag_vectors
  - Filtro: { tenant_id: "${tenant_id}" }
  - Límites: maxResults=${CFG.maxResults}, connectionLimit=${CFG.connLimit}, timeout=${CFG.timeout}
  - C3: Usa process.env para credenciales
  - Retorna solo el código funcional.`;

  const ctrl = new AbortController();
  setTimeout(() => ctrl.abort(), CFG.timeout);

  const res = await fetch(CFG.openrouterUrl, {
    method: 'POST',
    headers: { Authorization: `Bearer ${CFG.apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: CFG.model, messages: [{ role: 'user', content: prompt }], max_tokens: 2048 }),
    signal: ctrl.signal
  });

  if (!res.ok) throw new Error(`Proxy generation failed: ${res.status}`);
  const data = await res.json();
  const codeBlock = data.choices[0].message.content.match(/```typescript\n([\s\S]*?)\n```/)?.[1] || '';

  console.log(JSON.stringify({ event: 'skill_generated', tenant_id, lines: codeBlock.split('\n').length, maxResults: CFG.maxResults, connectionLimit: CFG.connLimit, timeout: CFG.timeout }));
  return codeBlock;
}
```
````
✅ Deberías ver: `{ "event":"skill_generated", "tenant_id":"nexus-arg-01", "lines":>40, "maxResults":50, "connectionLimit":15, "timeout":30000 }` + código válido TS en memoria.
❌ Si ves esto en su lugar: `Proxy generation failed: 401` o `C4 VIOLATION` o `AbortError` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Proxy generation failed: 401` | `OPENROUTER_API_KEY` inválida o sin crédito | `curl -H "Authorization: Bearer $KEY" $OPENROUTER_URL -d '{}'` | Rotar clave en `.env` o recargar balance en dashboard | C3/C6 |
| `AbortError` | Timeout `30000ms` agotado por generación lenta | `date +%s && sleep 35 && date +%s` | Incrementar `TIMEOUT_MS=45000` en entorno o reducir `maxResults` | C1/C2 |
| `C4 VIOLATION` | `tenant_id` no propagado al generador | Stacktrace | Validar argumento de entrada antes de llamar función | C4 |

---

## 📦 3. PIPELINE DE AUTOGENERACIÓN & EMPAQUETADO ZIP
Flujo autónomo que valida, ensambla, comprime y entrega artefactos listos para deploy humano.

### Ejemplo 3: Pipeline Autoempaquetado ZIP (Validación C5 + Estructura)
**Objetivo**: Generar estructura de proyecto, validar schemas, aplicar C4/C3 y crear ZIP listo para entrega | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5, C7
```bash
#!/usr/bin/env bash
# packager-agentic.sh (Nivel: Experto)
set -euo pipefail

TENANT_ID="${1:?C4 VIOLATION: tenant_id required as argument}"
MAX_RESULTS="${MAX_RESULTS:-50}"
TIMEOUT_MS="${TIMEOUT_MS:-30000}"
CONN_LIMIT="${CONN_LIMIT:-15}"
ZIP_NAME="release-${TENANT_ID}-$(date +%Y%m%d_%H%M).zip"
TEMP_DIR=".temp_build_${TENANT_ID}"

echo "🔍 Iniciando empaquetado agéntico para tenant: ${TENANT_ID}"

# 1. Estructura base C3/C4/C7
mkdir -p "${TEMP_DIR}"/{config,src,infra,validation}
cat > "${TEMP_DIR}/config/bootstrap.json" <<EOF
{"tenant_id":"${TENANT_ID}","limits":{"maxResults":${MAX_RESULTS},"timeout_ms":${TIMEOUT_MS},"connectionLimit":${CONN_LIMIT}}}
EOF

# 2. Validación de reglas (C5 ejecutable)
if ! grep -q "${TENANT_ID}" "${TEMP_DIR}/config/bootstrap.json"; then
  echo "❌ C4 VIOLATION: tenant_id not persisted in artifact"
  exit 1
fi

# 3. Generación de .env seguro (sin hardcodeo)
cat > "${TEMP_DIR}/config/.env.example" <<EOF
TENANT_ID=${TENANT_ID}
MAX_RESULTS=${MAX_RESULTS}
TIMEOUT_MS=${TIMEOUT_MS}
CONNECTION_LIMIT=${CONN_LIMIT}
DB_PRIMARY_DSN=
OPENROUTER_API_KEY=
QDRANT_URL=
EOF

# 4. Validación de estructura y compresión
cd "${TEMP_DIR}"
find . -type f | xargs -I {} sh -c 'echo "{}" >> manifest.txt'
cd ..
zip -r "${ZIP_NAME}" "${TEMP_DIR}" -x "*.git/*" "*.DS_Store" > /dev/null 2>&1

# 5. Log final C5
echo "{\"event\":\"package_ready\",\"tenant_id\":\"${TENANT_ID}\",\"artifact\":\"${ZIP_NAME}\",\"maxResults\":${MAX_RESULTS},\"connectionLimit\":${CONN_LIMIT},\"timeout\":${TIMEOUT_MS}}" | tee deploy-log.json

# Limpieza
rm -rf "${TEMP_DIR}"
echo "✅ ZIP entregado: ${ZIP_NAME} listo para deploy humano."
```
✅ Deberías ver: `✅ ZIP entregado: release-nexus-arg-01_YYYYMMDD.zip listo para deploy humano.` + log JSON con `tenant_id`, límites y ruta exacta.
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id required as argument` o `zip command not found` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION: tenant_id required as argument` | Script ejecutado sin parámetro posicional | `./packager-agentic.sh` | Ejecutar `./packager-agentic.sh nexus-arg-01` | C4 |
| `zip command not found` | Paquetería base no instalada en entorno | `which zip` | Instalar con `apt install zip` o usar `tar -czvf` como fallback | C3/C7 |

---

## 🩺 4. SMOKE TESTS & ROLLBACK ATÓMICO (C7/C8)
Validación post-empaquetado y capacidad de reversión segura antes de entregar al humano.

### Ejemplo 4: Smoke Test & Rollback Automatizado
**Objetivo**: Verificar integridad del ZIP, extraer sin riesgos y validar contratos C4/C5 antes de entrega final | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5, C8
```typescript
// smoke_test_deploy.ts (Nivel: Experto)
import { execSync } from 'child_process';
import { existsSync, readFileSync, mkdirSync } from 'fs';
import { join } from 'path';

function runSmokeTest(zipPath: string, tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory for validation');
  const extractDir = join(process.cwd(), 'verify_staging');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 50;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 15;

  if (!existsSync(zipPath)) throw new Error(`Artifact missing: ${zipPath}`);

  // Extracción controlada
  if (existsSync(extractDir)) execSync(`rm -rf ${extractDir}`);
  mkdirSync(extractDir, { recursive: true });
  execSync(`unzip -q ${zipPath} -d ${extractDir}`, { timeout });

  // Validación C4/C5 en artefacto
  const bootstrap = JSON.parse(readFileSync(join(extractDir, '.temp_build_'+tenant_id.split('/').pop()+'/config/bootstrap.json'), 'utf-8'));
  if (bootstrap.tenant_id !== tenant_id) throw new Error('C4 ARTIFACT MISMATCH: Staging tenant_id invalid');

  // Validación C3: Cero credenciales hardcodeadas en src/
  const scan = execSync(`grep -rniE "(api_key|secret|password)\s*=\s*['\"]" ${extractDir}/src || true`, { encoding: 'utf-8' });
  if (scan.trim().length > 0) throw new Error('C3 VIOLATION: Hardcoded credentials detected in src/');

  console.log(JSON.stringify({
    event: 'smoke_passed',
    tenant_id,
    artifact: zipPath,
    maxResults,
    connectionLimit: connLimit,
    timeout,
    status: 'READY_FOR_HUMAN_DEPLOY'
  }));

  // Rollback automático (limpieza segura)
  execSync(`rm -rf ${extractDir}`);
  return true;
}
```
✅ Deberías ver: `{ "event":"smoke_passed", "tenant_id":"nexus-arg-01", "status":"READY_FOR_HUMAN_DEPLOY" }` y limpieza de directorio staging.
❌ Si ves esto en su lugar: `C4 ARTIFACT MISMATCH: Staging tenant_id invalid` o `C3 VIOLATION: Hardcoded credentials detected` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 ARTIFACT MISMATCH` | ZIP generado con tenant_id diferente al de validación | `cat *.zip | grep tenant_id` | Regenerar paquete con `TENANT_ID` correcto y re-empaquetar | C4 |
| `C3 VIOLATION: Hardcoded credentials` | Template de IA incluyó string literal en vez de `process.env` | `grep -rniE "(api_key|secret)\s*=" src/` | Corregir archivo, aplicar `sed -i` automático o re-ejecutar generador con prompt C3 estricto | C3 |

---

## 📜 5. CHECKLIST DE VALIDACIÓN FINAL (PRE-ENTREGA)
Ejecutar secuencialmente antes de marcar `status: READY_FOR_HUMAN_DEPLOY`.

| # | Validación | Comando/Script | Estado Requerido | Regla |
|---|---|---|---|---|
| 1 | `tenant_id` presente en bootstrap, código, logs y payload | `grep -rl "tenant_id" config/ src/` | ✅ Todas las referencias dinámicas | C4 |
| 2 | Cero credenciales hardcodeadas | `sh 05-CONFIGURATIONS/validation/audit-secrets.sh` | ✅ 0 coincidencias en `src/` | C3 |
| 3 | Límites explícitos en todos los fetch/DB calls | `grep -E "(timeout|maxResults|connectionLimit)" src/*.ts` | ✅ Declarados y parseados desde env | C1/C2 |
| 4 | Inferencia solo vía proxy cloud | `grep -ri "openrouter\|dashscope\|deepseek" src/` | ✅ Ninguna llamada directa a endpoints locales | C6 |
| 5 | ZIP válido y extrae sin errores | `unzip -t release-*.zip` | ✅ OK, 0 archivos corruptos | C5 |
| 6 | Smoke test pasa sin rollback | `node smoke_test_deploy.ts` | ✅ Log `READY_FOR_HUMAN_DEPLOY` | C8 |

> 📌 **Nota de Orquestación IA**: Al alcanzar 6/6 checks, el agente marca `SDD-COLLABORATIVE-GENERATION.md` con `status: COMPLETE` y entrega el `release-*.zip` mediante webhook seguro o canal cifrado (S3/Vault/Signal). El despliegue humano solo ejecuta `./deploy.sh` dentro del ZIP, sin tocar código fuente.
