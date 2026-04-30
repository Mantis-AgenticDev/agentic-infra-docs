---
artifact_id: runbook-disaster-recovery-mantis
artifact_type: runbook_documentation
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C4","C5","C7","C8","V2"]
canonical_path: 05-CONFIGURATIONS/observability/runbooks/disaster-recovery.md
domain: 05-CONFIGURATIONS
subdomain: observability
agent_role: configurations-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain configurations --strict
tier: 2
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_operators"]
human_readable: false
checksum_sha256: "b3a009a238f3860367b757417753e1d1ea5683226e2c910adf7003d9bacc5d98"
---

# 🚨 RUNBOOK: RECUPERACIÓN ANTE DESASTRE (MANTIS v2.0.0)
## 1. Metadata & Scope
| Field | Value | Constraint |
|-------|-------|------------|
| `trigger` | Pérdida total de VPS, corrupción de estado Terraform, o desastre regional | C7 |
| `rto_target` | < 4 horas (con backups actualizados) | C8 |
| `rpo_target` | < 24 horas (backup diario V2) | V2 |
| `owner` | configurations-master-agent / infra-ops | C4 |
| `last_drill` | YYYY-MM-DD | C7 |

## 2. Prerequisites (Pre-Ejecución)
- [ ] Acceso a cuenta cloud con permisos `IAM:AssumeRole` + `S3:GetObject`
- [ ] Bucket de estado S3 accesible y backend `dynamodb_table` intacto
- [ ] Claves KMS para desencriptar backups y estado disponibles
- [ ] `.env.prod` o secret manager accesible para credenciales de despliegue
- [ ] Este runbook disponible offline o en dispositivo secundario

## 3. Fase 1: Reconstrucción de Infraestructura (Terraform)
```bash
# 1.1 Clonar repositorio en instancia limpia
git clone <repo_url> mantis-recovery && cd mantis-recovery

# 1.2 Configurar backend remoto (apuntar a S3/DynamoDB existentes)
cat > 05-CONFIGURATIONS/terraform/backend.tf <<'EOF'
terraform { backend "s3" { bucket = "${TF_BACKEND_BUCKET}" region = "${AWS_REGION}" key = "mantis/prod/terraform.tfstate" dynamodb_table = "${DYNAMODB_TABLE}" encrypt = true kms_key_id = "${KMS_KEY_ARN}" } }
EOF

# 1.3 Iniciar backend y aplicar estado (idempotente)
cd 05-CONFIGURATIONS/terraform
terraform init -input=false
terraform plan -out=tfplan -var="environment_tag=prod"
# C7: Gate humano obligatorio. Verificar diffs antes de continuar.
terraform apply -auto-approve tfplan
```

## 4. Fase 2: Restauración de Datos (Integridad V2)
```bash
# 2.1 Restaurar PostgreSQL desde backup S3
cd 05-CONFIGURATIONS/scripts
bash backup-mysql.sh --restore --target s3://${BACKUP_BUCKET}/db-backups/latest.sql.zst
# V2: Verificación checksum post-restauración
sha256sum -c latest.sql.zst.sha256 || exit 1

# 2.2 Restaurar índices Qdrant (si aplica)
curl -X POST "${QDRANT_ENDPOINT}/collections/mantis_vectors/snapshots/recover" \
  -H "api-key: ${QDRANT_API_KEY}" \
  -d '{"location": "s3://${BACKUP_BUCKET}/qdrant-snapshots/latest", "priority": "snapshot"}'
```

## 5. Fase 3: Despliegue de Servicios (Docker Compose)
```bash
# 3.1 Ejecutar orquestador con validación estricta
cd 05-CONFIGURATIONS/scripts
bash deploy-all.sh --env prod --skip-terraform

# 3.2 Verificar salud post-deploy (C8)
bash health-check.sh prod --verbose
# Esperado: exit 0, todos los servicios en estado "ok"
```

## 6. Fase 4: Validación Cross-Constraint (C4/C5/C7)
```bash
# 4.1 Ejecutar suite de validación automatizada
bash validate-against-specs.sh 05-CONFIGURATIONS/ --strict

# 4.2 Verificar consistencia de registry & checksums
jq -e '.artifacts | length > 0' 05-CONFIGURATIONS/registry/checksum-manifest.json || exit 1
# 4.3 Test comportamental rápido (Promptfoo subset)
promptfoo eval -c 05-CONFIGURATIONS/pipelines/promptfoo/config.yaml --threshold 0.80 --no-cache --max-concurrency 2
```

## 7. Rollback de Emergencia (Si Fase 3/4 Fallan)
```bash
# 7.1 Revertir servicios a versión estable anterior
cd 05-CONFIGURATIONS/docker-compose
docker compose down --timeout 60
git checkout stable-v1.9.0 # O tag conocido previo al incidente
docker compose up -d --force-recreate

# 7.2 Restaurar estado Terraform a snapshot anterior (S3 versioning)
# Identificar ID de versión en AWS Console → S3 → mantis-state → terraform.tfstate → Versions
aws s3 cp s3://mantis-state/prod/terraform.tfstate?versionId=<VERSION_ID> ./terraform.tfstate.bak
terraform state push ./terraform.tfstate.bak
```

## 8. Anti-Patterns (NUNCA DURANTE RECUPERACIÓN)
- ❌ `terraform destroy` en entorno productivo (viola C7 irreversiblemente)
- ❌ Omitir `sha256sum -c` en restores (viola V2 integridad)
- ❌ Hardcodear credenciales en scripts de recuperación (viola C3)
- ❌ Saltar `health-check.sh` o `validate-against-specs.sh` (viola C8/C5)
- ✅ SIEMPRE: Registrar timestamps, hashes y decisiones en `08-LOGS/incident-YYYYMMDD.log` (C4)
- ✅ SIEMPRE: Validar contra `interface-spec.yaml` antes de declarar "recuperado"

## 9. Comandos de Validación & Mantenimiento
```bash
# yq eval '.' 05-CONFIGURATIONS/observability/runbooks/disaster-recovery.md > /dev/null && echo "✅ Markdown válido"
# grep -q "^checksum_sha256: "b3a009a238f3860367b757417753e1d1ea5683226e2c910adf7003d9bacc5d98"
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/observability/runbooks/disaster-recovery.md | awk '{print $1}') && sed -i "s/checksum_sha256: "b3a009a238f3860367b757417753e1d1ea5683226e2c910adf7003d9bacc5d98"
# orchestrator-engine.sh --domain configurations --file 05-CONFIGURATIONS/observability/runbooks/disaster-recovery.md --strict


---
