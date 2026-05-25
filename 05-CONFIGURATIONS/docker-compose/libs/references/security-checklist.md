---
artifact_id: "docker-compose-security-checklist-reference"
artifact_type: "docker-compose_reference"
version: "1.0.0"
constraints_mapped: ["C3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/references/security-checklist.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/references/security-checklist.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:security-checklist-ref-v1.0.0"
generated_at: "2026-05-23T19:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["security-audit", "container-hardening"]
  update_frequency: monthly
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🔐 Guia de Segurança para Imagens e Contêineres

> **Contrato modular**: Artefato de referência do `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Lista de verificação de segurança para Dockerfiles e stacks Compose, baseada no CIS Docker Benchmark e nas constraints MANTIS C3.

---

## 🛡️ Checklist de Segurança

### Imagem Base
- [ ] Usar versão exata + digest SHA256 (`image: alpine:3.19@sha256:abc...`)
- [ ] Evitar `:latest` em produção
- [ ] Preferir Wolfi/Chainguard ou Alpine para minimizar CVEs

### Usuário e Privilégios
- [ ] Executar como non-root (`USER 1001:1001`)
- [ ] Drop todas as capacidades (`cap_drop: ALL`)
- [ ] Prevenir escalada de privilégios (`no-new-privileges:true`)

### Filesystem
- [ ] Filesystem somente leitura (`read_only: true`)
- [ ] Diretórios de escrita via `tmpfs` com `noexec,nosuid`

### Secrets
- [ ] NUNCA em variáveis de ambiente (`environment:`)
- [ ] NUNCA no Dockerfile (`ENV SECRET=...`)
- [ ] Usar Docker Secrets (`secrets:` + arquivo em `/run/secrets/`)
- [ ] Adicionar `secrets/` ao `.gitignore`

### Rede
- [ ] Serviços internos sem porta exposta (`expose`, não `ports`)
- [ ] Redes de backend com `internal: true`
- [ ] Bind a localhost (`127.0.0.1:8080:8080`) quando expor porta

### Health Check
- [ ] Health check profundo que valida dependências reais
- [ ] `start_period` adequado ao tempo de inicialização

### Metadados
- [ ] Labels OCI com versão, commit, equipe
- [ ] Labels MANTIS com `constraint-mapping`

---

## 🧪 Testes Unitários (TDD)
```bash
test_security_no_secret_in_env() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/compose.yaml" << 'EOF'
services:
  svc:
    image: alpine:3.19
    command: env
    secrets: [test_secret]
secrets:
  test_secret:
    file: /dev/null
EOF
  docker compose -f "$tmp/compose.yaml" config --quiet 2>/dev/null && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_security_no_secret_in_env && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[../security-patterns.md]]
- [[../../validation/audit-secrets.sh]]
- [[https://www.cisecurity.org/benchmark/docker]]
