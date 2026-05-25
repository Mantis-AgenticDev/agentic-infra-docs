---
# FRONTMATTER CANÓNICO OBRIGATÓRIO
artifact_id: "00-index-configurations-v2.3.0"
artifact_type: "directory_index"
version: "2.3.0"
constraints_mapped: ["C4","C5"]
canonical_path: "05-CONFIGURATIONS/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "root_index"
agent_role: "configurations-ceo"
language_lock: "pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain configurations --file 05-CONFIGURATIONS/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
# FIN FRONTMATTER
---

# 📁 05-CONFIGURATIONS/ — Índice Mestre do Domínio

> **Propósito**: Ponto de entrada canônico para o domínio de infraestrutura, configuração e governança do ecossistema MANTIS. Fornece navegação estruturada, mapeamento de proprietários, constraints aplicáveis e rotas de validação para agentes e arquitetos.

## 🗺️ Mapa de Subdomínios

| Subdomínio | Rota Canônica | Agente Responsável | Owner Principal | Constraints | Estado |
|------------|---------------|-------------------|-----------------|-------------|--------|
| **Coordenação (CEO)** | `05-CONFIGURATIONS/` | `configurations-ceo` | `@facundo` / `arch-team` | C1-C9 | ✅ REAL |
| **Libs do CEO** | `05-CONFIGURATIONS/libs/` | `configurations-ceo` | `@facundo` / `arch-team` | C1-C9 | ✅ REAL |
| **Terraform** | `05-CONFIGURATIONS/terraform/` | `terraform-master-agent` | `@facundo` / `infra-team` | C1,C2,C3,C5,C7 | ✅ REAL |
| **Docker Compose** | `05-CONFIGURATIONS/docker-compose/` | `docker-compose-master-agent` | `@facundo` / `platform-team` | C1,C2,C3,C5,C7,C8 | ✅ REAL |
| **Pipelines CI/CD** | `05-CONFIGURATIONS/pipelines/` | `pipelines-master-agent` | `@facundo` / `devops-team` | C1,C3,C5,C6,C8 | ✅ REAL |
| **Scripts Operativos** | `05-CONFIGURATIONS/scripts/` | `configurations-ceo` | `@facundo` / `sre-team` | C1,C3,C5,C7 | ✅ REAL |
| **Segurança** | `05-CONFIGURATIONS/security/` | `configurations-ceo` | `@facundo` / `security-team` | C3,C5,C6 | ✅ REAL |
| **Observabilidade** | `05-CONFIGURATIONS/observability/` | `configurations-ceo` | `@facundo` / `sre-team` | C4,C5,C7,C8,V3 | ✅ REAL |
| **Ambiente/Variáveis** | `05-CONFIGURATIONS/environment/` | `configurations-ceo` | `@facundo` / `platform-team` | C3,C4,C5 | ✅ REAL |
| **Templates** | `05-CONFIGURATIONS/templates/` | `configurations-ceo` | `@facundo` / `dev-team` | C1,C4,C5 | ✅ REAL |
| **Validação/Harness** | `05-CONFIGURATIONS/validation/` | `orchestrator-engine` | `@facundo` / `qa-team` | C4,C5,C8 | ✅ REAL |
| **Registry/Manifests** | `05-CONFIGURATIONS/registry/` | `configurations-ceo` | `@facundo` / `arch-team` | C1,C4,C5 | ✅ REAL |

## 🛠️ Scripts Críticos & Acessos Rápidos

| Comando | Propósito | Domínio | Validação |
|---------|-----------|---------|------------|
| `./scripts/deploy-all.sh` | Orquestra despliegue completo (Terraform → Docker → Health) | Root | `shellcheck`, `orchestrator-engine.sh` |
| `./scripts/onboard-tenant.sh` | Alta de tenant com RLS e registry update | Scripts | `bash -n`, `V1-compliance` |
| `./scripts/migrate-tenant.sh` | Migração segura entre ambientes com checksum | Scripts | `pg_restore`, `C7-rollback` |
| `./scripts/vps-hardening.sh` | Endurecimento de SO (UFW, Fail2Ban, SSH) | Security | `cis-benchmark`, `C6-compliance` |
| `./scripts/rotate-secrets.sh` | Rotação automática de credenciais (90d) | Security | `audit-secrets.sh`, `C3-validation` |
| `./scripts/drift-remediate.sh` | Correção automática de desvios IaC | Terraform | `terraform plan`, `C2-sync` |

## 📐 Matriz de Validação & Constraints (C1-C8, V1-V3)

| Constraint | Descrição | Domínio(s) Aplicáveis | Ferramenta de Validação | Gate CI/CD |
|------------|-----------|------------------------|-------------------------|------------|
| **C1** | Imutabilidade/Versionado | Todos | `git diff`, `semantic-release` | `integrity-check.yml` |
| **C2** | Infraestrutura como Código | `terraform/`, `docker-compose/` | `terraform validate`, `docker compose config` | `terraform-plan.yml` |
| **C3** | Zero Secrets em Texto Plano | Todos | `audit-secrets.sh`, `trivy fs --secret` | `security-scan.yml` |
| **C4** | Rastreabilidade/Labels | `observability/`, `environment/` | `check-wikilinks.sh`, `validate-frontmatter.sh` | `validate-skill.yml` |
| **C5** | Integridade Estrutural | Todos | `orchestrator-engine.sh`, `shellcheck` | `integrity-check.yml` |
| **C6** | Aprovações/Compliance | `security/`, `pipelines/` | `checkov`, `tfsec`, `opa` | `compliance-audit.yml` |
| **C7** | Resiliência/Rollback | `scripts/`, `docker-compose/` | `backup-verify.sh`, `health-check.sh` | `deploy-*.yml` |
| **C8** | Observabilidade/Métricas | `observability/` | `promtool`, `grafana-api` | `monitoring-check.yml` |
| **V1** | Isolamento Tenants (RLS) | `scripts/`, `observability/` | `check-rls.sh`, `verify-constraints.sh` | `validate-skill.yml` |
| **V2** | Integridade Dados Vetoriais | `observability/`, `scripts/` | `pg_verifybackup`, `sha256sum` | `backup-verify.yml` |
| **V3** | Performance Busca Vetorial | `observability/` | `vector-alerts.yml`, `latency-check.sh` | `perf-gate.yml` |

## 🤖 Guias de Ingestão para Agentes (C4/C5)

### Regras de Navegação
1. **Não assumir rotas**: Sempre resolver rotas canônicas desde `canonical_registry.json` ou este índice.
2. **Frontmatter obrigatório**: Todo arquivo `.md`, `.yaml`, `.sh` neste domínio deve incluir `artifact_id`, `constraints_mapped`, `validation_command` e `checksum_sha256`.
3. **Idioma**: `pt-BR` como padrão para todos os artefatos (evitar deriva multilinguística).
4. **Carga de contexto**: Carregar APENAS os subdomínios necessários para a tarefa. Nunca carregar `05-CONFIGURATIONS/` completo.

### Comandos de Validação Padrão
```bash
# Validação completa do domínio
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain configurations --strict

# Verificação de checksums
for f in 05-CONFIGURATIONS/**/*.{md,yaml,sh}; do
  bash verify-and-commit.sh "$f" --check-only
done

# Auditoria de secrets
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --path 05-CONFIGURATIONS/
```

## ⚠️ Anti-Padrões Explícitos (NÃO FAZER)
- ❌ Modificar arquivos em `terraform/` ou `docker-compose/` sem passar por `orchestrator-engine.sh --strict`
- ❌ Hardcodear valores de infra (`mem_limit`, `cpu_quota`) em vez de usar variáveis de ambiente
- ❌ Commitear `.env` com valores reais (usar `git-crypt` ou `sops`)
- ❌ Omitir `validation_command` no frontmatter de novos artefatos
- ❌ Gerar código sem validar `LANGUAGE_LOCK` e constraints `C1-C8`
- ❌ Usar idioma diferente de `pt-BR` em novos artefatos (viola padronização)

## 📊 Estado do Domínio & Métricas
- **Última auditoria completa**: 2026-05-24T10:00:00Z
- **Versão do CEO**: 2.3.0 (modular, 15 skills em `libs/`)
- **Subdomínios com agente próprio**: 3 (docker-compose, pipelines, terraform)
- **Subdomínios governados diretamente**: 5 (templates, scripts, environment, observability, security)
- **Procedimentos documentados**: `07-PROCEDURES/configurations-ceo-sop.md`
- **Próxima revisão de governança**: Turno 15 / Sessão atual

## 🔗 Links Canônicos Relacionados
- [[00-STACK-SELECTOR.md]] → Kernel de roteamento e resolução de `{language}`
- [[IA-QUICKSTART.md]] → Protocolo ACG e gates de modo (A1-A3, B1-B3)
- [[configurations-ceo.md]] → Agente coordenador do domínio
- [[interface-spec.yaml]] → Especificação de interface entre domínios (v2.3.0)
- [[canonical_registry.json]] → Índice mestre de artefatos e dependências
- [[07-PROCEDURES/configurations-ceo-sop.md]] → Procedimento operacional do CEO
- [[07-PROCEDURES/docker-compose-sop.md]] → Procedimento operacional Docker Compose
- [[07-PROCEDURES/pipelines-sop.md]] → Procedimento operacional Pipelines
- [[07-PROCEDURES/terraform-sop.md]] → Procedimento operacional Terraform

---
*Documento gerado por `configurations-ceo` v2.3.0 | Mantido por `configurations-ceo` | Constraints: C4, C5*
