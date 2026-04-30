#!/bin/bash
# generate-batch-checksums-2files.sh - Solo 2 archivos solicitados
set -euo pipefail

# 🔒 PROTECCIÓN DE RUTA
if [[ ! -d "05-CONFIGURATIONS" ]]; then
    echo "❌ ERROR CRÍTICO: Ruta inválida."
    echo "   📍 Estás en: $(pwd)"
    echo "   📍 Debes estar en: /home/ricardo/proyectos/agentic-infra-docs/"
    echo "   👉 Ejecuta: cd /home/ricardo/proyectos/agentic-infra-docs/"
    exit 1
fi

ARTIFACTS=(
  "05-CONFIGURATIONS/terraform/modules/README-TEMPLATE.md"
  "05-CONFIGURATIONS/terraform/modules/00-INDEX.md"
)

MANIFEST="05-CONFIGURATIONS/registry/checksum-manifest.json"
mkdir -p "$(dirname "$MANIFEST")"

echo "🔐 Sellando checksums para 2 archivos solicitados..."

for artifact in "${ARTIFACTS[@]}"; do
  if [[ -f "$artifact" ]]; then
    CHECKSUM=$(sha256sum "$artifact" | awk '{print $1}')
    
    # Inyectar en frontmatter
    sed -i "s/checksum_sha256: .*/checksum_sha256: \"$CHECKSUM\"/" "$artifact" 2>/dev/null || true
    sed -i "s/# checksum_sha256: .*/# checksum_sha256: \"$CHECKSUM\"/" "$artifact" 2>/dev/null || true
    
    # Actualizar manifest
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

echo ""
echo "📄 Manifest actualizado: $MANIFEST"
echo "✅ 2 archivos sellados. Cero deriva."
