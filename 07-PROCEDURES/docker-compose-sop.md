---
artifact_id: "procedures-docker-compose-sop"
artifact_type: "standard_operating_procedure"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "07-PROCEDURES/docker-compose-sop.md"
tier: 1
immutable: false
requires_human_approval_for_changes: true
audience: ["human-architects","agentic-assistants","orchestrator-engine","devops"]
language_lock: "pt-BR"
prompt_hash: "sha256:docker-compose-sop-v2.3.0"
generated_at: "2026-05-23T22:00:00Z"
domain: "procedures"
subdomain: "docker-compose"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# 🐳 Procedimento Operacional Padrão — Docker Compose MANTIS Agentic

**Objetivo**: Estabelecer o fluxo de trabalho completo para operação do domínio `docker-compose/`, incluindo geração de stacks, configuração de túneis SSH, deploy ordenado, validação e recuperação de falhas.

**Público-alvo**: Arquitetos humanos, agentes mestres, engenheiros DevOps, operadores de infraestrutura.

---

## 1. Visão Geral do Domínio

O domínio `05-CONFIGURATIONS/docker-compose/` é responsável pela orquestração de contêineres no ecossistema MANTIS. Ele contém:

- **Agente Mestre** (`docker-compose-master-agent.md`): framework executável de geração de stacks.
- **Skills Modulares** (`libs/`): padrões reutilizáveis de YAML, health checks, segurança, redes, volumes.
- **Arquivos Compose** (`vps1-n8n-uazapi.yml`, `vps2-crm-qdrant.yml`, `vps3-n8n-uazapi.yml`): stacks de produção para 3 VPS interconectados.

### 1.1 Conexão com o Ecossistema `goals/`

```mermaid
graph TD
    A[Orchestrator Engine] -->|1. Atribui meta| B[registry.db]
    B -->|2. goal_id, agent, status| A
    A -->|3. Adquire meta com CAS| C[RegistryClient.acquire_goal]
    C -->|4. Sucesso| D[docker-compose-master-agent]
    D -->|5. Carrega skills sob demanda| E[libs/00-INDEX.md]
    D -->|6. Gera stack YAML| F[vpsX.yml]
    D -->|7. Valida com orchestrator-engine.sh| G[Validação C5]
    G -->|8. Handoff A2A| H[status.json + trace.json]
    H -->|9. Libera meta| C
```

---

## 2. Fluxo de Geração de Stacks

```mermaid
stateDiagram-v2
    [*] --> Especificação: Requisitos do stack + perfil de infra
    Especificação --> Seleção_de_Skills: Carregar libs/00-INDEX.md
    Seleção_de_Skills --> Geração: Aplicar x-service-base + health checks
    Geração --> Segurança: Adicionar hardening (non-root, secrets, read_only)
    Segurança --> Rede: Configurar redes e isolamento
    Rede --> Volumes: Configurar persistência
    Volumes --> Validação: docker compose config + orchestrator-engine.sh
    Validação --> Aprovado: passed=true
    Validação --> Rejeitado: passed=false
    Rejeitado --> Diagnóstico: Ler issues no output JSON
    Diagnóstico --> Correção: Aplicar fix_hint por constraint violada
    Correção --> Validação
    Aprovado --> Handoff: status.json com output_ref
    Handoff --> [*]
```

---

## 3. Conexão com Outros Domínios

```mermaid
graph LR
    Master["🧠 docker-compose-master-agent.md"] --> Core["🧠 mantis-core-context.md<br/>Constraints C1-C8"]
    Master --> Rules["📜 harness-norms-v3.0.md<br/>Hardening padrão"]
    Master --> Orchestrator["⚙️ orchestrator-engine/main.go<br/>Validação automatizada"]
    Master --> Pipelines["🚀 pipelines-master-agent<br/>CI/CD e deploy"]
    Master --> Terraform["🏗️ terraform-master-agent<br/>Infraestrutura como código"]
    Master --> Pgvector["🔷 postgresql-pgvector-master-agent<br/>Config de DB"]
    
    Core -.->|Define contrato C1-C8| Master
    Rules -.->|Especifica hardening mínimo| Master
    Orchestrator -.->|Valida artefatos via JSON| Master
    Pipelines -.->|Recebe Compose para deploy| Master
    Terraform -.->|Provisiona recursos externos| Master
    Pgvector -.->|Fornece config de DB| Master
    
    style Master fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:4px
    style Core fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Rules fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Orchestrator fill:#16213e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style Pipelines fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Terraform fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
    style Pgvector fill:#0f3460,color:#fff,stroke:#7f7f7f,stroke-width:1px,stroke-dasharray: 3 3
```

---

## 4. Inter-relação dos Módulos Internos (`libs/`)

```mermaid
graph TD
    MASTER["🧠 docker-compose-master-agent.md"]:::foundation
    BASE["🧱 base-service-template.md"]:::foundation
    HEALTH["🩺 healthcheck-patterns.md"]:::foundation
    SECURITY["🛡️ security-patterns.md"]:::security
    NETWORK["🌐 network-patterns.md"]:::operations
    VOLUMES["💾 volume-patterns.md"]:::operations
    DEPLOY["🚀 deployment-strategies.md"]:::operations
    IMAGE["🏗️ image-building.md"]:::operations
    LOGGING["📊 logging-observability.md"]:::operations
    ENV["🌍 environment-strategies.md"]:::operations

    MASTER --> BASE
    MASTER --> HEALTH
    MASTER --> SECURITY
    MASTER --> NETWORK
    MASTER --> VOLUMES
    MASTER --> DEPLOY
    MASTER --> IMAGE
    MASTER --> LOGGING
    MASTER --> ENV
    
    BASE --> SECURITY
    BASE --> HEALTH
    SECURITY --> NETWORK
    NETWORK --> VOLUMES
    DEPLOY --> HEALTH
    IMAGE --> SECURITY
    LOGGING --> HEALTH

    classDef foundation fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    classDef security fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    classDef operations fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
```

---

## 5. Arquitetura de Rede 3-VPS

```mermaid
graph TD
    INTERNET["🌐 INTERNET"] -->|HTTPS:443| VPS1["🖥️ VPS1<br/>n8n + uazapi + Redis"]
    INTERNET -->|HTTPS:443| VPS2["🗄️ VPS2<br/>EspoCRM + MySQL + Qdrant"]
    INTERNET -->|HTTPS:443| VPS3["🔄 VPS3<br/>n8n + uazapi + Redis (Failover)"]
    
    VPS1 -->|"SSH Tunnel :3306 → :3306"| VPS2
    VPS1 -->|"SSH Tunnel :6333 → :6333"| VPS2
    VPS3 -->|"SSH Tunnel :3307 → :3306"| VPS2
    VPS3 -->|"SSH Tunnel :6334 → :6333"| VPS2
    
    VPS2 -->|"MySQL (interno)"| MYSQL["mysql:3306"]
    VPS2 -->|"Qdrant (interno)"| QDRANT["qdrant:6333"]
    
    style INTERNET fill:#1a1a2e,color:#fff,stroke:#E0AF68,stroke-width:3px
    style VPS1 fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    style VPS2 fill:#16213e,color:#fff,stroke:#E0AF68,stroke-width:2px
    style VPS3 fill:#0f3460,color:#fff,stroke:#E0AF68,stroke-width:2px
    style MYSQL fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
    style QDRANT fill:#2a2a4e,color:#fff,stroke:#7f7f7f,stroke-width:1px
```

---

## 6. Configuração de Túneis SSH

Os túneis SSH permitem que VPS1 e VPS3 acessem MySQL e Qdrant no VPS2 sem expor esses serviços à internet.

### 6.1 Pré-requisito: Chaves SSH

```bash
# Em VPS1 e VPS3: gerar chave e copiar para VPS2
ssh-keygen -t ed25519 -C "vps1-mantis-tunnel" -f ~/.ssh/vps1_tunnel -N ""
ssh-copy-id -i ~/.ssh/vps1_tunnel.pub root@IP_VPS2
ssh -i ~/.ssh/vps1_tunnel root@IP_VPS2 "echo 'Conexão OK'"
```

### 6.2 Configurar SSH Config

```bash
cat > ~/.ssh/config << 'EOF'
Host vps2
    HostName IP_VPS2
    User root
    IdentityFile ~/.ssh/vps1_tunnel
    ServerAliveInterval 30
    ServerAliveCountMax 3
    StrictHostKeyChecking accept-new
    ConnectTimeout 10
EOF
chmod 600 ~/.ssh/config
```

### 6.3 Criar Túneis Persistentes com Systemd

```bash
# Instalar autossh
apt-get install -y autossh

# Criar serviço para túnel MySQL
cat > /etc/systemd/system/mantis-tunnel-mysql.service << 'EOF'
[Unit]
Description=MANTIS SSH Tunnel — MySQL VPS2
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/mantis/tunnels.env
ExecStart=/usr/bin/autossh -M 0 -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -i /root/.ssh/vps1_tunnel \
  -L "127.0.0.1:3306:127.0.0.1:3306" \
  root@${VPS2_IP}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Repetir para Qdrant REST (porta 6333) e Qdrant gRPC (porta 6334)
# Habilitar e iniciar
systemctl daemon-reload
systemctl enable --now mantis-tunnel-mysql mantis-tunnel-qdrant-rest mantis-tunnel-qdrant-grpc
```

---

## 7. Processo de Deploy Ordenado

**Ordem obrigatória**: VPS2 → VPS1 → VPS3

```mermaid
sequenceDiagram
    participant DevOps
    participant VPS2
    participant VPS1
    participant VPS3
    
    DevOps->>VPS2: 1. Deploy MySQL + Qdrant + EspoCRM
    VPS2-->>DevOps: Health checks OK
    DevOps->>VPS1: 2. Configurar túneis SSH
    VPS1->>VPS2: Túneis estabelecidos
    DevOps->>VPS1: 3. Deploy n8n + uazapi + Redis
    VPS1-->>DevOps: Health checks OK
    DevOps->>VPS3: 4. Configurar túneis SSH
    VPS3->>VPS2: Túneis estabelecidos
    DevOps->>VPS3: 5. Deploy n8n + uazapi + Redis (failover)
    VPS3-->>DevOps: Health checks OK
```

### 7.1 Comandos de Deploy

```bash
# PASSO 1: Deploy VPS2
ssh root@IP_VPS2 "cd /opt/mantis && docker compose -f vps2-crm-qdrant.yml up -d --wait"
sleep 90

# PASSO 2: Túneis em VPS1
ssh root@IP_VPS1 "systemctl start mantis-tunnel-mysql mantis-tunnel-qdrant-rest mantis-tunnel-qdrant-grpc"

# PASSO 3: Deploy VPS1
ssh root@IP_VPS1 "cd /opt/mantis && docker compose -f vps1-n8n-uazapi.yml up -d --wait"

# PASSO 4: Túneis em VPS3
ssh root@IP_VPS3 "systemctl start mantis-tunnel-mysql mantis-tunnel-qdrant-rest"

# PASSO 5: Deploy VPS3
ssh root@IP_VPS3 "cd /opt/mantis && docker compose -f vps3-n8n-uazapi.yml up -d --wait"
```

---

## 8. Validação Pós-Deploy

| # | Verificação | Constraint | Comando | ✅ Esperado |
|---|---|---|---|---|
| 1 | MySQL não acessível da internet | C3 | `nc -zv IP_VPS2 3306` | Connection refused |
| 2 | Qdrant não acessível da internet | C3 | `nc -zv IP_VPS2 6333` | Connection refused |
| 3 | Túnel MySQL ativo em VPS1 | C7 | `ss -tulpn \| grep 127.0.0.1:3306` | 127.0.0.1:3306 |
| 4 | Túnel Qdrant ativo em VPS1 | C7 | `ss -tulpn \| grep 127.0.0.1:6333` | 127.0.0.1:6333 |
| 5 | MySQL responde via túnel | C7 | `mysqladmin ping -h 127.0.0.1 -P 3306 -u root -p$PASS` | mysqld is alive |
| 6 | EspoCRM acessível via HTTPS | C3 | `curl -sf https://crm.dominio.com` | HTTP 200 |
| 7 | n8n protegido com BasicAuth | C3 | `curl -sf https://n8n.dominio.com` | HTTP 401 |
| 8 | Redis não acessível da internet | C3 | `redis-cli -h IP_VPS1 -p 6379 ping` | Could not connect |
| 9 | Subnets Docker sem colisão | C7 | `docker network ls` | 172.20.x, 172.21.x, 172.22.x |
| 10 | Health checks dos serviços | C8 | `docker ps --filter 'health=unhealthy'` | Nenhum unhealthy |
| 11 | Túneis com restart automático | C7 | `systemctl show mantis-tunnel-mysql \| grep Restart=` | Restart=on-failure |
| 12 | tenant_id nos contêineres | C4 | `docker inspect mantis-n8n \| grep TENANT_ID` | TENANT_ID configurado |
| 13 | Logs em JSON | C8 | `docker logs mantis-n8n --tail 1 \| python3 -m json.tool` | JSON válido |
| 14 | ICC desabilitado em redes internas | C3 | `docker network inspect mantis-internal \| grep icc` | enable_icc: false |
| 15 | autossh reconecta após queda | C7 | Parar docker no VPS2 → esperar 60s → verificar túnel | Túnel reconectado |

---

## 9. Operações Diárias

### 9.1 Ver Estado dos Serviços

```bash
for vps in $VPS1_IP $VPS2_IP $VPS3_IP; do
  echo "─── $vps ───"
  ssh root@$vps "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
done
```

### 9.2 Backup Manual

```bash
# MySQL (VPS2)
ssh root@$VPS2_IP "
  TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
  docker exec mantis-mysql mysqldump -u root -p\$MYSQL_ROOT_PASSWORD \
    --all-databases --single-transaction | gzip > /opt/mantis/backups/mysql_\$TIMESTAMP.sql.gz
  sha256sum /opt/mantis/backups/mysql_\$TIMESTAMP.sql.gz
"

# Qdrant (VPS2)
ssh root@$VPS2_IP "
  curl -X POST -H 'api-key: \$QDRANT_API_KEY' 'http://127.0.0.1:6333/snapshots'
"
```

### 9.3 Failover VPS1 → VPS3

```bash
# 1. Verificar VPS3
ssh root@$VPS3_IP "docker ps | grep mantis-vps3-n8n"

# 2. Atualizar DNS: n8n.dominio.com → IP_VPS3

# 3. Notificar
echo "⚠️ FAILOVER ATIVADO: n8n em VPS3 ($VPS3_IP)"
```

---

## 10. Troubleshooting

| Sintoma | VPS | Causa Provável | Diagnóstico | Solução |
|---------|-----|---------------|-------------|---------|
| `n8n não conecta ao MySQL` | VPS1 | Túnel SSH caído | `systemctl status mantis-tunnel-mysql` | `systemctl restart mantis-tunnel-mysql` |
| `EspoCRM: Erro de BD` | VPS2 | MySQL reiniciando | `docker logs mantis-mysql` | `docker compose restart mysql` |
| `Qdrant: Connection refused` | VPS1/3 | Túnel Qdrant caído | `ss -tulpn \| grep 6333` | `systemctl restart mantis-tunnel-qdrant-rest` |
| `OOM: MySQL killed` | VPS2 | Buffer pool > RAM | `dmesg \| grep killed` | Reduzir `innodb_buffer_pool_size` ou escalar KVM2 |
| `Traefik: 502 Bad Gateway` | VPS1/2/3 | Backend caído | `docker logs mantis-traefik --tail 20` | Reiniciar serviço backend |
| `SSH: Host key verification failed` | Qualquer | Chave do servidor mudou | `ssh-keygen -R IP_VPS2` | Remover chave antiga e reconectar |

---

## 11. Rollback de Emergência

```bash
# 1. Reverter para tag de imagem anterior
ssh root@$VPS1_IP "
  cd /opt/mantis
  export VERSION=<versão-anterior>
  docker compose -f vps1-n8n-uazapi.yml up -d --wait
"

# 2. Se necessário, restaurar banco de dados
ssh root@$VPS2_IP "
  cd /opt/mantis
  gunzip -c backups/mysql_<timestamp>.sql.gz | docker exec -i mantis-mysql mysql -u root -p\$MYSQL_ROOT_PASSWORD
"

# 3. Verificar saúde
bash scripts/health-check.sh prod
```

---

## 12. Referências Cruzadas

- [[05-CONFIGURATIONS/docker-compose/docker-compose-master-agent.md]] — Agente mestre
- [[05-CONFIGURATIONS/docker-compose/libs/00-INDEX.md]] — Índice de skills
- [[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]] — Stack VPS1
- [[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]] — Stack VPS2
- [[05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml]] — Stack VPS3
- [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] — Motor de validação
- [[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]] — IaC complementar
- [[goals/README.md]] — Sistema de metas
- [[01-RULES/harness-norms-v3.0.md]] — Hardening padrão
- [[01-RULES/11-A2A-COMMUNICATION-RULES.md]] — Contrato A2A (C9)

---

> **Versão 2.3.0** | Procedimento Operacional Padrão do domínio `docker-compose/` — MANTIS Agentic.
> Aplicável a partir de 2026-05-23.
