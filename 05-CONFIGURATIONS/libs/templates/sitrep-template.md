---
artifact_id: "configurations-sitrep-template"
artifact_type: "governance_template"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/templates/sitrep-template.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/templates/sitrep-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:sitrep-template-v1.0.0"
generated_at: "2026-05-24T09:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["weekly-reporting", "situation-report"]
  update_frequency: on-change
audience: ["configurations-ceo", "human-architects"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# SitRep: 05-CONFIGURATIONS — Semana YYYY-WW

> **Contrato modular**: Template filho de `configurations-ceo-mantis`. Referenciado por [[../project-management.md]] e [[../stakeholder-communication.md]].

**Período:** YYYY-MM-DD a YYYY-MM-DD  
**Estado geral:** 🟢 On Track / 🟡 At Risk / 🔴 Off Track  
**Próxima revisão:** YYYY-MM-DD

---

## 📊 Progresso

### ✅ Completado esta semana
- [Logro 1 com link para PR/commit]
- [Logro 2 com link para PR/commit]

### 🔄 Em progresso
- [Tarefa atual com % completado e bloqueio se aplicável]

### 🚧 Bloqueado
- [Bloqueador com causa raiz e ação corretiva]

---

## 📈 Métricas Chave

| Métrica | Valor atual | Target | Tendência |
|---------|-------------|--------|-----------|
| Workflows de CI exitosos | 95% | >90% | 📈 +2% |
| Tempo médio de despliegue | 4.2 min | <5 min | 📉 -0.3 min |
| Drift detectado | 0 recursos | 0 | ✅ Sem mudanças |
| Taxa de erros post-deploy | 0.3% | <1% | 📉 -0.1% |
| Cobertura de tests (promptfoo) | 87% | >85% | 📈 +3% |

---

## 🗓️ Próxima semana

### Prioridades
1. [Prioridade 1 do roadmap com link para tarefa]
2. [Prioridade 2 do roadmap com link para tarefa]

### Reuniões / Revisões programadas
- [Revisão de segurança: YYYY-MM-DD]
- [Sincronização com arquiteto: YYYY-MM-DD]

### Riscos identificados
- [Risco 1 com mitigação proposta]
- [Risco 2 com mitigação proposta]

---

## 📋 Decisões tomadas esta semana

| Decisão | Impacto | ADR / Link |
|----------|---------|------------|
| [Decisão 1] | [Alto/Médio/Baixo] | [ADR-XXX](link) |
