---
canonical_path: "docs/pt-BR/validation-tools/validate-frontmatter/README.md"
artifact_id: "validate-frontmatter-ptbr-docs-v3.0"
constraints_mapped: "V-INT-01,V-INT-02,V-LOG-01"
validation_command: "bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh --help"
tier: 3
---

# 📑 validate-frontmatter.sh – Auditor de Metadados YAML

> **Idioma**: Português do Brasil 🇧🇷  
> **Público-alvo**: Autores de Documentação e Mantenedores MANTIS  
> **Versão do validador**: v3.0-CONTRACTUAL  
> **Última atualização**: 2026-04-25

---

## 🎯 Propósito

Este validador garante que **todo arquivo Markdown** no ecossistema MANTIS possua um cabeçalho (Frontmatter) YAML válido, garantindo rastreabilidade e integração com os agentes de inteligência artificial.

### Critérios Obrigatórios Detectados:
1. `canonical_path`: O caminho absoluto lógico do artefato. Deve bater com sua localização no repositório.
2. `artifact_id`: O identificador exclusivo textual do arquivo.
3. `constraints_mapped`: A declaração explícita de quais normas (Ex: `C3, C4`) o arquivo cumpre ou documenta.
4. `validation_command`: O comando shell que a IA deve invocar para provar o status de sucesso do script.
5. `tier`: O nível arquitetônico (1, 2 ou 3).

---

## 🔧 Implementação Técnica

Em vez de utilizar uma dependência pesada de Ruby ou Python para parseamento YAML, este validador se apoia no utilitário de texto nativo `awk` para demarcar o bloco YAML entre as linhas `---`. Isso garante uma validação ultrarrápida (<50ms). Os logs resultantes são canalizados diariamente para a pasta JSONL persistente sob `08-LOGS`.

---

## 🚀 Como Usar

```bash
# Validar cabeçalho
bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh --file 06-PROGRAMMING/bash/00-INDEX.md
```

---

## 🔗 Referências

| Documento | Link Canônico | Propósito |
|-----------|--------------|-----------|
| Estrutura de Documentos | `[[SDD-COLLABORATIVE-GENERATION.md]]` | Padrões de escrita em Markdown e metadados requeridos |

---

## 🌳 JSON Tree Final

```json
{
  "artifact": "validate-frontmatter.sh",
  "version": "3.0.0",
  "language_docs": "pt-BR",
  "canonical_path": "docs/pt-BR/validation-tools/validate-frontmatter/README.md"
}
```
