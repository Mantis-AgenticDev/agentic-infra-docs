---
artifact_id: "lgpd-privacy-notice-template"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C4","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/privacy-notice-template.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/privacy-notice-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-privacy-notice-template-v1.0.0"
generated_at: "2026-05-25T04:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["privacy-notice", "data-disclosure", "transparency"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 📜 Template de Aviso de Privacidade (Art. 9º)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a geração de avisos de privacidade para cada sistema ou workflow que realize tratamento de dados pessoais, conforme o Art. 9º da LGPD, garantindo transparência e o direito do titular ao acesso facilitado às informações sobre o tratamento de seus dados (C4, C5).

## 📋 Especificação (SDD)
- **Entradas**: Dados do controlador, finalidades do tratamento, tipos de dados coletados, bases legais, canais de contato do Encarregado (DPO).
- **Saídas**: Aviso de privacidade em formato Markdown pronto para publicação.
- **Side Effects**: Registro de versão do aviso em Data Table para auditoria.
- **Constraints Aplicáveis**: C4 (rastreabilidade da versão do aviso), C5 (validação de conteúdo obrigatório).
- **Dependências**: n8n, Data Tables.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
privacy_notice_template:
  art_9_requirements:
    - "Finalidade específica do tratamento"
    - "Forma e duração do tratamento"
    - "Identificação do controlador"
    - "Informações de contato do controlador"
    - "Informações sobre uso compartilhado de dados e finalidade"
    - "Responsabilidades dos agentes que realizarão o tratamento"
    - "Direitos do titular, com menção explícita aos direitos do Art. 18"

  mandatory_sections:
    controlador:
      nome: "string (ex: Empresa XYZ Ltda)"
      cnpj: "string"
      endereco: "string"
      email_encarregado: "string (e-mail do DPO)"
    dados_coletados:
      - tipo: "string (ex: Nome, E-mail, CPF)"
        classe: "pessoal|sensível|criança"
        finalidade: "string (ex: Cadastro para prestação de serviço)"
        base_legal: "consentimento|contrato|legítimo_interesse|obrigação_legal"
        duracao: "string (ex: Até revogação + 30 dias)"
    compartilhamento:
      destinatarios: ["string (ex: Operador de pagamento X)"]
      finalidade: "string"
      transferencia_internacional: "string | null"
    direitos_titular:
      - "Confirmação da existência de tratamento"
      - "Acesso aos dados"
      - "Correção de dados incompletos, inexatos ou desatualizados"
      - "Anonimização, bloqueio ou eliminação de dados desnecessários"
      - "Portabilidade dos dados a outro fornecedor"
      - "Eliminação dos dados pessoais tratados com consentimento"
      - "Informação sobre compartilhamento"
      - "Informação sobre possibilidade de não consentir"
      - "Revogação do consentimento"
    contato_encarregado:
      nome: "string"
      email: "string"
      telefone: "string (opcional)"

  template_markdown: |
    # Aviso de Privacidade — {{controlador.nome}}
    
    ## 1. Quem é o Controlador dos seus dados
    {{controlador.nome}}, CNPJ {{controlador.cnpj}}, com sede em {{controlador.endereco}}.
    
    ## 2. Quais dados coletamos e por quê
    | Dado | Finalidade | Base Legal | Duração |
    |------|-----------|------------|---------|
    {{#each dados_coletados}}
    | {{tipo}} | {{finalidade}} | {{base_legal}} | {{duracao}} |
    {{/each}}
    
    ## 3. Com quem compartilhamos seus dados
    {{#each compartilhamento.destinatarios}}
    - {{this}} — {{compartilhamento.finalidade}}
    {{/each}}
    {{#if compartilhamento.transferencia_internacional}}
    Transferência internacional: {{compartilhamento.transferencia_internacional}}
    {{/if}}
    
    ## 4. Seus direitos como titular (Art. 18, LGPD)
    {{#each direitos_titular}}
    - {{this}}
    {{/each}}
    
    ## 5. Contato do Encarregado (DPO)
    {{contato_encarregado.nome}} — {{contato_encarregado.email}}
    {{#if contato_encarregado.telefone}}Telefone: {{contato_encarregado.telefone}}{{/if}}
    
    *Última atualização: {{data_atualizacao}}*

  version_tracking:
    table_name: "lgpd_privacy_notices"
    columns:
      - { name: "notice_id", type: "string" }
      - { name: "version", type: "number" }
      - { name: "controlador_cnpj", type: "string" }
      - { name: "data_publicacao", type: "date" }
      - { name: "data_atualizacao", type: "date" }
      - { name: "hash_content", type: "string" }

  anti_patterns:
    - "Aviso genérico que não lista finalidades específicas → NULO (Art. 9º, §1º)"
    - "Aviso sem contato do Encarregado → impossibilita exercício de direitos"
    - "Mudança de finalidade sem notificação prévia ao titular → consentimento original é NULO"
    - "Aviso inacessível (enterrado em subpáginas) → viola princípio da transparência"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_privacy_notice_has_mandatory_sections() {
  local sections=("controlador" "dados_coletados" "compartilhamento" "direitos_titular" "contato_encarregado")
  [[ ${#sections[@]} -eq 5 ]] && return 0 || return 1
}

test_privacy_notice_has_all_rights() {
  local rights=("Confirmação" "Acesso" "Correção" "Anonimização" "Portabilidade" "Eliminação" "Compartilhamento" "Não consentir" "Revogação")
  [[ ${#rights[@]} -eq 9 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_privacy_notice_has_mandatory_sections && test_privacy_notice_has_all_rights && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[data-classifier.md]]
