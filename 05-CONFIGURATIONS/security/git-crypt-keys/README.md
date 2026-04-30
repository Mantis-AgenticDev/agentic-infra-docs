---
artifact_id: security-git-crypt-keys-readme-mantis
artifact_type: security_documentation
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C3","C4","C5","C6"]
canonical_path: 05-CONFIGURATIONS/security/git-crypt-keys/README.md
domain: 05-CONFIGURATIONS
subdomain: security
agent_role: configurations-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain configurations --strict
tier: 2
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "devops_ops", "security_ops"]
human_readable: false
checksum_sha256: "ddfbf456ac467c73fdd1859b912bca7e701d4b1305b3839e780c778a86789520"
---

# 🔐 GUÍA DE GESTIÓN DE CLAVES: `git-crypt` (MANTIS v2.0.0)

## 1. Propósito y Alcance
- **Objetivo**: Documentar el flujo seguro de cifrado de archivos sensibles (`.env.*`, `*.tfvars`, `secrets/`) usando `git-crypt`, garantizando trazabilidad (C4), mínimos privilegios (C5) y control de acceso explícito (C6).
- **Regla C3 Absoluta**: NUNCA commitear claves simétricas o GPG públicas/privadas en el repositorio. Este directorio solo contiene documentación y reglas de atributo.

## 2. Inicialización y Configuración de Repositorio
```bash
# 1. Instalar git-crypt (Debian/Ubuntu)
sudo apt install git-crypt

# 2. Inicializar cifrado en la raíz del repo (solo primera vez)
cd <repo_root>
git-crypt init

# 3. Definir qué archivos se cifran automáticamente
cat >> .gitattributes <<'EOF'
# C3: Encriptación automática de secrets y configs sensibles
05-CONFIGURATIONS/environment/.env.* filter=git-crypt diff=git-crypt
05-CONFIGURATIONS/terraform/envs/*/terraform.tfvars filter=git-crypt diff=git-crypt
05-CONFIGURATIONS/docker-compose/secrets/* filter=git-crypt diff=git-crypt
*.key filter=git-crypt diff=git-crypt
*.pem filter=git-crypt diff=git-crypt
EOF

git add .gitattributes
git commit -m "chore: git-crypt initialization + attribute rules (C3)"
```

## 3. Exportación y Distribución Segura de Claves
```bash
# Exportar clave simétrica para compartir con colaboradores/CI
git-crypt export-key ./05-CONFIGURATIONS/security/git-crypt-keys/mantis-crypt-key.key

# C3/C6: NUNCA commitear este archivo. Eliminarlo de la raíz tras compartirlo.
rm -f mantis-crypt-key.key

# Compartir vía canal seguro:
# - HashiCorp Vault (path: secret/data/mantis/devops/git-crypt-key)
# - AWS KMS + S3 presigned URL con expiración 1h
# - Transferencia física cifrada (GPG) o hardware token
```

## 4. Flujo de Colaboración y Acceso (C5, C6)
| Rol | Permisos `git-crypt` | Proceso de Acceso |
|-----|----------------------|-------------------|
| `dev` | Lectura/Commit archivos encriptados | Recibe clave vía Vault. Ejecuta `git-crypt unlock <ruta>` |
| `sre/ops` | Lectura/Escritura + CI/CD | Clave inyectada como `GIT_CRYPT_KEY` en pipeline. Auto-unlock en checkout |
| `auditor` | Solo lectura metadata | No requiere `git-crypt`. Usa `git log --patch` (sin desencriptar) |
| `security` | Rotación/Revocación | `git-crypt add-gpg-user` / `git-crypt rm-gpg-user` + rotación de clave simétrica |

## 5. Rotación y Revocación (C6)
```bash
# 1. Agregar nuevo colaborador GPG
git-crypt add-gpg-user <fingerprint>

# 2. Rotar clave simétrica (obligatorio cada 90d o tras offboarding)
git-crypt export-key ./new-mantis-key.key
# Distribuir nueva clave de forma segura
# Actualizar CI/CD secrets con nueva clave
# Revocar acceso antiguo:
git-crypt rm-gpg-user <fingerprint>
git commit -m "security: rotate git-crypt keys & revoke access"
```

## 6. Anti-Patrones (C3, C5, C6)
- ❌ **NUNCA**: `git add 05-CONFIGURATIONS/security/git-crypt-keys/*.key` (viola C3 críticamente)
- ❌ **NUNCA**: Usar `git-crypt init` en ramas feature y mergear sin sincronizar claves (causa conflictos de decrypt)
- ❌ **NUNCA**: Compartir claves por Slack, email o tickets sin cifrado adicional (viola C6)
- ❌ **NUNCA**: Confiar en `.gitignore` para proteger secrets sin `git-crypt` (git history es inmutable)
- ✅ **SIEMPRE**: Verificar estado con `git-crypt status` pre-push
- ✅ **SIEMPRE**: Auditar acceso con `git log --grep="git-crypt"` trimestralmente

## 7. Comandos de Validación
```bash
# Verificar archivos cifrados en staging area
git-crypt status -f
# Validar que .gitattributes aplica correctamente
git check-attr filter 05-CONFIGURATIONS/environment/.env.dev
# Esperado: 05-CONFIGURATIONS/environment/.env.dev: filter: git-crypt
```

---
