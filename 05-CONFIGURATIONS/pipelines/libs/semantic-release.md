---
artifact_id: "pipelines-semantic-release"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C4"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/semantic-release.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/semantic-release.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:semantic-release-v1.0.0"
generated_at: "2026-05-23T23:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["version-management", "changelog-generation"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📦 Versionado Semântico e Releases

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Automatizar versionado semântico, geração de changelog e convenções de commit para manter imutabilidade (C1) e rastreabilidade (C4).

## 📋 Especificação
- **Entradas**: Commits formatados.
- **Saídas**: Tag de versão, release notes, changelog.
- **Constraints Aplicáveis**: C1, C4.

---

## 🛡️ Configuração

```json
// .releaserc.json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/github"
  ]
}
```

### Convenção de Commits
| Tipo | Efeito |
|------|--------|
| `feat:` | Minor ↑ |
| `fix:` | Patch ↑ |
| `feat!:` ou `BREAKING CHANGE:` | Major ↑ |
| `chore:`, `docs:` | Sem versão |

---

## 🧪 Testes Unitários (TDD)
```bash
test_commit_format() {
  echo "feat: add new pipeline" | grep -qE "^(feat|fix|chore|docs)(\(.+\))?!?: .+" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_commit_format && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
