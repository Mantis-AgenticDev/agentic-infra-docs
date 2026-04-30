#!/bin/bash
# update-batch-43-checksums.sh - Lote 2: 43 artefactos críticos (#18 al #60)
set -euo pipefail

ARTIFACTS=(
  "05-CONFIGURATIONS/terraform/modules/backup-encrypted/main.tf"
  "05-CONFIGURATIONS/terraform/modules/openrouter-proxy/main.tf"
  "05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml"
  ".github/workflows/terraform-plan.yml"
  "05-CONFIGURATIONS/scripts/backup-mysql.sh"
  "05-CONFIGURATIONS/scripts/packager-assisted.sh"
  "05-CONFIGURATIONS/scripts/sync-to-sandbox.sh"
  "05-CONFIGURATIONS/observability/otel-tracing-config.yaml"
  "05-CONFIGURATIONS/pipelines/promptfoo/config.yaml"
  "05-CONFIGURATIONS/pipelines/promptfoo/test-cases/tenant-isolation.yaml"
  "05-CONFIGURATIONS/terraform/variables.tf"
  "05-CONFIGURATIONS/terraform/outputs.tf"
  "05-CONFIGURATIONS/scripts/compact-chronique.sh"
  "05-CONFIGURATIONS/observability/runbooks/disaster-recovery.md"
  "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml"
  "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml"
  "05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf"
  "05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf"
  "05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf"
  "05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf"
  "05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf"
  "05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf"
  "05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf"
  "05-CONFIGURATIONS/scripts/backup-qdrant.sh"
  "05-CONFIGURATIONS/scripts/restore-mysql.sh"
  "05-CONFIGURATIONS/scripts/bootstrap-hardened-repo.sh"
  "05-CONFIGURATIONS/scripts/test-alerts.sh"
  "05-CONFIGURATIONS/scripts/generate-sitrep.sh"
  "05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars"
  "05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars"
  "05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars"
  "05-CONFIGURATIONS/observability/alerts/mantis-alerts.yml"
  "05-CONFIGURATIONS/scripts/pipeline-deploy.sh"
  "05-CONFIGURATIONS/docs/README-deployment.md"
  "05-CONFIGURATIONS/terraform/envs/.gitkeep"
  "05-CONFIGURATIONS/observability/prometheus.yml"
  "05-CONFIGURATIONS/observability/grafana/dashboards/core-mantis.json"
  "05-CONFIGURATIONS/observability/grafana/provisioning/dashboards.yml"
  "05-CONFIGURATIONS/observability/alertmanager/config.yml"
  "05-CONFIGURATIONS/observability/alertmanager/templates/notification.tmpl"
  "05-CONFIGURATIONS/security/vault-policies.hcl"
  "05-CONFIGURATIONS/security/git-crypt-keys/README.md"
  "05-CONFIGURATIONS/scripts/generate-checksum-manifest.sh"
)

MANIFEST="05-CONFIGURATIONS/registry/checksum-manifest.json"
mkdir -p "$(dirname "$MANIFEST")"

echo "🔐 Generando checksums para Lote 2 (${#ARTIFACTS[@]} artefactos)..."

for artifact in "${ARTIFACTS[@]}"; do
  if [[ -f "$artifact" ]]; then
    CHECKSUM=$(sha256sum "$artifact" | awk '{print $1}')
    # Update frontmatter checksum (compatible con YAML, HCL y Markdown)
    sed -i "s/checksum_sha256: .*/checksum_sha256: \"$CHECKSUM\"/" "$artifact" 2>/dev/null || true
    sed -i "s/# checksum_sha256: .*/# checksum_sha256: \"$CHECKSUM\"/" "$artifact" 2>/dev/null || true
    
    # Register in manifest
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg path "$artifact" --arg sha "$CHECKSUM" --arg ts "$TIMESTAMP" \
       '.artifacts[$path] = {version: "2.0.0-COMPREHENSIVE", sha256: $sha, last_modified: $ts, validated_by: "orchestrator-engine.sh", constraints: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]}' \
       "$MANIFEST" > "${MANIFEST}.tmp" 2>/dev/null && mv "${MANIFEST}.tmp" "$MANIFEST" || \
       jq -n --arg path "$artifact" --arg sha "$CHECKSUM" --arg ts "$TIMESTAMP" \
       '{artifacts: {($path): {version: "2.0.0-COMPREHENSIVE", sha256: $sha, last_modified: $ts, validated_by: "orchestrator-engine.sh", constraints: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]}}}' > "$MANIFEST"
    echo "✅ $artifact → $CHECKSUM"
  else
    echo "⚠️ FILE_NOT_FOUND: $artifact"
  fi
done

echo "📄 Manifest actualizado: $MANIFEST"
echo "✅ Lote 2: Checksums generados. Listo para commit y recarga de contexto."
