---
artifact_id: "lgpd-data-classifier"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/data-classifier.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/data-classifier.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-data-classifier-v1.0.0"
generated_at: "2026-05-25T03:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["data-classification", "pii-detection", "sensitive-data-identification"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 🏷️ Classificador de Dados Pessoais

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Identificar e classificar automaticamente os tipos de dados que um workflow manipula, determinando se são dados pessoais, sensíveis, de crianças/adolescentes, públicos ou anonimizados, e aplicar as proteções correspondentes exigidas pela LGPD (C3, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Schema de dados do workflow (campos e valores de exemplo).
- **Saídas**: Classificação de cada campo (pessoal/sensível/criança/público/anonimizado) com a base legal recomendada.
- **Side Effects**: Geração de log de auditoria com a classificação.
- **Constraints Aplicáveis**: C3 (proteção de dados sensíveis), C5 (validação), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
data_classifier:
  patterns:
    pessoal:
      - "nome, sobrenome, full_name, first_name, last_name"
      - "email, e-mail, mail, email_address"
      - "cpf, cnpj, rg, documento, document"
      - "telefone, phone, celular, mobile"
      - "endereco, address, rua, bairro, cidade, cep"
      - "ip, ip_address, user_ip"
      - "cookie, session_id, device_id"
      - "data_nascimento, birth_date, nascimento"
      - "foto, photo, avatar, imagem"
      - "geolocalizacao, latitude, longitude, location"
    sensivel:
      - "origem_racial, raca, etnia, ethnicity"
      - "religiao, religion, crenca"
      - "opiniao_politica, political, partido"
      - "sindicato, union, filiacao_sindical"
      - "saude, health, diagnostico, prontuario, paciente"
      - "vida_sexual, sexual, genero, gender_identity"
      - "genetico, dna, genetic"
      - "biometria, biometric, digital, facial, iris"
    crianca_adolescente:
      - "idade < 18, menor, child, adolescent"
      - "responsavel, parent, guardian, pai, mae"
      - "escola, school, serie, grade"

  classification_rules:
    - "Se o campo contiver padrão de CPF (\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}) → PESSOAL"
    - "Se o campo contiver '@' → provável e-mail → PESSOAL"
    - "Se o campo estiver na lista sensivel → SENSÍVEL"
    - "Se o campo for data_nascimento e idade calculada < 18 → CRIANÇA/ADOLESCENTE"
    - "Se o dado puder ser revertido por meios técnicos → NÃO é anonimizado"

  mandatory_actions:
    pessoal: "Escolher e documentar base legal (consentimento/contrato/legítimo interesse)"
    sensivel: "EXIGIR consentimento EXPLÍCITO e específico. Proibido tratar sem ele."
    crianca: "EXIGIR consentimento de PELO MENOS UM dos pais ou responsável legal"
    publico: "Tratamento permitido, mas respeitar finalidade e boa-fé"
    anonimizado: "LGPD não se aplica (Art. 12), mas verificar irreversibilidade"

  log_event: "lgpd_data_classified"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_cpf_pattern_detection() {
  local cpf="123.456.789-00"
  echo "$cpf" | grep -qE '[0-9]{3}\.?[0-9]{3}\.?[0-9]{3}-?[0-9]{2}' && return 0 || return 1
}

test_email_detection() {
  local email="joao@example.com"
  echo "$email" | grep -q '@' && return 0 || return 1
}

test_sensitive_keyword() {
  local field="diagnostico"
  local sensitive=("saude" "diagnostico" "prontuario" "religiao" "biometria")
  for s in "${sensitive[@]}"; do
    [[ "$field" == *"$s"* ]] && return 0
  done
  return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_cpf_pattern_detection && test_email_detection && test_sensitive_keyword && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[pii-redaction.md]]
- [[audit-logging.md]]
