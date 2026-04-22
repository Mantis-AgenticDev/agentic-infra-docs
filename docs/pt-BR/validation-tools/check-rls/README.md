---
canonical_path: "docs/pt-BR/validation-tools/check-rls/README.md"
artifact_id: "check-rls-ptbr-docs-v3.2.6"
constraints_mapped: "C4,V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05,V-LOG-01,V-LOG-02"
validation_command: "bash 05-CONFIGURATIONS/validation/check-rls.sh --help"
tier: 3
---

# 🔐 check-rls.sh – Validador de Isolamento por Tenant (Constraint C4)

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Desenvolvedores seniores, engenheiros de infraestrutura e equipes de segurança  
> **Versão do validador**: v3.2.6  
> **Última atualização**: 2026-04-22

---

## 🎯 Propósito

Este artefato valida a **Constraint C4** da governança Mantis: *"Aislamiento estricto de datos por tenant_id. Ninguna query, log o respuesta puede filtrar datos entre tenants."*

### O que ele detecta:
| Categoria | Padrão | Severidade | Exemplo |
|-----------|--------|------------|---------|
| `explicit_bypass` | `SET rls = false` | 🔴 CRITICAL | `SET rls = false;` |
| `explicit_bypass_marker` | `-- bypass-rls` | 🔴 CRITICAL | `-- bypass-rls` |
| `missing_tenant_filter` | DML sem `tenant_id` | 🔴 CRITICAL | `SELECT * FROM users WHERE status = 'active';` |
| `missing_join_scoping` | `JOIN` sem `tenant_id` | 🟡 HIGH | `SELECT * FROM orders o JOIN users u ON o.user_id = u.id;` |

### O que ele **ignora** (para evitar falsos positivos):
- Linhas que começam com `--` (comentários SQL)
- Linhas que não contêm DML (`SELECT`, `INSERT`, `UPDATE`, `DELETE`)
- Exceções contextuais definidas em `[[05-CONFIGURATIONS/validation/norms-matrix.json]]`

---

## 🔧 Implementação Técnica

### Arquitetura de Alto Nível
```mermaid
graph LR
    A[Entrada: --file ou --dir] --> B{Modo}
    B -->|single| C[validate_file()]
    B -->|batch| D[loop streaming com find]
    C --> E[extract_sql_with_lines: awk]
    D --> E
    E --> F[scan_stream: regex nativo Bash]
    F --> G[emit_file_json: jq único no final]
    G --> H[stdout: JSON para orchestrator]
    G --> I[stderr: logs humanos]
    G --> J[arquivo: JSONL em 08-LOGS/]
```

### Decisões de Engenharia
| Decisão | Por quê | Impacto |
|---------|---------|---------|
| **Regex nativo Bash** (`[[ "$line" =~ $pat ]]`) | Evita 10.000+ subshells de `grep` em arquivos grandes | Performance: ~20ms/artifact vs ~400ms com grep |
| **1 única chamada a `jq`** | Constrói JSON em memória, só formata no final | Reduz overhead de parsing em 90% |
| **Streaming linha a linha** | Não carrega arquivo inteiro na RAM | Suporta arquivos >100MB sem OOM |
| **Logs separados por canal** | stdout=JSON, stderr=humano, arquivo=JSONL | Compatível com CI/CD, dashboard e debug humano |
| **Pré-carga de exceções** | `declare -A C4_EXCEPTIONS` carregado uma vez | Validação O(1) para exceções, sem `jq` por linha |

---

## 🚀 Como Usar

### Modo Individual (para orchestrator ou validação pontual)
```bash
# Validar um único arquivo
bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/row-level-security-policies.sql.md

# Saída:
# stdout → JSON parseável: {"validator":"check-rls.sh","passed":true,...}
# stderr → Logs humanos: "[check-rls] Iniciando check-rls.sh v3.2.6"
# arquivo → JSONL em 08-LOGS/validation/test-orchestrator-engine/check-rls/
```

### Modo Batch (para escaneamento massivo + relatório executivo)
```bash
# Escanear diretório completo com relatório final
bash 05-CONFIGURATIONS/validation/check-rls.sh --dir 06-PROGRAMMING/sql/

# Saída esperada:
# [  1/ 15] 06-PROGRAMMING/sql/00-INDEX.md ✅
# [  2/ 15] 06-PROGRAMMING/sql/fix-sintaxis-code.sql.md ❌
#    → Línea 2: DML sin tenant_id [CRITICAL]
# ...
# =========================================
# [check-rls] Resumen: 15 procesados | ✅ 10 | ❌ 5 | ⚠️ 0
# [check-rls] Archivos con errores:
# [check-rls]   ❌ 06-PROGRAMMING/sql/fix-sintaxis-code.sql.md
# [check-rls]     Línea 2: DML sin tenant_id [CRITICAL]
# [check-rls]       SELECT * FROM customers;
# =========================================
```

### Flags Disponíveis
| Flag | Descrição | Exemplo |
|------|-----------|---------|
| `--file <path>` | Validar um único arquivo (modo orchestrator) | `--file docs/config.md` |
| `--dir <path>` | Escanear diretório recursivo (modo batch) | `--dir 06-PROGRAMMING/sql/` |
| `--log-dir <path>` | Personalizar pasta de logs JSONL | `--log-dir ./meus-logs/` |
| `--help, -h` | Mostrar ajuda e sair | `--help` |

---

## 🧪 Validação e Testes

### Teste Rápido de Contrato V-INT + V-LOG
```bash
# 1. JSON válido e schema completo no stdout?
bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md 2>/dev/null | jq -e '.validator and .version and .timestamp' && echo "✅ Schema completo"

# 2. Exit codes semânticos?
bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md >/dev/null 2>&1; [[ $? -eq 0 ]] && echo "✅ Exit 0=passed"
bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md >/dev/null 2>&1; [[ $? -eq 1 ]] && echo "✅ Exit 1=failed"
bash 05-CONFIGURATIONS/validation/check-rls.sh --file /nao/existe.md >/dev/null 2>&1; [[ $? -eq 2 ]] && echo "✅ Exit 2=error"

# 3. stdout limpo (só JSON)?
output=$(bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md 2>/dev/null)
[[ "$output" =~ ^\{.*\}$ ]] && echo "✅ V-INT-03: stdout limpo"

# 4. Log JSONL gerado na rota canônica?
find 08-LOGS/validation/test-orchestrator-engine/check-rls/ -name "*.jsonl" -exec head -1 {} \; | jq -e '.validator' && echo "✅ V-LOG-01: log na rota correta"
```

### Teste de Performance
```bash
# Arquivo de 5k linhas deve processar em <3000ms
time bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/unit-test-patterns/06-large-stress.sql.md >/dev/null 2>&1
# Esperado: real 0m1,XXXs (não minutos)
```

---

## 🔗 Referências e Links Relacionados

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Governança C4 | `[[01-RULES/harness-norms-v3.0.md#C4]]` | Definição oficial da constraint |
| Contrato V-INT | `[[05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md]]` | Normas internas para validadores |
| Matriz de Contexto | `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` | Exceções por pasta/domínio |
| Orchestrator | `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` | Consumidor do output JSON |
| Padrões Bash | `[[06-PROGRAMMING/bash/00-INDEX.md]]` | Biblioteca de referência para implementação |
| Fixtures de Teste | `[[06-PROGRAMMING/sql/unit-test-patterns/]]` | 8 artefatos para validação estática |

---

## 🌳 JSON Tree Final (para agents remotos e dashboard)

```json
{
  "artifact": "check-rls.sh",
  "version": "3.2.6",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/check-rls/README.md",
  "compliance": {
    "C4": true,
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
    "input": {"required": ["--file <path>", "--dir <path>"], "optional": ["--log-dir"]},
    "output": {
      "stdout": "JSON único com schema definido",
      "stderr": "Logs humanos de progresso/erros",
      "file": "JSONL em 08-LOGS/validation/test-orchestrator-engine/check-rls/"
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
    "log_path": "08-LOGS/validation/test-orchestrator-engine/check-rls/*.jsonl",
    "query_example": "find 08-LOGS/.../check-rls -name '*.jsonl' -exec cat {} \\; | jq -s 'group_by(.file) | map({file: .[0].file, last_status: .[-1].passed})'",
    "fields_indexed": ["file", "passed", "issues_count", "timestamp", "validator", "performance_ms"]
  }
}
```

---

> 💡 **Nota para a equipe**: Esta documentação segue o padrão SDD-COLLABORATIVE-GENERATION.md. Para atualizar, edite este arquivo e execute `bash 05-CONFIGURATIONS/validation/check-rls.sh --file docs/pt-BR/validation-tools/check-rls/README.md` para auto-validar a sintaxe.
