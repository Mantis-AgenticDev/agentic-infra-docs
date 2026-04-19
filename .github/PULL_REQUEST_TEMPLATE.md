## 📋 Checklist de Validación
- [ ] Frontmatter YAML válido (6 campos mínimos)
- [ ] `constraints_mapped` aplica lógica SELECTIVE (V* solo si `skill_pgvector`)
- [ ] Ejemplos ≤5 líneas ejecutables
- [ ] Cero operadores pgvector fuera de `postgresql-pgvector/` (LANGUAGE LOCK)
- [ ] Validación local pasada: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <ruta> --json`
## 🎯 Constraints Aplicados
- [ ] C1-C8 (CORE)
- [ ] V1-V3 (SELECTIVE, si aplica)
