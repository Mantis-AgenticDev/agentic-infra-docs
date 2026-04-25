---
canonical_path: "docs/pt-BR/validation-tools/audit-secrets/README.md"
artifact_id: "audit-secrets-ptbr-docs-v3.1.0"
constraints_mapped: "C3,V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05,V-LOG-01,V-LOG-02"
validation_command: "bash 05-CONFIGURATIONS/validation/audit-secrets.sh --help"
tier: 3
---

# 🕵️ audit-secrets.sh – Auditor de Zero Hardcode (Constraint C3)

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Desenvolvedores e especialistas em SecOps  
> **Versão do validador**: v3.1.0-CONTRACTUAL  
> **Última atualização**: 2026-04-25

---

## 🎯 Propósito

Este script varre agressivamente o código para garantir o cumprimento da **Constraint C3 (Zero Hardcode)**, assegurando que nenhuma credencial, token ou chave de API seja consolidada no repositório.

### Padrões Detectados:
| Categoria | Assinatura Regex (Simplificada) | Severidade |
|-----------|--------------------------------|------------|
| `AWS_KEY` | `AKIA[0-9A-Z]{16}` | 🔴 CRITICAL |
| `JWT_TOKEN` | `eyJ[a-zA-Z0-9_-]+\.eyJ` | 🔴 CRITICAL |
| `GENERIC_SECRET` | `(password\|secret\|key)[ \t]*[=:][ \t]*['"][a-zA-Z0-9]{8,}['"]` | 🟡 HIGH |
| `PRIVATE_KEY` | `BEGIN RSA PRIVATE KEY` | 🔴 CRITICAL |

### Padrões Ignorados (Safe-list):
O validador é inteligente o suficiente para ignorar placeholders comuns utilizados em documentações, como:
- Valores contendo: `changeme`, `your-`, `xxxx`, `REDACTED`, `example_`
- Referências a variáveis de ambiente (`${API_KEY}`).

---

## 🔧 Implementação Técnica

O script utiliza expressões regulares nativas do `bash` para alcançar tempos de execução sub-milissegundo, evitando a criação massiva de instâncias de sub-shells como `grep` ou `sed` durante a análise de strings em memória.

### Formato de Log JSONL Diário
De acordo com o protocolo **V-LOG-01**, o script não retém histórico infinito fragmentado; ele concatena suas saídas no arquivo `/home/ricardo/proyectos/agentic-infra-docs-testing/08-LOGS/validation/test-orchestrator-engine/audit-secrets/YYYY-MM-DD.jsonl`.

---

## 🚀 Como Usar

```bash
# Validar um script Python
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --file 06-PROGRAMMING/python/conexao-db.py

# A saída JSON informará se existem segredos vazados no atributo `issues`.
```

---

## 🔗 Referências

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Governança C3 | `[[01-RULES/harness-norms-v3.0.md#C3]]` | Definição da norma de Zero Hardcode |

---

## 🌳 JSON Tree Final

```json
{
  "artifact": "audit-secrets.sh",
  "version": "3.1.0",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/audit-secrets/README.md",
  "compliance": {
    "C3": true,
    "V-INT-01": true,
    "V-LOG-01": true
  }
}
```
