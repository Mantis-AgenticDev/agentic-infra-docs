# ---
# title: "Health Check Script"
# version: "1.0.0"
# constraints_mapped: ["C7", "C8"]
# validation_command: "./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/scripts/health-check.sh"
# canonical_path: "05-CONFIGURATIONS/scripts/health-check.sh"
#---
#!/bin/bash
set -euo pipefail

HEALTH_ENDPOINT="http://localhost:5000/health"

response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_ENDPOINT)

if [ "$response" -ne 200 ]; then
  echo "{\"tenant_id\": \"${TENANT_ID:?missing}\", \"trace_id\": \"$(uuidgen)\", \"severity\": \"ERROR\", \"message\": \"Health check failed with status code $response\"}" | jq .
  exit 1
fi

echo "{\"tenant_id\": \"${TENANT_ID:?missing}\", \"trace_id\": \"$(uuidgen)\", \"severity\": \"INFO\", \"message\": \"Health check passed\"}" | jq .
---
🟢 VALIDATION: ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/scripts/health-check.sh
---END-OF-FILE---
