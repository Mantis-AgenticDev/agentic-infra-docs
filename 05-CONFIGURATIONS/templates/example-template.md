---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Ejemplo didáctico ✅/❌ con troubleshooting y mapeo de constraints"
tags: ["example", "troubleshooting", "validation"]
---

# 📘 EJEMPLO: `[NOMBRE_CASO]`

## ✅ Implementación Correcta (C1-C6)
```bash
# C1: timeout explícito, C2: 1vCPU, C3: env var, C4: tenant filter, C5: hash, C6: cloud API
curl -s --max-time 30 \
  -H "Authorization: Bearer ${AI_KEY}" \
  -H "X-Tenant-ID: ${TENANT_ID}" \
  -d '{"prompt": "..."}' \
  "https://openrouter.ai/api/v1/chat/completions" | sha256sum
```

## ❌ Implementación Incorrecta (Violaciones)
```bash
# ❌ C1: Sin timeout (puede colgar)
# ❌ C3: Hardcode de clave
# ❌ C4: Sin tenant_id (fuga cross-tenant)
# ❌ C6: Endpoint local no documentado
curl -s http://localhost:11434/api/generate -d '{"prompt": "...", "key": "sk-123"}'
```

## 🔧 Troubleshooting
| Síntoma | Causa | Solución |
|---------|-------|----------|
| `Timeout exceeded` | Sin `--max-time` o pool saturado | Añadir retry exponencial + límite C1 |
| `403 Tenant mismatch` | Header `X-Tenant-ID` ausente | Inyectar desde contexto de request (C4) |
| `Secret exposed in logs` | `echo $KEY` en debug | Usar `set +x` y masking en CI (C3) |

## 📊 Validación Automatizada
- Frontmatter: `ai_optimized: true`
- Schema: Cumple `skill-input-output.schema.json`
- Scripts: Pasa `verify-constraints.sh` y `audit-secrets.sh`
```

---
