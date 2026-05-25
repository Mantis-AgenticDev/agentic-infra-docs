---
artifact_id: "configurations-roadmap-template"
artifact_type: "governance_template"
version: "1.0.0"
constraints_mapped: ["C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/templates/roadmap-template.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/templates/roadmap-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:roadmap-template-v1.0.0"
generated_at: "2026-05-24T09:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["roadmap-planning", "quarterly-planning"]
  update_frequency: quarterly
audience: ["configurations-ceo", "human-architects"]
status: "🟢 Novo"
next_review: "2026-09-24"
---

# Roadmap QY 2026 — "Tema do Trimestre"

> **Contrato modular**: Template filho de `configurations-ceo-mantis`. Referenciado por [[../project-management.md]].

**Período:** Mês inicial – Mês final YYYY  
**Responsável:** configurations-ceo  
**Revisão:** YYYY-MM-DD

---

## Objetivos do Trimestre
1. [Objetivo estratégico 1]
2. [Objetivo estratégico 2]

---

## Iniciativas

### 🔴 Alta Prioridade
- [ ] Tarefa 1: [Descrição] (Agente: [nome], Score RICE: [valor])
- [ ] Tarefa 2: [Descrição] (Agente: [nome], Score RICE: [valor])

### 🟡 Média Prioridade
- [ ] Tarefa 3: [Descrição] (Agente: [nome], Score RICE: [valor])

### 🟢 Baixa Prioridade
- [ ] Tarefa 4: [Descrição] (Agente: [nome], Score RICE: [valor])

---

## Marcos (Milestones)
| Data | Marco | Critério de Sucesso |
|------|-------|---------------------|
| YYYY-MM-DD | [Nome do marco] | [Descrição mensurável] |

---

## Riscos e Mitigações
| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| [Descrição] | Alta/Média/Baixa | Alto/Médio/Baixo | [Ação] |

---

## Dependências Externas
- [Dependência 1: agente/time/equipe externa]
- [Dependência 2: recurso/ferramenta/serviço]
