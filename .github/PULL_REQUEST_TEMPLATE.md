## 📋 Checklist Manual (Para el Autor del PR)

> ⚠️ Este checklist es una guía para humanos. Las validaciones automáticas se ejecutan LOCALMENTE antes de hacer push.

### ✅ Pre-Commit (Ejecutar en tu máquina local)
- [ ] Validar frontmatter: `bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh --file <ruta>`
- [ ] Validar constraints: `bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file <ruta> --json`
- [ ] Validar integridad: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <ruta> --json`
- [ ] Verificar LANGUAGE LOCK: `grep -rE '<->|<=>|<#>|vector\(' 06-PROGRAMMING/sql/ 06-PROGRAMMING/yaml-json-schema/` → debe estar vacío

### 🎯 Constraints Aplicados en este PR
- [ ] C1: Resource Limits (si aplica)
- [ ] C2: Explicit Timeouts (si aplica)
- [ ] C3: Secrets Validation (NUNCA hardcodear credenciales)
- [ ] C4: Multi-Tenant Isolation (tenant_id en queries/logs)
- [ ] C5: Integrity Verification (checksums si aplica)
- [ ] C6: Optional Dependencies (fallbacks documentados)
- [ ] C7: Path Safety (realpath, trap cleanup)
- [ ] C8: Structured Logging (JSON a stderr, no print/console.log)
- [ ] V1-V3: Vector constraints (SOLO si artifact_type == skill_pgvector)

### 📝 Descripción del Cambio
<!-- Breve descripción de qué cambia y por qué -->

### 🔗 Related Issues
<!-- Ej: Closes #123, Related to #456 -->

### 🧪 Validación Local Confirmada
```bash
# Pegar aquí el output de: orchestrator-engine.sh --file <ruta> --json
# Debe mostrar: "passed": true, "score": >=30
