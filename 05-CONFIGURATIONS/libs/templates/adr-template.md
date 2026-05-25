---
artifact_id: "configurations-adr-template"
artifact_type: "governance_template"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/templates/adr-template.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/templates/adr-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:adr-template-v1.0.0"
generated_at: "2026-05-24T09:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["architecture-decision-records", "decision-documentation"]
  update_frequency: on-change
audience: ["configurations-ceo", "human-architects"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📋 ADR-XXX: Título da Decisão

> **Contrato modular**: Template filho de `configurations-ceo-mantis`. Referenciado por [[../project-management.md]].

**Estado:** Propuesto / Aceptado / Reemplazado / Obsoleto  
**Data:** YYYY-MM-DD  
**Decisor:** configurations-ceo (MANTIS)  
**Stakeholders afetados:** [lista de agentes e humanos]

## Contexto
Descrição do problema ou situação que motiva a decisão. Incluir:
- Requisitos técnicos ou de negócio
- Restrições conhecidas (orçamento, tempo, compliance)
- Alternativas consideradas inicialmente

## Decisão
A decisão tomada, expressa em uma ou duas frases claras e acionáveis.

## Consequências
### Positivas
- [Vantagem 1]
- [Vantagem 2]

### Negativas / Trade-offs aceitos
- [Desvantagem 1]
- [Custo adicional, complexidade, etc.]

## Alternativas consideradas
| Alternativa | Pros | Contras | Por que foi descartada |
|-------------|------|---------|------------------------|
| [Nome] | [Vantagens] | [Desvantagens] | [Razão principal] |
| [Nome] | [Vantagens] | [Desvantagens] | [Razão principal] |

## Implementação
- [ ] Tarefa 1: [Descrição] (Agente responsável: [nome])
- [ ] Tarefa 2: [Descrição] (Agente responsável: [nome])

## Revisão
Próxima revisão programada: YYYY-MM-DD  
Critérios de re-avaliação: [condições que disparariam uma revisão]
