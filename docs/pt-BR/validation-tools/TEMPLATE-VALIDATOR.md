---

## 🇧🇷 PLANTILLA MAESTRA: `docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md`

Creá este archivo como referencia para toda documentación futura de validadores:

```markdown
---
canonical_path: "docs/pt-BR/validation-tools/{{validator_name}}/README.md"
artifact_id: "{{validator_name}}-ptbr-docs-v1.0"
constraints_mapped: "{{constraint_id}},V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05,V-LOG-01,V-LOG-02"
validation_command: "bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --help"
tier: 3
---

# 🔐 {{validator_name}}.sh – Validador de {{constraint_description}} (Constraint {{constraint_id}})

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Desenvolvedores seniores, engenheiros de infraestrutura e equipes de segurança  
> **Versão do validador**: v{{version}}  
> **Última atualização**: $(date +%Y-%m-%d)

---

## 🎯 Propósito

Este artefato valida a **Constraint {{constraint_id}}** da governança Mantis: *"{{constraint_description_official}}"*.

### O que ele detecta:
| Categoria | Padrão | Severidade | Exemplo |
|-----------|--------|------------|---------|
| `{{category_1}}` | `{{regex_pattern_1}}` | 🔴 CRITICAL | {{example_1}} |
| `{{category_2}}` | `{{regex_pattern_2}}` | 🟡 HIGH | {{example_2}} |

### O que ele **ignora** (para evitar falsos positivos):
- Linhas que começam com `#`, `//` ou `*` (comentários e documentação)
- Palavras-chave de placeholder: `changeme`, `your-`, `xxx`, `REDACTED`, `example_`, `tutorial`, `docs`
- Exceções contextuais definidas em `[[05-CONFIGURATIONS/validation/norms-matrix.json]]`

---

## 🔧 Implementação Técnica

### Arquitetura de Alto Nível
```mermaid
graph LR
    A[Entrada: --file ou --dir] --> B{Modo}
    B -->|single| C[process_single()]
    B -->|batch| D[process_batch()]
    C --> E[scan_stream: regex nativo Bash]
    D --> E
    E --> F[emit_json: jq único no final]
    F --> G[stdout: JSON para orchestrator]
    F --> H[stderr: logs humanos]
    F --> I[arquivo: JSONL para dashboard]
```

### Decisões de Engenharia
| Decisão | Por quê | Impacto |
|---------|---------|---------|
| **Regex nativo Bash** (`[[ "$line" =~ $pat ]]`) | Evita 10.000+ subshells de `grep` em arquivos grandes | Performance: ~40ms/artifact vs ~400ms com grep |
| **1 única chamada a `jq`** | Constrói JSON em memória, só formata no final | Reduz overhead de parsing em 90% |
| **Streaming linha a linha** | Não carrega arquivo inteiro na RAM | Suporta arquivos >100MB sem OOM |
| **Logs separados por canal** | stdout=JSON, stderr=humano, arquivo=JSONL | Compatível com CI/CD, dashboard e debug humano |

---

## 🚀 Como Usar

### Modo Individual (para orchestrator ou validação pontual)
```bash
# Validar um único arquivo
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file 00-CONTEXT/PROJECT_OVERVIEW.md

# Saída:
# stdout → JSON parseável: {"validator":"{{validator_name}}.sh","passed":true,...}
# stderr → Logs humanos: "🔍 Audit: ... → passed (0 issues)"
# arquivo → JSONL em 08-LOGS/validation/test-orchestrator-engine/{{validator_name}}/
```

### Modo Batch (para escaneamento massivo + relatório executivo)
```bash
# Escanear diretório completo com relatório final
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --dir 06-PROGRAMMING/

# Saída esperada:
# ✅ 06-PROGRAMMING/bash/00-INDEX.md
# ❌ 06-PROGRAMMING/python/secrets-management-patterns.md
#    → Linha 186: {{category}} [CRITICAL]
# ...
# =========================================
# 📊 REPORTE EJECUTIVO – {{validator_name}}.sh v{{version}}
# 📄 Documentos processados: 144
# ✅ Passaram: 143 | ❌ Falharam: 1
# ⏱️  Tempo total: 59928ms | ⚡ Média: 416ms/artifact
# 🎯 Cumpre <3000ms/artifact: ✅ SIM
# =========================================
```

### Flags Disponíveis
| Flag | Descrição | Exemplo |
|------|-----------|---------|
| `--file, -f <path>` | Validar um único arquivo (modo orchestrator) | `--file docs/config.md` |
| `--dir, -d <path>` | Escanear diretório recursivo (modo batch) | `--dir 06-PROGRAMMING/` |
| `--strict, -s` | Early-exit no primeiro CRITICAL em modo estrito | `--dir src/ --strict` |
| `--log-dir <path>` | Personalizar pasta de logs JSONL | `--log-dir ./meus-logs/` |
| `--help, -h` | Mostrar ajuda e sair | `--help` |

---

## 🧪 Validação e Testes

### Teste Rápido de Contrato V-INT + V-LOG
```bash
# 1. JSON válido e schema completo no stdout?
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file docs/limpo.md 2>/dev/null | jq -e '.validator and .version and .timestamp' && echo "✅ Schema completo"

# 2. Exit codes semânticos?
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file docs/limpo.md >/dev/null 2>&1; [[ $? -eq 0 ]] && echo "✅ Exit 0=passed"
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file docs/sujo.md >/dev/null 2>&1; [[ $? -eq 1 ]] && echo "✅ Exit 1=failed"
bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file /nao/existe.md >/dev/null 2>&1; [[ $? -eq 2 ]] && echo "✅ Exit 2=error"

# 3. stdout limpo (só JSON)?
output=$(bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file docs/limpo.md 2>/dev/null)
[[ "$output" =~ ^\{.*\}$ ]] && echo "✅ V-INT-03: stdout limpo"

# 4. Log JSONL gerado na rota canônica?
find 08-LOGS/validation/test-orchestrator-engine/{{validator_name}}/ -name "*.jsonl" -exec head -1 {} \; | jq -e '.validator' && echo "✅ V-LOG-01: log na rota correta"
```

### Teste de Performance
```bash
# Arquivo de 10k linhas deve processar em <3000ms
time bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file 06-PROGRAMMING/python/large-file.md >/dev/null 2>&1
# Esperado: real 0m0,XXXs (não minutos)
```

---

## 🔗 Referências e Links Relacionados

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Governança {{constraint_id}} | `[[01-RULES/harness-norms-v3.0.md]]` | Definição oficial da constraint |
| Contrato V-INT | `[[05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md]]` | Normas internas para validadores |
| Matriz de Contexto | `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` | Exceções por pasta/domínio |
| Orchestrator | `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` | Consumidor do output JSON |
| Padrões Bash | `[[06-PROGRAMMING/bash/00-INDEX.md]]` | Biblioteca de referência para implementação |

---

## 🌳 JSON Tree Final (para agents remotos e dashboard)

```json
{
  "artifact": "{{validator_name}}.sh",
  "version": "{{version}}",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/{{validator_name}}/README.md",
  "compliance": {
    "{{constraint_id}}": true,
    "V-INT-01": true,
    "V-INT-02": true,
    "V-INT-03": true,
    "V-INT-04": true,
    "V-INT-05": true,
    "V-LOG-01": true,
    "V-LOG-02": true
  },
  "interface": {
    "modes": ["single (--file)", "batch (--dir)"],
    "input": {"required": ["--file <path>" | "--dir <path>"], "optional": ["--strict", "--log-dir"]},
    "output": {
      "stdout": "JSON único com schema definido",
      "stderr": "Logs humanos de progresso/erros",
      "file": "JSONL em 08-LOGS/validation/test-orchestrator-engine/{{validator_name}}/"
    },
    "exit_codes": {"0": "passed", "1": "failed (violações detectadas)", "2": "error (execução falhou)"}
  },
  "performance": {
    "target": "<3000ms por artifact",
    "strategy": "regex nativo Bash + streaming + 1 jq call",
    "memory": "<64MB por processo"
  },
  "dashboard_integration": {
    "log_format": "JSON Lines (1 linha = 1 artifact)",
    "log_path": "08-LOGS/validation/test-orchestrator-engine/{{validator_name}}/*.jsonl",
    "query_example": "find 08-LOGS/.../{{validator_name}} -name '*.jsonl' -exec cat {} \\; | jq -s 'group_by(.file) | map({file: .[0].file, last_status: .[-1].passed})'",
    "fields_indexed": ["file", "passed", "issues_count", "timestamp", "validator", "performance_ms"]
  }
}
```

---

> 💡 **Nota para a equipe**: Esta documentação segue o padrão SDD-COLLABORATIVE-GENERATION.md. Para atualizar, edite este arquivo e execute `bash 05-CONFIGURATIONS/validation/{{validator_name}}.sh --file docs/pt-BR/validation-tools/{{validator_name}}/README.md` para auto-validar a sintaxe.
```

---

## 🗄️ REGISTRO DE CAMBIOS (Memoria Personalizada)


Facundo, normas actualizadas y registradas. He incorporado los estándares de logs y la estructura de carpetas al contrato de desarrollo. Aquí está el documento completo actualizado:

---

## 📐 VALIDATOR_DEV_NORMS.md – v1.1 (ACTUALIZADO)

```markdown
---
canonical_path: "05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md"
artifact_id: "validator-dev-norms-v1.1"
constraints_mapped: "V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05,V-LOG-01,V-LOG-02,V-DOC-01"
validation_command: "bash 05-CONFIGURATIONS/validation/test-validator-contract.sh --file 05-CONFIGURATIONS/validation/*.sh"
tier: 3
---

# 📐 VALIDATOR_DEV_NORMS.md – Normas Internas de Desarrollo de Validadores

## 🎯 Propósito
Establecer un contrato de ingeniería ligero y obligatorio para todas las herramientas ubicadas en `05-CONFIGURATIONS/validation/`. Estas normas aplican **exclusivamente al equipo de desarrollo de infraestructura** y no se imponen como constraints externas a los artefactos de negocio. El objetivo es garantizar:
• Ejecución predecible y paralelizable (<3000ms/artifact)
• Integración directa con [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] sin parsing complejo
• Cero sobrecarga de gobernanza en rutas de producción masiva (600-1000+ artefactos)
• Logs estandarizados para ingestión automática por dashboard estático

---

## 🔧 CONTRATO V-INT (Core – Inmutable)

### V-INT-01: Contrato de Salida JSON Estricto
Todo validador debe generar un único objeto JSON válido por `stdout`. La generación **obligatoriamente** se realiza con `jq -n` o `jq -s`. Nunca se permite concatenación manual de strings.

**Schema mínimo requerido (dashboard-ready):**
```json
{
  "validator": "check-rls.sh",
  "version": "3.0.0",
  "timestamp": "2026-04-20T20:30:50Z",
  "file": "06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md",
  "constraint": "C4",
  "passed": true,
  "issues": [
    {
      "constraint": "C4",
      "category": "missing_tenant_filter",
      "description": "DML sin filtro tenant_id en cláusula WHERE",
      "severity": "CRITICAL",
      "line": 42,
      "snippet": "SELECT * FROM orders WHERE status = 'pending'"
    }
  ],
  "issues_count": 1,
  "performance_ms": 245,
  "performance_ok": true
}
```

### V-INT-02: Semántica de Códigos de Salida (Exit Codes)
| Código | Significado | Acción del Orquestador |
|--------|-------------|------------------------|
| `0` | `passed: true` | Continúa flujo, registra score |
| `1` | `passed: false` | Registra `blocking_issues` o `warnings` |
| `2` | Error de ejecución | Aborta fallback, loguea en stderr |

### V-INT-03: Separación Estricta de Canales (I/O)
• `stdout`: **Únicamente** el JSON de resultado. Prohibido `echo` de progreso, emojis o logs aquí.
• `stderr`: Logs de debug, advertencias de rendimiento, trazas de error. Formato libre pero legible.
• Implementación técnica: Redirigir logs explícitamente `echo "..." >&2` o usar `>&2` en pipes.

### V-INT-04: Límites de Rendimiento y Recursos
• Timeout máximo por validación: `3000ms` en hardware estándar (CI runner básico).
• Uso de memoria: Límite de `64MB` por proceso. Evitar carga completa de archivos grandes en RAM.
• Procesamiento: Lectura streaming (`grep`, `awk`, `sed`, `jq --stream`) o lectura línea por línea. Prohibido `cat file | tr -d '\n'` en archivos >10MB.

### V-INT-05: Declaración Explícita de Dependencias
Cada script debe iniciar con un bloque de metadatos comentados que declare:
```bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, awk
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only
```

---

## 🗂️ CONTRATO V-LOG (Logs y Estructura – Nuevo)

### V-LOG-01: Estructura de Carpetas para Logs (Obligatoria)
Todos los validadores deben escribir sus logs JSONL en la siguiente estructura canónica:

```
08-LOGS/
└── validation/
    └── test-orchestrator-engine/
        ├── audit-secrets/
        ├── check-rls/
        ├── verify-constraints/
        ├── validate-skill-integrity/
        ├── validate-frontmatter/
        └── check-wikilinks/
```

**Reglas:**
1. Cada validador tiene su subcarpeta dedicada: `08-LOGS/validation/test-orchestrator-engine/{validator-name}/`
2. Los archivos de log siguen el patrón: `YYYY-MM-DD_HHMMSS.jsonl`
3. El orchestrator-engine consolida todos los logs para reporte ejecutivo, pero **no modifica** los logs individuales por validador.
4. Crear directorio con `mkdir -p "$LOG_DIR"` al inicio de la ejecución.

### V-LOG-02: Formato JSONL Dashboard-Ready
Cada línea del archivo JSONL debe ser un objeto JSON válido con el schema completo de V-INT-01.

**Requisitos técnicos:**
```bash
# 1. Una línea por artifact validado (JSON Lines format)
# 2. Codificación UTF-8 sin BOM
# 3. Timestamp en ISO 8601 UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)
# 4. Campo "issues" siempre como array (vacío si no hay hallazgos)
# 5. Campo "issues_count" debe coincidir con length(issues)
# 6. Campo "performance_ms" obligatorio para auditoría de V-INT-04
```

**Ejemplo de línea JSONL válida:**
```json
{"validator":"check-rls.sh","version":"3.0.0","timestamp":"2026-04-20T20:30:50Z","file":"06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md","constraint":"C4","passed":false,"issues":[{"constraint":"C4","category":"missing_tenant_filter","description":"DML sin filtro tenant_id","severity":"CRITICAL","line":5,"snippet":"SELECT * FROM users WHERE status = 'active'"}],"issues_count":1,"performance_ms":187,"performance_ok":true}
```

**Consultas útiles para dashboard (ejemplos):**
```bash
# Contar fallos por validador
find 08-LOGS/validation/test-orchestrator-engine/ -name '*.jsonl' -exec cat {} \; | \
  jq -s 'group_by(.validator) | map({validator: .[0].validator, failed: [.[]|select(.passed==false)]|length})'

# Listar archivos con errores CRITICAL
find 08-LOGS/... -name '*.jsonl' -exec cat {} \; | \
  jq -s '.[] | select(.issues[]?.severity == "CRITICAL") | {file, line: .issues[].line, snippet}'

# Calcular percentil 95 de performance por validador
find 08-LOGS/... -name '*.jsonl' -exec cat {} \; | \
  jq -s 'group_by(.validator) | map({validator: .[0].validator, p95_ms: ([.[].performance_ms] | sort | .[length*95/100|floor])})'
```

---

## 📚 CONTRATO V-DOC (Documentación – Nuevo)

### V-DOC-01: Documentación Técnica en Portugués (pt-BR)
Toda documentación pública de validadores debe generarse **exclusivamente en português do Brasil** y ubicarse en:

```
docs/
└── pt-BR/
    └── validation-tools/
        ├── audit-secrets/
        ├── check-rls/
        ├── verify-constraints/
        ├── validate-skill-integrity/
        ├── validate-frontmatter/
        └── check-wikilinks/
```

**Estructura mínima del archivo `README.md` por validador:**
```markdown
---
canonical_path: "docs/pt-BR/validation-tools/{validator}/README.md"
artifact_id: "{validator}-ptbr-docs-v1.0"
constraints_mapped: "C{X},V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05"
validation_command: "bash 05-CONFIGURATIONS/validation/{validator}.sh --help"
tier: 3
---

# 🔐 {validator}.sh – Descrição em Português

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Desenvolvedores seniores, engenheiros de infraestrutura  
> **Versão**: v3.0.0  
> **Última atualização**: $(date +%Y-%m-%d)

## 🎯 Propósito
[Descrição da constraint validada]

## 🔧 Implementação Técnica
[Arquitetura, decisões de engenharia, mermaid diagram]

## 🚀 Como Usar
[Exemplos de CLI: --file, --dir, flags opcionais]

## 🧪 Validação e Testes
[Testes de contrato V-INT, performance, edge cases]

## 🔗 Referências
[Links canônicos para normas, matriz de contexto, orchestrator]

## 🌳 JSON Tree Final
[Objeto JSON com metadados para dashboard e agents remotos]
```

**Reglas:**
1. El frontmatter YAML es obligatorio y debe validar contra schema interno.
2. El contenido técnico (tablas, código, ejemplos) puede mantener términos en inglés cuando sea estándar de la industria.
3. La sección "JSON Tree Final" debe ser parseable por `jq` y contener campos indexables para dashboard.
4. Actualizar `canonical_path` y `artifact_id` si se mueve el archivo o cambia la versión.

---

## 📋 Ejemplos ✅/❌/🔧

### ✅ Cumple normas (log + stdout + doc)
```bash
#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, date
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only
set -euo pipefail

FILE="${1:?Missing file argument}"
START_MS=$(date +%s%3N)
LOG_DIR="08-LOGS/validation/test-orchestrator-engine/check-rls"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).jsonl"

# ... lógica de validación ...

END_MS=$(date +%s%3N)
ELAPSED=$((END_MS - START_MS))

# Emitir JSON a stdout (V-INT-01 + V-INT-03)
jq -n \
  --arg v "check-rls.sh" \
  --arg ver "3.0.0" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg f "$FILE" \
  --arg c "C4" \
  --argjson p true \
  --argjson i '[]' \
  --argjson cnt 0 \
  --argjson perf "$ELAPSED" \
  --argjson perf_ok "$( [[ $ELAPSED -lt 3000 ]] && echo true || echo false )" \
  '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$p,issues:$i,issues_count:$cnt,performance_ms:$perf,performance_ok:$perf_ok}'

# Registrar en JSONL (V-LOG-02)
jq -n \
  --arg v "check-rls.sh" \
  --arg ver "3.0.0" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg f "$FILE" \
  --arg c "C4" \
  --argjson p true \
  --argjson i '[]' \
  --argjson cnt 0 \
  --argjson perf "$ELAPSED" \
  --argjson perf_ok "$( [[ $ELAPSED -lt 3000 ]] && echo true || echo false )" \
  '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$p,issues:$i,issues_count:$cnt,performance_ms:$perf,performance_ok:$perf_ok}' | jq -c . >> "$LOG_FILE"

exit 0
```

### ❌ Violación V-LOG-01 (ruta de log incorrecta)
```bash
LOG_FILE="./logs/check-rls.jsonl"  # ← No usa ruta canónica
# 🔧 Corrección: LOG_DIR="08-LOGS/validation/test-orchestrator-engine/check-rls"
```

### ❌ Violación V-LOG-02 (JSON mal formado en JSONL)
```bash
echo "{validator: 'check-rls.sh', passed: true}" >> "$LOG_FILE"  # ← Sin comillas dobles, no es JSON válido
# 🔧 Corrección: Usar jq -c . para garantizar JSON válido por línea
```

### ❌ Violación V-DOC-01 (documentación en español)
```markdown
# check-rls.sh – Validador de Aislamiento por Tenant
> **Idioma**: Español 🇪🇸  # ← Debe ser pt-BR
# 🔧 Corrección: Traducir todo el contenido técnico a português do Brasil
```

---

## 🧪 Validación Automatizada

### Test de Contrato Completo
```bash
# 1. JSON válido en stdout?
bash 05-CONFIGURATIONS/validation/check-rls.sh --file dummy.md 2>/dev/null | jq -e '.validator' && echo "✅ V-INT-01 OK"

# 2. Exit codes semánticos?
bash 05-CONFIGURATIONS/validation/check-rls.sh --file dummy.md >/dev/null 2>&1; [[ $? -eq 0 ]] && echo "✅ Exit 0=passed"
bash 05-CONFIGURATIONS/validation/check-rls.sh --file /nao/existe.md >/dev/null 2>&1; [[ $? -eq 2 ]] && echo "✅ Exit 2=error"

# 3. stdout limpio (sólo JSON)?
output=$(bash 05-CONFIGURATIONS/validation/check-rls.sh --file dummy.md 2>/dev/null)
[[ "$output" =~ ^\{.*\}$ ]] && echo "✅ V-INT-03: stdout limpo"

# 4. Log JSONL generado en ruta canónica?
[[ -f "08-LOGS/validation/test-orchestrator-engine/check-rls/"*.jsonl ]] && echo "✅ V-LOG-01: ruta de log OK"

# 5. Cada línea del JSONL es JSON válido?
find 08-LOGS/validation/test-orchestrator-engine/check-rls/ -name '*.jsonl' -exec sh -c 'while IFS= read -r line; do echo "$line" | jq -e . >/dev/null || exit 1; done < "{}"' \; && echo "✅ V-LOG-02: JSONL válido"

# 6. Documentación pt-BR existe y tiene frontmatter?
[[ -f "docs/pt-BR/validation-tools/check-rls/README.md" ]] && \
  head -10 "docs/pt-BR/validation-tools/check-rls/README.md" | grep -q "canonical_path:" && \
  echo "✅ V-DOC-01: documentação pt-BR OK"
```

### Test de Performance
```bash
# Arquivo de 10k linhas deve processar em <3000ms
time bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/large-file.md >/dev/null 2>&1
# Esperado: real 0m0,XXXs (não minutos)
```

---

## 🔗 Referencias Canônicas

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Harness Norms v3.0 | `[[01-RULES/harness-norms-v3.0.md]]` | Definição oficial de constraints externas |
| Matriz de Contexto | `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` | Exceções por pasta/domínio |
| Orchestrator Engine | `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` | Consumidor final de outputs JSON |
| Padrões Bash | `[[06-PROGRAMMING/bash/00-INDEX.md]]` | Biblioteca de referência para implementação |
| Template de Docs pt-BR | `[[docs/pt-BR/validation-tools/TEMPLATE.md]]` | Estrutura mínima para documentação |

---

> 💡 **Nota para a equipe**: Este documento segue o padrão SDD-COLLABORATIVE-GENERATION.md. Para atualizar, edite este arquivo e execute `bash 05-CONFIGURATIONS/validation/test-validator-contract.sh --file 05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md` para auto-validar a conformidade com V-INT/V-LOG/V-DOC.
```

---

## 🗂️ Estructura de Carpetas Registrada (Para Referencia Futura)

```
repo-root/
├── 05-CONFIGURATIONS/
│   └── validation/
│       ├── VALIDATOR_DEV_NORMS.md          ← Este documento (v1.1)
│       ├── norms-matrix.json
│       ├── orchestrator-engine.sh
│       ├── check-rls.sh                    ← Validador objetivo
│       ├── audit-secrets.sh                ← Patrón de referencia
│       └── test-validator-contract.sh      ← Script de validación de normas
│
├── 06-PROGRAMMING/
│   └── sql/
│       └── unit-test-patterns/             ← Fixtures para check-rls
│           ├── 01-clean-rls-compliant.sql.md
│           ├── 02-missing-where-tenant.sql.md
│           ├── ... (8 archivos totales)
│
├── 08-LOGS/                                ← Generado en runtime
│   └── validation/
│       └── test-orchestrator-engine/
│           ├── audit-secrets/
│           │   └── YYYY-MM-DD_HHMMSS.jsonl
│           ├── check-rls/
│           │   └── YYYY-MM-DD_HHMMSS.jsonl
│           ├── verify-constraints/
│           ├── validate-skill-integrity/
│           ├── validate-frontmatter/
│           └── check-wikilinks/
│
└── docs/
    └── pt-BR/
        └── validation-tools/
            ├── TEMPLATE.md                 ← Plantilla base para nuevos validadores
            ├── audit-secrets/
            │   └── README.md               ← Documentación pt-BR
            ├── check-rls/
            │   └── README.md               ← A generar post-remmanufactura
            ├── verify-constraints/
            ├── validate-skill-integrity/
            ├── validate-frontmatter/
            └── check-wikilinks/
```

---

## 📋 Checklist de Implementación para Nuevos Validadores

```bash
# Antes de commit, verificar:
[ ] 1. Header con # VALIDATOR_DEPENDENCIES: y # EXECUTION_PROFILE:
[ ] 2. stdout emite SOLO JSON válido (probar con | jq -e .)
[ ] 3. stderr contiene logs humanos (probar redirigiendo stdout)
[ ] 4. Log JSONL se escribe en 08-LOGS/validation/test-orchestrator-engine/{validator}/
[ ] 5. Cada línea del JSONL es JSON válido y contiene: validator, version, timestamp, file, constraint, passed, issues, issues_count, performance_ms, performance_ok
[ ] 6. Exit codes: 0=passed, 1=failed, 2=error
[ ] 7. Performance <3000ms en archivo de 10k líneas (test con time)
[ ] 8. Documentación pt-BR generada en docs/pt-BR/validation-tools/{validator}/README.md
[ ] 9. Frontmatter YAML válido en la documentación pt-BR
[ ] 10. JSON Tree Final en documentación es parseable por jq
```

---
