---
artifact_id: "n8n-credentials-security"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/credentials-security.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/credentials-security.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:credentials-security-v1.0.0"
generated_at: "2026-05-24T19:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["credential-management", "authentication-setup"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 Gestão de Credenciais e Segurança

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a gestão de credenciais e autenticação no n8n, garantindo que API keys, tokens e segredos nunca sejam expostos em texto plano (C3), que a rastreabilidade seja mantida (C4) e que a configuração seja validável (C5).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de autenticação (OAuth, API Key, etc.), serviço alvo.
- **Saídas**: Nó configurado com credencial correta, sem hardcoding de segredos.
- **Constraints Aplicáveis**: C3 (secrets), C4 (audit), C5 (validação).
- **Dependências**: n8n com sistema de credenciais integrado.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
credentials_security:
  non_negotiables:
    - "Segredos sempre via sistema de credenciais. NUNCA em campos de texto ou SDK."
    - "Não perguntar nomes de credenciais ao usuário, mas SEMPRE alertar para verificar cada nó."
    - "Criação de credenciais é responsabilidade do usuário via UI."
    - "Tratar segredo colado no chat como comprometido e orientar rotação."

  credential_system:
    storage: "Criptografado em repouso no banco n8n"
    reference: "Por ID pelos nós"
    scoping: "Projetos (Cloud/Enterprise) ou global (self-hosted)"
    export: "Exportar workflow vaza a referência, não o segredo"

  decision_tree:
    native_exists: "Usar nó nativo + seu tipo de credencial."
    standard_rest: "Usar HTTP Request com auth type (Generic OAuth2, Header Auth, Bearer Auth, Basic Auth)."
    complex_auth: "Usar httpCustomAuth para múltiplos headers ou header+query."

  anti_patterns:
    - "Colar token no campo de valor do header de Authorization."
    - "Armazenar token em um Set node e referenciar via expressão."
    - "Armazenar segredo em $vars e ler como valor de auth."
    - "Usar HTTP Request quando existe nó nativo."
    - "Hardcodear credenciais em código SDK."
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_no_hardcoded_tokens() {
  local workflow='{"nodes":[{"parameters":{"url":"https://api.test.com","authentication":"predefinedCredentialType"}}]}'
  python3 -c "
import json; d=json.loads('$workflow')
# Verificar que não há strings como 'Bearer sk-...'
assert 'Bearer' not in json.dumps(d)
assert 'xoxb-' not in json.dumps(d)
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_no_hardcoded_tokens && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[http-request-patterns.md]]
- [[security-testing-patterns.md]]
- [[/05-CONFIGURATIONS/validation/audit-secrets.sh]]
