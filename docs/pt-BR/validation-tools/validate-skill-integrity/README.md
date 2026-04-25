---
canonical_path: "docs/pt-BR/validation-tools/validate-skill-integrity/README.md"
artifact_id: "validate-skill-integrity-ptbr-docs-v3.0"
constraints_mapped: "V-INT-01,V-INT-02,V-LOG-01"
validation_command: "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --help"
tier: 3
---

# 🤖 validate-skill-integrity.sh – Auditor de Integridade de Skills

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Engenheiros de IA e Desenvolvedores de Agentes  
> **Versão do validador**: v3.0-CONTRACTUAL  
> **Última atualização**: 2026-04-25

---

## 🎯 Propósito

As **Skills** são as funções atômicas em Markdown executadas pelos subagentes autônomos. Este validador garante que a sintaxe, a tipagem estrita de argumentos e as saídas das _skills_ estejam em estrita conformidade com os motores de invocação subjacentes (como LangChain ou MANTIS Orchestrator). 

### O que ele verifica:
- A existência e formatação do bloco de código descritivo (`# SKILL_DEFINITION`).
- A aderência da skill a assinaturas de método conhecidas no repositório.
- A ausência de lógicas recursivas mal formadas que possam levar os agentes a "loops" infinitos.

---

## 🔧 Implementação Técnica

Foi removido o antigo "scope creep" que tentava validar Wikilinks ou Pgvector, delegando isso aos seus respectivos validadores canônicos. Atualmente, este artefato foca exclusivamente no escaneamento de semântica de IA utilizando expressões regulares limpas e produzindo logs no formato padrão `V-INT-01`.

---

## 🚀 Como Usar

```bash
# Validar uma Skill do repositório
bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file 02-SKILLS/AI/minha-skill.md
```

---

## 🔗 Referências

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Definição de Skills | `[[02-SKILLS/README.md]]` | Padrões oficiais de elaboração de Skills |

---

## 🌳 JSON Tree Final

```json
{
  "artifact": "validate-skill-integrity.sh",
  "version": "3.0.0",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/validate-skill-integrity/README.md"
}
```
