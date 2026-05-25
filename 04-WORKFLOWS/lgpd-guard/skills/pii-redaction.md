---
artifact_id: "lgpd-pii-redaction"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/pii-redaction.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/pii-redaction.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-pii-redaction-v1.0.0"
generated_at: "2026-05-25T04:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["pii-sanitization", "llm-privacy", "data-masking"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 🔒 Sanitização de PII (Redação de Dados Pessoais)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a sanitização de dados pessoais identificáveis (PII) antes de serem enviados para serviços externos, especialmente LLMs e APIs de terceiros, garantindo que informações como nome, CPF, e-mail, telefone e endereço não sejam expostas fora do ambiente controlado (C3, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Texto ou JSON contendo dados potencialmente pessoais.
- **Saídas**: Texto sanitizado com PII substituído por tokens reversíveis (ex.: `<PESSOA_1>`, `<EMAIL_1>`).
- **Side Effects**: Armazenamento do mapeamento de tokens em Data Table local para reversão posterior.
- **Constraints Aplicáveis**: C3 (proteção de dados), C5 (validação), C8 (logging).
- **Dependências**: n8n Code node (JavaScript/Python), Data Tables.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
pii_redaction:
  patterns:
    cpf: '\d{3}\.?\d{3}\.?\d{3}-?\d{2}'
    cnpj: '\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2}'
    email: '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    phone: '\(?\d{2}\)?\s?\d{4,5}-?\d{4}'
    celular: '\(?\d{2}\)?\s?9\d{4}-?\d{4}'
    cep: '\d{5}-?\d{3}'
    rg: '\d{1,2}\.?\d{3}\.?\d{3}-?[0-9Xx]'
    nome_completo: 'Padrão contextual: duas ou mais palavras iniciando com maiúscula em sequência'
    endereco: 'Rua|Avenida|Av\.|Praça|Travessa|Alameda|Rodovia|Estrada seguido de número'
    ip: '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

  replacement_strategy:
    tokenization: "Substituir PII por tokens reversíveis: <PESSOA_N>, <EMAIL_N>, <CPF_N>, <TELEFONE_N>"
    mapping_storage: "Data Table `lgpd_pii_tokens` com {token, valor_real_hash, workflow_id, timestamp}"
    irreversible: "Para dados que nunca precisam ser revertidos, usar hash SHA256 + salt"

  llm_specific:
    prompt_sanitization: "Sanitizar TODO o prompt antes de enviar para LLM externo"
    response_desanitization: "Reverter tokens na resposta do LLM antes de entregar ao usuário"
    never_send: ["CPF", "RG", "cartão de crédito", "dados de saúde", "biometria"]

  code_example_javascript: |
    const text = $input.first().json.text;
    const piiMap = {};
    let counter = 1;

    // Redact CPF
    text = text.replace(/\d{3}\.?\d{3}\.?\d{3}-?\d{2}/g, (match) => {
      const token = `<CPF_${counter}>`;
      piiMap[token] = match;
      counter++;
      return token;
    });

    // Redact email
    text = text.replace(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, (match) => {
      const token = `<EMAIL_${counter}>`;
      piiMap[token] = match;
      counter++;
      return token;
    });

    return [{ json: { sanitized: text, pii_map: piiMap } }];

  code_example_python: |
    import re
    text = _input.first()['json']['text']
    pii_map = {}
    counter = 1

    # Redact CPF
    def replace_cpf(match):
        global counter
        token = f'<CPF_{counter}>'
        pii_map[token] = match.group(0)
        counter += 1
        return token

    text = re.sub(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}', replace_cpf, text)

    return [{'json': {'sanitized': text, 'pii_map': pii_map}}]

  anti_patterns:
    - "Enviar prompt bruto para LLM sem sanitização → exposição de PII a terceiros"
    - "Esquecer de reverter tokens na resposta → resposta ilegível"
    - "Sanitizar apenas campos óbvios e esquecer dados em metadados (headers, URLs)"
    - "Armazenar mapeamento de tokens em texto plano → se vazar, PII é recuperável"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_cpf_redaction() {
  local text="Meu CPF é 123.456.789-00"
  local sanitized=$(echo "$text" | sed -E 's/[0-9]{3}\.?[0-9]{3}\.?[0-9]{3}-?[0-9]{2}/<CPF_REDACTED>/g')
  echo "$sanitized" | grep -q "CPF_REDACTED" && echo "$sanitized" | grep -qv "123.456.789" && return 0 || return 1
}

test_email_redaction() {
  local text="Contato: joao@example.com"
  local sanitized=$(echo "$text" | sed -E 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/<EMAIL_REDACTED>/g')
  echo "$sanitized" | grep -q "EMAIL_REDACTED" && echo "$sanitized" | grep -qv "joao@example" && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_cpf_redaction && test_email_redaction && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[data-classifier.md]]
- [[audit-logging.md]]
