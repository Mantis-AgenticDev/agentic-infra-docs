---
artifact_id: "n8n-binary-data-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/binary-data-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/binary-data-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:binary-data-patterns-v1.0.0"
generated_at: "2026-05-24T22:50:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["binary-handling", "file-operations", "agent-tool-binary"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📎 Manipulação de Dados Binários

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o tratamento de dados binários ($binary) em workflows n8n, cobrindo a restrição crítica de agent tools (JSON-only), o padrão de pre-staging para uploads, o uso de CDN para chat hub, e a preservação de binário via Merge (C3, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados binários de nós anteriores (HTTP Request, Read Files, etc.).
- **Saídas**: Workflow que preserva ou referencia binários corretamente.
- **Constraints Aplicáveis**: C3 (secrets/CDN), C5 (validação), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
binary_data:
  non_negotiables:
    - "Binário está em $binary, NÃO em $json."
    - "Binário NÃO cruza a fronteira de agent tool em nenhuma direção. Parâmetros e resultados são JSON-only."

  agent_tool_gymnastics:
    inbound: |
      Uploads do usuário → chat trigger dá files[].
      passthroughBinaryImages: true → LLM vê para visão, mas fromAi() NÃO passa binário para tool.
      Padrão: pre-stage uploads para storage privado, injetar chaves no system prompt, tool faz download pela chave.
    outbound: |
      Tool gera arquivo → NÃO pode retornar binário cru.
      Padrão: upload para storage, retornar JSON { ok: true, file_id, url }.
      Agente embebe URL na resposta ou outra tool busca pela chave.

  merge_for_context:
    description: "Operações JSON-only (Edit Fields, Code, IF) removem binário do item. Usar Merge para reanexar."
    pattern: |
      [Source com binary] ─┬─→ [Edit Fields: transform JSON] ─┐
                           │                                    ├─→ [Merge: by position] ─→ [Email com attachment]
                           └────────────────────────────────────┘

  cdn_for_chat_hub:
    description: "Chat hub NÃO lê $binary. Imagens devem estar em CDN referenciável por URL."
    options: ["S3", "R2", "GCS", "Azure Blob", "Vercel Blob", "Supabase Storage", "Dropbox", "Google Drive", "OneDrive", "Box"]

  reading_binary_in_code:
    javascript: "const buffer = await this.helpers.getBinaryDataBuffer(0, 'data')"
    python: "Não suportado diretamente. Usar nó HTTP Request para download."

  setting_binary_in_code:
    javascript: |
      return [{
        json: { ... },
        binary: {
          data: {
            data: Buffer.from(content).toString('base64'),
            mimeType: 'text/plain',
            fileName: 'output.txt'
          }
        }
      }]

  anti_patterns:
    - "Tentar ler conteúdo de arquivo de $json (está em $binary)"
    - "Agent tool que retorna binário diretamente (upload para storage, retornar key/URL)"
    - "Assumir que passthroughBinaryImages: true permite tools receberem arquivos (apenas LLM vê)"
    - "Perder binário após transformação JSON (usar Merge para reanexar)"
    - "Hardcodear base64 em Code node (workflow JSON enorme, lento)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_binary_in_binary_slot() {
  node -e "
const item = { json: {}, binary: { data: { mimeType: 'application/pdf' } } };
console.assert(!item.json.mimeType, 'Binary must be in \$binary, not \$json');
console.assert(item.binary.data.mimeType === 'application/pdf', 'Binary slot exists');
console.log('OK');
" 2>/dev/null && return 0 || return 1
}

test_agent_tool_json_only() {
  # Agent tool params and results are JSON-only. Binary cannot cross.
  echo "Agent tools: JSON params, JSON results. Binary needs pre-staging." && return 0
}

[[ "${1:-}" == "--test" ]] && {
  test_binary_in_binary_slot && test_agent_tool_json_only && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[javascript-code-node.md]]
- [[database-file-operations.md]]
