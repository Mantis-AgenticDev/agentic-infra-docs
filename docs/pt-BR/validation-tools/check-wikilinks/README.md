---
canonical_path: "docs/pt-BR/validation-tools/check-wikilinks/README.md"
artifact_id: "check-wikilinks-ptbr-docs-v3.0"
constraints_mapped: "V-INT-01,V-INT-02,V-LOG-01"
validation_command: "bash 05-CONFIGURATIONS/validation/check-wikilinks.sh --help"
tier: 3
---

# 🔗 check-wikilinks.sh – Auditor de Trazabilidade (WikiLinks)

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Autores de Documentação Técnica e Mantenedores MANTIS  
> **Versão do validador**: v3.0-CONTRACTUAL  
> **Última atualização**: 2026-04-25

---

## 🎯 Propósito

No ecossistema MANTIS, os arquivos Markdown são como nós de um grafo de conhecimento interconectado. Em vez de usar hiperlinks relativos em markdown tradicional `[Link](ruta)`, os agentes dependem estritamente da notação **WikiLink** `[[ruta/canonica.md]]`. 

Este script assegura que:
- Nenhum link aponte para o vazio (404 Not Found interno).
- Não existam caminhos relativos ambíguos. Todos os caminhos dentro dos WikiLinks devem ser **absolutos a partir da raiz do repositório** (Ex: `[[01-RULES/harness-norms-v3.0.md]]`).

---

## 🔧 Implementação Técnica

Convertido integralmente do modo batch para o modo estrito Single-File (`--file`), o validador utiliza extração massiva via `grep -oP` ou nativamente via bash regex para capturar todas as ocorrências de `[[ ... ]]`.
Cada link encontrado é fisicamente verificado via `[[ -f "$link_extraido" ]]`. Se o link estiver quebrado, o script relata exatamente em que linha o erro ocorreu. 

---

## 🚀 Como Usar

```bash
# Validar enlaces de um arquivo específico
bash 05-CONFIGURATIONS/validation/check-wikilinks.sh --file 06-PROGRAMMING/python/agente.py.md
```

---

## 🔗 Referências

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Architecture Rules | `[[01-RULES/architecture-rules.md]]` | Detalhamento sobre a importância da malha de grafos e navegação semântica |

---

## 🌳 JSON Tree Final

```json
{
  "artifact": "check-wikilinks.sh",
  "version": "3.0.0",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/check-wikilinks/README.md"
}
```
