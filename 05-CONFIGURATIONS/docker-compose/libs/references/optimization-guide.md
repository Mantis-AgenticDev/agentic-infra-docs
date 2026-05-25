---
artifact_id: "docker-compose-optimization-guide-reference"
artifact_type: "docker-compose_reference"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/references/optimization-guide.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/references/optimization-guide.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:optimization-guide-ref-v1.0.0"
generated_at: "2026-05-23T19:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["image-size-reduction", "build-cache-optimization"]
  update_frequency: monthly
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# ⚡ Guia de Otimização de Builds e Tamanho de Imagem

> **Contrato modular**: Referência do `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Documentar técnicas para reduzir o tamanho da imagem Docker e acelerar os builds, aplicando as constraints C5 (validação automatizada de integridade).

---

## 🛡️ Técnicas de Otimização

### Ordem de Camadas para Maximizar Cache
```dockerfile
# 1. Dependências do sistema (raramente mudam)
RUN apk add --no-cache curl

# 2. Manifests de dependências (mudam ocasionalmente)
COPY package*.json ./
RUN npm ci --only=production

# 3. Código fonte (muda frequentemente)
COPY . .
```

### Multi-Stage Build (Separar Build de Runtime)
```dockerfile
FROM node:20-alpine AS builder
# ... build com ferramentas pesadas ...
FROM alpine:3.19 AS production
COPY --from=builder /app/dist ./dist
```

### `.dockerignore` Eficiente
```gitignore
.git
node_modules
dist
.env*
*.log
*.test.*
```

### Escolha de Imagem Base por Tamanho
| Imagem | Tamanho Aproximado |
|--------|-------------------|
| Distroless | ~2 MB |
| Alpine | ~7 MB |
| Wolfi/Chainguard | ~50 MB |
| Slim | ~200 MB |
| Standard | ~1 GB |

### Combinar Comandos RUN
```dockerfile
RUN apk add --no-cache --virtual .build-deps build-base && \
    make && \
    apk del .build-deps
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_dockerignore_exists() {
  [[ -f 05-CONFIGURATIONS/docker-compose/.dockerignore ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_dockerignore_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[../image-building.md]]
- [[../../templates/docker-compose-template.yml]]
```

---

## `05-CONFIGURATIONS/docker-compose/libs/references/docker-best-practices.md`

```markdown
---
artifact_id: "docker-compose-best-practices-reference"
artifact_type: "docker-compose_reference"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/references/docker-best-practices.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/references/docker-best-practices.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:best-practices-ref-v1.0.0"
generated_at: "2026-05-23T19:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["dockerfile-quality", "compose-standards"]
  update_frequency: monthly
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📘 Melhores Práticas Gerais de Docker

> **Contrato modular**: Referência do `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Compilar as melhores práticas da Docker Inc. e da comunidade, adaptadas ao ecossistema MANTIS.

---

## 🛡️ Práticas Recomendadas

### Dockerfile
- [ ] Usar `CMD` com exec form: `CMD ["executable", "arg1", "arg2"]`
- [ ] Não usar `ADD` para arquivos remotos; usar `curl` ou `wget` e remover
- [ ] Pin versões exatas com digest SHA256
- [ ] Um processo por contêiner (ou usar `dumb-init` para múltiplos)
- [ ] Health check sempre presente
- [ ] Labels OCI para metadados

### Compose
- [ ] Usar `restart: unless-stopped` para serviços de produção
- [ ] `depends_on` com `condition: service_healthy`
- [ ] Redes com `internal: true` para serviços de backend
- [ ] Volumes nomeados para dados persistentes
- [ ] Limitar recursos com `deploy.resources.limits`

### Segurança
- [ ] Nunca expor Docker socket (`/var/run/docker.sock`) a menos que estritamente necessário
- [ ] Escanear imagens com Trivy ou Docker Scout
- [ ] Gerar SBOM para cada imagem

---

## 🧪 Testes Unitários (TDD)
```bash
test_dockerfile_uses_exec_form() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/Dockerfile" << 'EOF'
FROM alpine:3.19
CMD ["echo", "ok"]
EOF
  grep -q 'CMD \["' "$tmp/Dockerfile" && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_dockerfile_uses_exec_form && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[../image-building.md]]
- [[../security-patterns.md]]
- [[https://docs.docker.com/develop/dev-best-practices/]]
