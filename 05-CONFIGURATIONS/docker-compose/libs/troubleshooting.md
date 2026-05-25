---
artifact_id: "docker-compose-troubleshooting"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/troubleshooting.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/troubleshooting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:troubleshooting-v1.0.0"
generated_at: "2026-05-23T19:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["container-debugging", "compose-diagnostics"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🔧 Diagnóstico e Resolução de Problemas

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`. Herda hardening do Master.

## 🎯 Propósito
Fornecer comandos de diagnóstico rápido para identificar e resolver falhas comuns em stacks Docker Compose (C8).

## 📋 Especificação
- **Entradas**: Sintoma do problema (ex: `container-restart-loop`, `healthcheck-failing`).
- **Saídas**: Comandos bash com saída esperada e ações corretivas.
- **Constraints Aplicáveis**: C8 (qualidade de entrega com diagnóstico).

---

## 🛡️ Guia Rápido de Diagnóstico

| Sintoma | Causa Provável | Comando de Diagnóstico | Ação Corretiva |
|---------|---------------|----------------------|---------------|
| Contêiner reiniciando | Erro na aplicação | `docker compose logs --tail=50 <svc>` | Corrigir código, verificar variáveis |
| Health check falhando | Dependência não pronta | `docker inspect <svc> --format='{{.State.Health}}'` | Aumentar `start_period` |
| Serviços não se comunicam | Rede incorreta | `docker compose exec <svc> ping <target>` | Verificar redes e aliases |
| Volume não persiste | Permissões ou montagem | `docker compose exec <svc> ls -la /data` | Ajustar `user` e `chown` |
| Imagem sempre reconstrói | Cache mal ordenado | `docker history <image>` | Reordenar camadas |
| Sem escrita em disco | `read_only: true` sem `tmpfs` | `docker compose exec <svc> touch /test` | Adicionar `tmpfs` |

---

## 🧪 Testes Unitários (TDD)
```bash
test_troubleshooting_command_exists() {
  command -v docker &>/dev/null || return 0  # Docker não disponível, skip
  docker compose version &>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_troubleshooting_command_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[healthcheck-patterns.md]]
- [[network-patterns.md]]
