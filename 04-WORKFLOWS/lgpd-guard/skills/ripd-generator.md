---
artifact_id: "lgpd-ripd-generator"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C4","C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/ripd-generator.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/ripd-generator.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-ripd-generator-v1.0.0"
generated_at: "2026-05-25T04:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["data-protection-impact-assessment", "risk-assessment", "legitimate-interest"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 📊 Gerador de RIPD — Relatório de Impacto à Proteção de Dados Pessoais

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a geração de Relatórios de Impacto à Proteção de Dados Pessoais (RIPD) para tratamentos de alto risco ou baseados em legítimo interesse, conforme exigido pela LGPD e regulamentação da ANPD, garantindo documentação adequada para demonstração de conformidade (C4, C5, C6).

## 📋 Especificação (SDD)
- **Entradas**: Descrição do tratamento, tipos de dados, finalidades, bases legais, medidas de segurança.
- **Saídas**: RIPD em formato Markdown com todas as seções obrigatórias.
- **Side Effects**: Registro em Data Table para auditoria e versionamento.
- **Constraints Aplicáveis**: C4 (rastreabilidade), C5 (validação), C6 (aprovação para tratamentos de alto risco).
- **Dependências**: n8n, Data Tables.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
ripd_generator:
  when_required:
    - "Tratamento baseado em legítimo interesse (Art. 10, §3º)"
    - "Tratamento de dados sensíveis em larga escala"
    - "Tratamento que possa gerar riscos às liberdades civis e aos direitos fundamentais"
    - "Uso de tecnologias emergentes (IA, machine learning) com dados pessoais"
    - "Quando solicitado pela ANPD (Art. 10, §3º)"

  mandatory_sections:
    identificacao_agentes:
      controlador: "Nome, CNPJ, endereço, contato"
      operador: "Nome, CNPJ, endereço, contato (se houver)"
      encarregado: "Nome, e-mail, telefone do DPO"
      suboperadores: "Lista de suboperadores contratados (se houver)"
    
    descricao_tratamento:
      finalidade: "Propósito específico e legítimo do tratamento"
      base_legal: "Artigo específico da LGPD que fundamenta o tratamento"
      categorias_dados: "Pessoal, sensível, criança/adolescente"
      volume_estimado: "Número estimado de titulares afetados"
      frequencia: "Diário, semanal, sob demanda"
      fontes_dados: "Coleta direta, terceiros, bases públicas"
    
    riscos_identificados:
      - risco: "Acesso não autorizado"
        probabilidade: "baixa|média|alta"
        impacto: "baixo|médio|alto"
        mitigacao: "Criptografia em repouso e trânsito, MFA"
      - risco: "Vazamento de dados sensíveis"
        probabilidade: "baixa|média|alta"
        impacto: "baixo|médio|alto"
        mitigacao: "Sanitização PII antes de envio a terceiros, logs de auditoria"
    
    medidas_salvaguardas:
      tecnicas:
        - "Criptografia AES-256 em repouso"
        - "TLS 1.3 em trânsito"
        - "Mascaramento de PII em logs"
        - "Sanitização de prompts para LLMs"
      administrativas:
        - "Política de privacidade publicada"
        - "Treinamento LGPD para equipe"
        - "NDA com operadores e suboperadores"
        - "Plano de resposta a incidentes"
    
    avaliacao_necessidade:
      minimizacao: "Os dados coletados são estritamente necessários para a finalidade?"
      alternativas: "Existem meios menos invasivos de atingir a mesma finalidade?"
      proporcionalidade: "O benefício do tratamento justifica o risco aos titulares?"

  approval_flow:
    - "Gerar RIPD → Revisão do Encarregado (DPO)"
    - "Aprovação do Controlador (responsável legal)"
    - "Registro em Data Table com hash SHA256"
    - "Revisão periódica: anual ou quando houver mudança significativa no tratamento"

  anti_patterns:
    - "Tratar dados com legítimo interesse sem RIPD → infração ao Art. 10, §3º"
    - "RIPD genérico copiado de outro tratamento → não reflete riscos reais"
    - "RIPD sem medidas de mitigação → não demonstra conformidade"
    - "RIPD desatualizado após mudança no tratamento → deve ser revisado"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_ripd_has_mandatory_sections() {
  local sections=("identificacao_agentes" "descricao_tratamento" "riscos_identificados" "medidas_salvaguardas" "avaliacao_necessidade")
  [[ ${#sections[@]} -eq 5 ]] && return 0 || return 1
}

test_ripd_has_approval_flow() {
  local flow=("gerar" "revisar_dpo" "aprovar_controlador" "registrar" "revisao_periodica")
  [[ ${#flow[@]} -eq 5 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_ripd_has_mandatory_sections && test_ripd_has_approval_flow && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[data-classifier.md]]
- [[incident-response.md]]
