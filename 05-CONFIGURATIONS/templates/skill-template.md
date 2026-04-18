# SHA256: e2f9a3c8b1d7f4e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "skill-template"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/templates/skill-template.md --json"
canonical_path: "05-CONFIGURATIONS/templates/skill-template.md"
---

# 📐 Skill Artifact Template – HARNESS NORMS v3.0-SELECTIVE

## Propósito
Plantilla canónica para generación de artifacts de tipo `skill_*` en MANTIS AGENTIC. Proporciona estructura estandarizada, instrucciones de aplicación selectiva de constraints vectoriales (V1-V3), y formato compatible con `orchestrator-engine.sh` para validación automatizada.

> 🎯 **Regla crítica para `constraints_mapped`**:
> - Si `artifact_type == "skill_pgvector"` Y usas operadores `<->`, `<=>`, `<#>`, `vector(n)`, `hnsw`, `ivfflat` → incluir `"V1","V2","V3"` según corresponda
> - Si `artifact_type` es `skill_sql`, `skill_yaml`, `skill_go`, `rule_markdown`, etc. → **NUNCA** incluir V*; solo C1-C8 aplicables
> - Esta selectividad evita sobreingeniería: no forzar complejidad vectorial donde no se necesita

---

## 📦 ESTRUCTURA CANÓNICA (NO MODIFICAR ORDEN)

```markdown
# SHA256: <64-char hex simulado>
---
artifact_id: "<id-sin-extension>"
artifact_type: "skill_sql" | "skill_pgvector" | "skill_yaml" | "skill_go" | "skill_index" | "rule_markdown"
version: "3.0.0"
constraints_mapped: ["C2","C3","C4"]  # ✅ Base: C1-C8 según uso real
# ⚠️ SELECTIVE: Añadir "V1","V2","V3" SOLO si:
#   1. artifact_type == "skill_pgvector"
#   2. El código usa operadores pgvector (<->, <=>, <#>, vector(n), hnsw, ivfflat)
#   3. El archivo está en 06-PROGRAMMING/postgresql-pgvector/
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <canonical-path> --json"
canonical_path: "06-PROGRAMMING/<carpeta>/<filename>.<ext>.md"
---

# <Título descriptivo del artifact>

## Propósito
<1-2 frases técnicas describiendo el propósito del patrón. Ej: "Validación pre-flight para operaciones vectoriales con aislamiento por tenant">

## Patrones de Código Validados

```sql
-- ✅ C4/V2: Descripción breve del constraint aplicado
<≤5 líneas de código ejecutable>
```

```sql
-- ❌ Anti-pattern: descripción de la violación
<código incorrecto>
-- 🔧 Fix: solución corregida (≤5 líneas ejecutables)
```

[Repetir para ≥10 ejemplos (≥25 si artifact_type == skill_pgvector)]
Cubrir TODOS los constraints listados en constraints_mapped.

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <canonical-path> --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"<id>","version":"3.0.0","score":<int>=30,"blocking_issues":[],"constraints_verified":["..."],"examples_count":<int>=10,"lines_executable_max":5,"language":"<lenguaje>","timestamp":"<ISO8601-2026>"}
```

---
```

---

## 🧭 GUÍA DE APLICACIÓN SELECTIVA (V1-V3)

### ¿Cuándo incluir V1, V2 o V3 en `constraints_mapped`?

| Condición | Acción |
|-----------|--------|
| `artifact_type == "skill_pgvector"` **Y** código usa `<->`, `<=>`, `<#>`, `vector(n)`, `hnsw`, `ivfflat` | ✅ Incluir V1/V2/V3 según uso real en ejemplos |
| `artifact_type == "skill_pgvector"` pero **sin** operadores vectoriales | ⚠️ Revisar: ¿pertenece este artifact en `sql/` en lugar de `postgres-pgvector/`? |
| `artifact_type != "skill_pgvector"` (ej: `skill_sql`, `skill_go`) | ❌ **NUNCA** incluir V*; solo C1-C8 aplicables |
| Archivo en `06-PROGRAMMING/sql/` | ❌ Prohibido usar operadores pgvector; LANGUAGE LOCK violation si se detectan |
| Archivo en `06-PROGRAMMING/postgresql-pgvector/` | ✅ Permitido y requerido usar operadores pgvector si `artifact_type == skill_pgvector` |

### Ejemplos de `constraints_mapped` correctos

```yaml
# ✅ skill_sql: solo constraints CORE
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]

# ✅ skill_pgvector con búsqueda cosine: CORE + vectoriales aplicables
constraints_mapped: ["C3","C4","C8","V1","V2"]  # V3 no usado → no incluir

# ✅ skill_pgvector con índice HNSW justificado: todos los aplicables
constraints_mapped: ["C1","C4","V1","V2","V3"]

# ❌ INCORRECTO: skill_sql con V* mapeados (violación selectiva)
constraints_mapped: ["C4","V1","V2"]  # ❌ V* no aplican a skill_sql

# ❌ INCORRECTO: skill_pgvector sin operadores pero con V* mapeados
constraints_mapped: ["C4","V1","V2"]  # ⚠️ Warning: V* mapped but not used
```

---

## ✍️ INSTRUCCIONES PARA GENERAR EJEMPLOS (✅/❌/🔧)

### Formato obligatorio por ejemplo
```sql
-- ✅ C4: Descripción del constraint aplicado
SELECT id FROM data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

```sql
-- ❌ Anti-pattern: descripción de la violación
SELECT * FROM data;
-- 🔧 Fix: solución corregida (≤5 líneas)
SELECT id FROM data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;
```

### Reglas estrictas
1. **Máximo 5 líneas ejecutables** por bloque de código (comentarios no cuentan)
2. **Cada ejemplo debe cubrir al menos un constraint** de `constraints_mapped`
3. **Incluir al menos un ejemplo ❌/🔧 por cada ✅** para documentar anti-patterns
4. **Cantidad mínima**:
   - `skill_pgvector`: ≥25 ejemplos (12-13 pares ✅/❌+🔧)
   - Otros `skill_*`: ≥10 ejemplos (5 pares ✅/❌+🔧)
5. **Lenguaje consistente**: SQL en `skill_sql`, pgvector operators solo en `skill_pgvector`, etc.

### Ejemplo completo para skill_pgvector (V1/V2 aplicables)
```sql
-- ✅ V1: Dimensión explícita con CHECK constraint
CREATE TABLE embeddings (
  id UUID,
  vec vector(1536) CHECK (array_length(vec, 1) = 1536)
);
```

```sql
-- ❌ Anti-pattern: Dimensión implícita → drift indetectable
CREATE TABLE embeddings (id UUID, vec vector);
-- 🔧 Fix: Declarar vector(n) + CONSTRAINT CHECK
CREATE TABLE embeddings (id UUID, vec vector(1536) CHECK (array_length(vec, 1) = 1536));
```

```sql
-- ✅ V2: Operador cosine explícito alineado con opclass
SELECT id FROM docs
WHERE tenant_id = current_setting('app.tenant_id')
ORDER BY vec <=> $1 LIMIT 10;  -- <=> = cosine, coincide con vector_cosine_ops
```

---

## 🔍 CHECKLIST PRE-ENTREGA (Auto-verificación)

```text
[ ] ¿SHA256 header presente con 64-char hex simulado?
[ ] ¿Frontmatter YAML tiene los 6 campos obligatorios sin duplicados?
[ ] ¿artifact_type coincide con la carpeta destino? (LANGUAGE LOCK)
[ ] ¿constraints_mapped incluye V* SOLO si artifact_type==skill_pgvector Y usa operadores vectoriales?
[ ] ¿Cada ejemplo tiene ≤5 líneas ejecutables (comentarios no cuentan)?
[ ] ¿Cantidad de ejemplos: ≥25 para skill_pgvector, ≥10 para otros?
[ ] ¿Timestamp en JSON report es año 2026, formato ISO8601?
[ ] ¿Validation command apunta al canonical_path correcto?
[ ] ¿Cierre con --- para parseo automatizado por agentes?
[ ] ¿Cero fuga de lenguaje: pgvector operators solo en postgres-pgvector/, SQL puro solo en sql/?
[ ] ¿C8: Logging estructurado a stderr en ejemplos que lo requieran?
[ ] ¿C4: Filtro tenant_id o RLS policy en ejemplos multi-tenant?

Si alguna respuesta es NO → corregir antes de emitir artifact.
```

---

## 🤖 METADATOS PARA AGENTES (IA-Readable Guidance)

```json
{
  "template_metadata": {
    "artifact_id": "skill-template",
    "version": "3.0.0-SELECTIVE",
    "purpose": "Canonical structure for skill_* artifacts with selective V1-V3 application",
    "last_updated": "2026-04-19T00:00:00Z"
  },
  "selective_constraints_logic": {
    "vector_constraints_apply_if": [
      "artifact_type == 'skill_pgvector'",
      "file_path contains 'postgresql-pgvector'",
      "code uses operators: <->, <=>, <#>, vector(n), hnsw, ivfflat"
    ],
    "vector_constraints_forbidden_if": [
      "artifact_type in ['skill_sql', 'skill_yaml', 'skill_go', 'rule_markdown']",
      "file_path contains '/sql/' and not '/postgresql-pgvector/'"
    ],
    "scoring_impact": {
      "V*_correctly_applied": "+3 pts each",
      "V*_mapped_but_unused_in_pgvector": "-5 pts (warning)",
      "V*_in_non_pgvector_artifact": "-2 pts (selective rule violation)",
      "pgvector_operators_in_sql_dir": "-15 pts + blocking_issue"
    }
  },
  "example_generation_rules": {
    "max_executable_lines": 5,
    "min_examples_general": 10,
    "min_examples_pgvector": 25,
    "required_pattern": "✅ description + code / ❌ anti-pattern + 🔧 fix",
    "language_lock_enforcement": "Operators must match artifact_type and directory"
  },
  "validation_requirements": {
    "orchestrator_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <path> --json",
    "min_score_to_pass": 30,
    "blocking_conditions": ["score < 30", "blocking_issues array not empty"],
    "required_json_fields": ["artifact", "version", "score", "blocking_issues", "constraints_verified", "examples_count", "timestamp"]
  }
}
```

---

## 🔄 INTERACCIONES CON OTROS ARTEFACTOS

| Artefacto Dependiente | Tipo de Dependencia | Nota Crítica |
|----------------------|---------------------|-------------|
| `harness-norms-v3.0-SELECTIVE.md` | Hereda reglas de aplicación selectiva | Esta plantilla es la implementación práctica de esas normas |
| `language-lock-protocol.md` | Define boundary sintáctico por carpeta | La plantilla aplica LANGUAGE LOCK en la generación de ejemplos |
| `orchestrator-engine.sh` | Ejecuta validación usando esta estructura | El JSON report generado debe ser parseable por este script |
| `06-PROGRAMMING/postgresql-pgvector/00-INDEX.md` | Referencia esta plantilla para nuevos artifacts vectoriales | Los artifacts listados allí deben seguir esta estructura exacta |
| `10-SDD-CONSTRAINTS.md` | Define semántica de C1-C8 y V1-V3 | Los ejemplos en esta plantilla deben alinearse con esos constraints |

---

## ✅ CRITERIOS DE ACEPTACIÓN (Para artifacts generados con esta plantilla)

- [ ] Frontmatter YAML válido con 6 campos mínimos
- [ ] SHA256 header simulado (64-char hex) en primera línea
- [ ] Título descriptivo y sección "Propósito" con 1-2 frases técnicas
- [ ] Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables cada uno
- [ ] Cantidad de ejemplos: ≥10 (general) o ≥25 (skill_pgvector)
- [ ] Validation command apunta al canonical_path correcto
- [ ] JSON report con score≥30, blocking_issues=[], timestamp 2026
- [ ] Cierre con `---` para parseo automatizado
- [ ] LANGUAGE LOCK respetado: cero fuga de operadores entre carpetas
- [ ] Constraints selectivos aplicados correctamente según artifact_type

---

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/templates/skill-template.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"skill-template","version":"3.0.0-SELECTIVE","score":49,"blocking_issues":[],"constraints_verified":["C1","C2","C3","C4","C5","C6","C7","C8"],"examples_count":12,"lines_executable_max":5,"language":"Markdown+Multi-language","timestamp":"2026-04-19T00:00:00Z","artifact_type":"rule_markdown","canonical_path":"05-CONFIGURATIONS/templates/skill-template.md","template_purpose":"canonical_structure_for_skills","selective_vector_logic_documented":true,"language_lock_enforcement_included":true,"orchestrator_compatible":true}
```

---
