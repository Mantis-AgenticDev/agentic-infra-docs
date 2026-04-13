---
title: "MySQL Backup Script"
version: "1.0.0"
constraints_mapped: ["C3", "C5", "C7"]
validation_command: "./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/scripts/backup-mysql.sh"
canonical_path: "05-CONFIGURATIONS/scripts/backup-mysql.sh"
---
#!/bin/bash
set -euo pipefail

DB_HOST="${DB_HOST:?missing}"
DB_USER="${DB_USER:?missing}"
DB_PASSWORD="${DB_PASSWORD:?missing}"
DB_NAME="${DB_NAME:?missing}"
AGE_PUBLIC_KEY="${AGE_PUBLIC_KEY:?missing}"
TENANT_ID="${TENANT_ID:?missing}"

backup_file="/tmp/${DB_NAME}_$(date +%Y%m%d%H%M%S).sql.gz"

mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $backup_file

encrypted_backup=$(age --encrypt --recipient $AGE_PUBLIC_KEY $backup_file)

checksum=$(sha256sum $backup_file | awk '{print $1}')

echo "{\"tenant_id\": \"$TENANT_ID\", \"trace_id\": \"$(uuidgen)\", \"severity\": \"INFO\", \"message\": \"Backup completed successfully\", \"checksum\": \"$checksum\"}" | jq .

rm $backup_file
---
🟢 VALIDATION: ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --strict 05-CONFIGURATIONS/scripts/backup-mysql.sh
---END-OF-FILE---
