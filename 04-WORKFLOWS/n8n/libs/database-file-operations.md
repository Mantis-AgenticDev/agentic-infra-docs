---
artifact_id: "n8n-database-file-operations"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/database-file-operations.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/database-file-operations.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:database-file-operations-v1.0.0"
generated_at: "2026-05-24T16:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["database-queries", "file-operations", "data-persistence"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗄️ Operações com Banco de Dados e Arquivos

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar operações com bancos de dados (PostgreSQL, MongoDB, MySQL) e arquivos (S3, FTP, Google Drive) em workflows n8n, garantindo segurança (C3), rastreabilidade de tenant (C4), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de operação (query, insert, upload, download), fonte de dados.
- **Saídas**: Dados consultados ou confirmação de operação.
- **Constraints Aplicáveis**: C3 (credenciais seguras), C4 (tenant isolation), C5 (validação), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
database_operations:
  postgresql:
    query_with_params: |
      SELECT * FROM users
      WHERE created_at > $1 AND status = $2
      ORDER BY created_at DESC
    parameters: ["{{ $json.startDate }}", "active"]

  batch_insert:
    description: "Inserção em lote via Code node"
    code_snippet: |
      const items = $input.all();
      const values = items.map(item => ({
        name: item.json.name,
        email: item.json.email,
        created_at: new Date().toISOString()
      }));
      return [{ json: { values } }];
    sql: "INSERT INTO users (name, email, created_at) VALUES {{ $json.values }}"

  file_operations:
    upload_s3:
      workflow: "File Trigger → S3 Upload"
      s3_config:
        operation: "Upload"
        bucket: "my-bucket"
        fileName: "={{ $json.fileName }}"
        binaryData: true
    download_process:
      workflow: "HTTP Request (download) → Code (process) → Google Drive (upload)"
      steps:
        - "HTTP Request: Binary response enabled"
        - "Code: Process $binary.data"
        - "Google Drive: Upload with binary data"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_query_has_tenant_filter() {
  local query="SELECT * FROM users WHERE tenant_id = $1 AND status = 'active'"
  echo "$query" | grep -q "tenant_id" && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_query_has_tenant_filter && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[api-integration-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
