---
artifact_id: readme-deployment-mantis
artifact_type: documentation_guide
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C1","C2","C4","C5","C6","C8"]
canonical_path: 05-CONFIGURATIONS/docs/README-deployment.md
domain: 05-CONFIGURATIONS
subdomain: docs
agent_role: configurations-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain configurations --strict
tier: 2
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_devops"]
human_readable: false
checksum_sha256: "c477c5afac15fdaed165ae101ccd93787346312e90ab02d1d41e4da1afadf8e7"
---

# 📖 GUÍA DE DESPLIEGUE OPERATIVO (MANTIS v2.0.0)
## 1. Metadata & Scope
| Campo | Valor | Constraint |
|-------|-------|------------|
| `scope` | Despliegue de infra (Terraform) + servicios (Docker Compose) + validación post-deploy | C2, C8 |
| `environments` | `dev`, `staging`, `prod` (tfvars en `05-CONFIGURATIONS/terraform/envs/`) | C4 |
| `orchestrator` | `pipeline-deploy.sh` (artefacto #50) | C5, C6 |
| `owner` | infra-ops / configurations-master-agent | C4 |
| `rollback_policy` | Automático si health-check falla o approval gate es rechazado | C7 |

## 2. Pre-requisitos Operativos
- [ ] Repositorio clonado y rama alineada a `main` o `release/*`
- [ ] Credenciales AWS configuradas (OIDC recomendado) + permisos `ec2:*`, `rds:*`, `s3:*`, `apigateway:*`
- [ ] `terraform.tfvars` para el entorno objetivo generado y validado (`#46`, `#47`, `#48`)
- [ ] Secrets inyectados vía `TF_VAR_db_password`, `TF_VAR_qdrant_api_key` o Vault/CI (C3: **nunca** en disco)
- [ ] Docker Engine ≥ 24.0 y Docker Compose ≥ 2.20 instalados

## 3. Flujo de Despliegue Estandarizado
### 3.1 Entorno Desarrollo (`dev`)
```bash
# Despliegue completo sin gates humanos
bash 05-CONFIGURATIONS/scripts/pipeline-deploy.sh dev all --force
# Validación rápida
bash 05-CONFIGURATIONS/scripts/health-check.sh dev
```

### 3.2 Entorno Staging (`staging`)
```bash
# Despliegue infra → servicios → validación
bash 05-CONFIGURATIONS/scripts/pipeline-deploy.sh staging all
# Test de alertas (dry-run por defecto)
bash 05-CONFIGURATIONS/scripts/test-alerts.sh staging
```

### 3.3 Entorno Producción (`prod`)
```bash
# 1. Plan & Review (obligatorio)
cd 05-CONFIGURATIONS/terraform
terraform plan -var-file=envs/prod/terraform.tfvars -out=tfplan-prod
# 2. Apply con gate humano
bash 05-CONFIGURATIONS/scripts/pipeline-deploy.sh prod all
# 3. Validación de calidad C8
bash 05-CONFIGURATIONS/scripts/health-check.sh prod
bash 05-CONFIGURATIONS/scripts/generate-sitrep.sh
```

## 4. Gates & Validación (C5, C6, C8)
| Fase | Gate | Criterio de Éxito | Fallback |
|------|------|-------------------|----------|
| Infra | `terraform apply` | 0 cambios no planificados, estado S3 actualizado | `terraform state push --force` (solo si estado corrupto) |
| Servicios | `docker compose up --wait` | Todos los contenedores en `healthy` en ≤120s | `docker compose down` + revertir imagen tag |
| Calidad | `health-check.sh` | API, DB y Qdrant responden `200 OK` | Activar rollback automático (C7) |
| Seguridad | `test-alerts.sh` | Regulas YAML válidas, canal de notificación verificado | Revisar `observability/alerts/` y routing Alertmanager |

## 5. Procedimiento de Rollback (C7)
1. **Automático**: Si `pipeline-deploy.sh` falla en validación, ejecuta `trap 'rollback' ERR`.
2. **Manual Controlado**:
   ```bash
   # Revertir infra a estado anterior
   cd 05-CONFIGURATIONS/terraform && terraform apply -target=module.vps_base -var-file=envs/prod/terraform.tfvars
   # Revertir servicios a tag estable
   cd 05-CONFIGURATIONS/docker-compose && docker compose -f vps1-n8n-uazapi.yml down --rmi local && docker compose up -d
   # Restaurar DB si hay corrupción (V2)
   bash 05-CONFIGURATIONS/scripts/restore-mysql.sh /var/backups/mantis-db/latest.sql.zst --force
   ```

## 6. Troubleshooting Rápido
| Síntoma | Causa Probable | Acción |
|---------|----------------|--------|
| `TF_INIT_FAIL` | Backend S3 bloqueado o creds expiradas | Verificar `backend.tf`, renovar OIDC, revisar bucket policy |
| `COMPOSE_CONFIG_FAIL` | Variables `.env` faltantes o sintaxis YAML rota | Ejecutar `docker compose config`, validar `.env.example` |
| `HEALTH_CHECK_FAIL` | Puerto bloqueado por SG o DB no ready | Revisar `vps-base/main.tf` SG, logs `journalctl -u docker` |
| `ALERT_ROUTING_FAIL` | `test-alerts.sh` dry-run o webhook inválido | Verificar `TEST_CHANNEL_WEBHOOK`, ejecutar con `--dry-run false` |

## 7. Anti-Patterns (C1, C3, C6)
- ❌ **NUNCA**: Ejecutar `terraform apply -auto-approve` en prod sin revisión de plan (C6)
- ❌ **NUNCA**: Modificar `pipeline-deploy.sh` localmente para saltar gates (viola C1/C5)
- ❌ **NUNCA**: Usar `docker compose up` sin `--wait` o sin límites de recursos (C8)
- ❌ **NUNCA**: Hardcodear `db_password` o `qdrant_api_key` en tfvars o `.env` (C3)
- ✅ **SIEMPRE**: Registrar hash de commit y timestamp en `08-LOGS/deploy-*.json` (C4)
- ✅ **SIEMPRE**: Validar contra `interface-spec.yaml` antes de declarar "despliegue exitoso"

## 8. Comandos de Validación & Mantenimiento
```bash
# Validar estructura de docs
yq eval '.' 05-CONFIGURATIONS/docs/README-deployment.md > /dev/null && echo "✅ Markdown/YAML válido"
# Verificar alineación de scripts referenciados
for f in pipeline-deploy.sh health-check.sh restore-mysql.sh test-alerts.sh generate-sitrep.sh; do
  test -x 05-CONFIGURATIONS/scripts/$f && echo "✅ $f ejecutable" || echo "⚠️ $f ausente o sin permisos"
done
# Actualizar checksum (post-merge)
CHECKSUM=$(sha256sum 05-CONFIGURATIONS/docs/README-deployment.md | awk '{print $1}')
sed -i "s/checksum_sha256: "c477c5afac15fdaed165ae101ccd93787346312e90ab02d1d41e4da1afadf8e7"
```

---
*Guía generada bajo normas C1-C8/V1-V3. Inmutable hasta aprobación humana. Checksum pendiente de generación post-deployment.*


---
