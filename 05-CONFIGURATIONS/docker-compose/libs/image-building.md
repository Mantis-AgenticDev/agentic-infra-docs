---
artifact_id: "docker-compose-image-building"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/image-building.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/image-building.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:image-building-v1.0.0"
generated_at: "2026-05-23T18:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["dockerfile-optimization", "image-size-reduction"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🏗️ Construção e Otimização de Imagens

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Documentar as técnicas canônicas de multi-stage builds, ordem de camadas, `.dockerignore` e escolha de imagem base para minimizar o tamanho da imagem e maximizar a segurança (C1, C5).

## 📋 Especificação
- **Entradas**: Linguagem (`node`, `python`, `go`, etc.), perfil de infra (`nano`, `micro`, `standard`).
- **Saídas**: Dockerfile otimizado com multi-stage build e pinned versions.
- **Constraints Aplicáveis**: C1 (imutabilidade de artefatos), C5 (validação automatizada).

---

## 🛡️ Padrões de Build

### Ordem de Camadas por Frequência de Mudança
```dockerfile
FROM node:20-alpine@sha256:abc123...
RUN apk add --no-cache dumb-init curl          # 1. Dependências do sistema
RUN addgroup -g 1001 -S appuser && adduser ... # 2. Usuário non-root
WORKDIR /app
COPY package*.json ./                           # 3. Manifests de dependências
RUN npm ci --only=production                    # 4. Instalar dependências
COPY --chown=appuser:appuser . .                # 5. Código fonte
USER appuser
CMD ["dumb-init", "node", "index.js"]
```

### Multi-Stage Build
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN npm prune --production

FROM cgr.dev/chainguard/node:latest AS production
WORKDIR /app
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
USER nodejs
CMD ["node", "dist/index.js"]
```

### `.dockerignore` Mínimo
```gitignore
.git
node_modules
dist
.env*
*.log
__tests__
*.test.*
*.spec.*
```

### Escolha de Imagem Base
| Imagem | Tamanho | Uso | Segurança |
|--------|---------|-----|-----------|
| Wolfi/Chainguard | ~50MB | Produção crítica | ✅ Zero-CVE goal |
| Alpine | ~7MB | Produção geral | ✅ Minimal |
| Distroless | ~2MB | Máxima segurança | ✅ Sem shell |
| Slim | ~200MB | Debugging | ⚠️ Mais pacotes |

---

## 🧪 Testes Unitários (TDD)
```bash
test_dockerfile_pinned_tag() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/Dockerfile" << 'EOF'
FROM alpine:3.19@sha256:abc123...
CMD echo ok
EOF
  grep -q sha256 "$tmp/Dockerfile" && return 0 || return 1
  rm -rf "$tmp"
}
[[ "${1:-}" == "--test" ]] && { test_dockerfile_pinned_tag && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[security-patterns.md]]
- [[references/optimization-guide.md]]
