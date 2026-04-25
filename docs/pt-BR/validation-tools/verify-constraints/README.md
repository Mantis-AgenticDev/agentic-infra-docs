---
canonical_path: "docs/pt-BR/validation-tools/verify-constraints/README.md"
artifact_id: "verify-constraints-ptbr-docs-v3.0"
constraints_mapped: "C1,C2,C3,C4,C5,C6,C7,C8,V-INT-01,V-INT-02,V-LOG-01"
validation_command: "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --help"
tier: 3
---

# ⚖️ verify-constraints.sh – Validador de Conformidade MANTIS (C1-C8)

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Arquitetos e engenheiros de qualidade MANTIS  
> **Versão do validador**: v3.0.0-SELECTIVE-CONTRACTUAL  
> **Última atualização**: 2026-04-25

---

## 🎯 Propósito

O `verify-constraints.sh` atua como o **validador transversal** da plataforma MANTIS. Em vez de se focar em um único problema (como vazamento de senhas), este artefato garante que o código cumpra holisticamente as normas operacionais (C1 a C8) e respeite os limites do **Language Lock Protocol** e regras vetoriais de `pgvector` (V1-V3).

### O que ele verifica:
| Constraint | Escopo Focado |
|------------|---------------|
| **C1-C2** | Detecção de limites de recursos (memória, CPU) e Timeouts assíncronos. |
| **C4** | Isolamento de tenants. |
| **C8** | **Structured Logging**: Detecção do uso indevido de `print` ou `console.log` em favor de JSON a `stderr`. |
| **LANGUAGE LOCK** | Garante que operadores como `<->` de `pgvector` **não** vazem para a pasta `/sql` pura. |
| **Examples Count** | Exige no mínimo 10 exemplos práticos para scripts comuns, e 25 para `skill_pgvector`. |

---

## 🔧 Implementação Técnica

Após o Post-Mortem V3, este script foi destituído da sua posição original de "Orquestrador". Ele agora opera de forma 100% atômica, ingerindo um único `--file` por execução e reportando via JSON para stdout. O cálculo do `SCORE` interno (0 a 100) é embutido na saída e afeta a taxonomia booleana `passed: true/false`.

---

## 🚀 Como Usar

```bash
# Validar um arquivo
bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/python/agente.py

# A saída conterá o "score" final no JSON.
```

---

## 🔗 Referências

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Regras Base | `[[01-RULES/harness-norms-v3.0.md]]` | Definição das normas C1-C8 e V1-V3 |

---

## 🌳 JSON Tree Final

```json
{
  "artifact": "verify-constraints.sh",
  "version": "3.0.0",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/verify-constraints/README.md",
  "compliance": {
    "C1_C8": true,
    "LANGUAGE_LOCK": true
  }
}
```
