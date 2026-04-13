---
title: "Validator Documentation"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "./05-CONFIGURATIONS/validation/validate-skill-integrity.sh \$0 --strict"
canonical_path: "05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md"
ai_optimized: true
---
# 📖 Validator Documentation & Constraints Mapping
## 📋 Constraints Explícitos
- **C1**: Límites de RAM/CPU (`mem_limit`, `cpus`, `pids_limit`) aplicados en validación y ejecución.
- **C2**: Aislamiento de CPU y concurrencia controlada por servicio.
- **C3**: Gestión de secretos vía `${VAR:?missing}` y `audit-secrets.sh`. Cero hardcode.
- **C4**: `tenant_id` obligatorio en queries, logs y políticas RLS.
- **C5**: Validación de esquemas JSON, auditoría SHA256 y checksums.
- **C6**: Inferencia exclusiva vía proxies cloud (OpenRouter/DashScope). Prohibido `localhost`.
- **C7**: Resiliencia con healthchecks, retry y circuit breakers.
- **C8**: Observabilidad con logs JSON, `tenant_id`, `trace_id` y OTEL.
## 📊 Validated Examples (≥5)
1. `audit-secrets.sh` detecta y bloquea credenciales en texto plano (C3)
2. `check-rls.sh` verifica `tenant_id` en políticas PostgreSQL (C4)
3. `validate-skill-integrity.sh` retorna `passed` solo con schema válido (C5)
4. `provider-router.yml` fuerza fallback cloud, bloquea modelos locales (C6)
5. `otel-tracing-config.yaml` inyecta `trace_id` y `tenant_id` en logs JSON (C8)
