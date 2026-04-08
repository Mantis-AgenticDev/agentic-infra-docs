---
title: "SECURITY RULES - Agentic Infra Docs"
category: "Seguridad"
priority: "Alta"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "rules"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "daily"
validation_script: "scripts/validate-security.sh"
auto_fixable: true
severity_scope: "critical"
rules_count: 10
tags:
  - security
  - firewall
  - ssh
  - fail2ban
  - secrets
related_files:
  - "01-ARCHITECTURE-RULES.md"
  - "05-CONFIGURATIONS/scripts/"
  - "07-PROCEDURES/vps-initial-setup.md"
---

# SECURITY RULES

## Metadatos del Documento

- **Categoría:** Seguridad
- **Prioridad de carga:** Alta
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 01-ARCHITECTURE-RULES.md

---

## Regla SEG-001: Firewall UFW Obligatorio

**Descripción:** Todos los VPS deben tener UFW configurado y activo.

**Reglas obligatorias por VPS:**

| Puerto | Servicio | Acceso             | VPS 1 | VPS 2 | VPS 3 |
|--------|----------|--------------------|-------|-------|-------|
| 22     | SSH      | Solo IPs conocidas | Sí    | Sí    | Sí    |
| 80     | HTTP     | Público            | Sí    | Sí    | Sí    |
| 443    | HTTPS    | Público            | Sí    | Sí    | Sí    |
| 3306   | MySQL    | Solo VPS 1 y 3     | No    | Sí    | No    |
| 6333   | Qdrant   | Solo VPS 1 y 3     | No    | Sí    | No    |
| 5678   | n8n      | Localhost          | Sí    | No    | Sí    |
| 8080   | uazapi   | Localhost          | Sí    | No    | Sí    |

**Comando default:**
```bash
ufw default deny incoming
ufw default allow outgoing
```
**Violación crítica:** Puerto 3306 o 6333 abierto a 0.0.0.0.

---

## Regla SEG-002: Autenticación SSH Solo Claves

**Descripción:** SSH debe usar solo autenticación por claves, sin password.

**Configuración obligatoria en /etc/ssh/sshd_config:**
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password

**Violación crítica:** PasswordAuthentication yes.

---

## Regla SEG-003: fail2ban Obligatorio

**Descripción:** fail2ban debe estar instalado y activo en todos los VPS.

**Configuración mínima:**

|Parámetro	 | Valor  	| Justificación                 |
|------------|----------|-------------------------------|
|maxretry	   | 5	      | Intentos antes de ban         |
|findtime	   | 600	    | Ventana de tiempo (segundos)  |
|bantime	   | 3600	    | Tiempo de ban (segundos)      |

**Jails obligatorios:**

sshd
nginx-repeat-offender (si aplica)

**Violación crítica:** fail2ban no instalado o inactivo.

---

## Regla SEG-004: Secretos en Variables de Entorno

**Descripción:** Nunca exponer secretos en código o logs.

**Requisitos obligatorios:**

- API keys en archivos .env (nunca en código)
- .env nunca commiteado a Git
- Secrets en n8n usando credenciales nativas
- Logs nunca imprimen tokens o API keys

**Violación crítica:** API key hardcodeada en archivo .js o .py.


### Template de Archivo .env (NUNCA COMMITEAR A GIT)

```bash
# .env para VPS-1 (n8n, uazapi)

# n8n
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=${GENERAR_PASSWORD}
EXECUTIONS_PROCESS=main
EXECUTIONS_MAX_CONCURRENT=5
WEBHOOK_TIMEOUT=30000

# OpenRouter
OPENROUTER_API_KEY=sk-or-v1-XXXXXXXXXXXXXXXXXXXXXXXX

# Qdrant Cloud
QDRANT_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXX
QDRANT_URL=https://XXXXXXXX.XXX-XXXX.XXX.qdrant.io

# MySQL (VPS-2)
MYSQL_ROOT_PASSWORD=${GENERAR_PASSWORD}
MYSQL_DATABASE=espocrm
MYSQL_USER=espocrm
MYSQL_PASSWORD=${GENERAR_PASSWORD}

# Telegram Bot (alertas)
TELEGRAM_BOT_TOKEN=XXXXXXXXX:XXXXXXXXXXXXXXXXXXXXXXXX
TELEGRAM_CHAT_ID=-XXXXXXXXXX

# UAZAPI
UAZAPI_URL=http://localhost:8080
UAZAPI_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXX
```
**Comandos útiles:**
```bash
# Generar password seguro
openssl rand -base64 32

# Verificar que .env no está en git
git check-ignore .env
```
**Violación crítica:** Archivo .env commiteado a Git.

---

## Regla SEG-005: Backups Encriptados

**Descripción:** Todos los backups deben estar encriptados con contraseña.

**Requisitos obligatorios:**

Encriptación:   AES-256 mínimo
Contraseña:     32 caracteres mínimo, almacenada en gestor de passwords
Verificación:   Checksum SHA256 de cada backup

**Comando ejemplo:**

tar czf - backup/ | openssl enc -aes-256-cbc -salt -out backup.tar.gz.enc


### Encriptación de Backups (SEG-005)

**Comando obligatorio para backup MySQL:**
```bash
mysqldump -u root --all-databases | \
  gzip | \
  openssl enc -aes-256-cbc -salt -pbkdf2 -out backup-$(date +%F).tar.gz.enc
  ```

---

## Regla SEG-006: tenant_id Validado en Cada Consulta

**Descripción:** Multi-tenencia requiere validación estricta de tenant_id.

**Requisitos obligatorios:**

- Cada consulta SQL debe incluir WHERE tenant_id = ?
- Cada búsqueda en Qdrant debe incluir filtro por tenant_id
- Log de acceso por tenant para auditoría
- Nunca exponer datos de un cliente a otro

**Violación crítica:** Consulta SQL sin filtro tenant_id.

---

## Regla SEG-007: Índices de Base de Datos para Seguridad

**Descripción:** Índices obligatorios para consultas seguras y rápidas.

**Índices mínimos requeridos:**

```sql
CREATE INDEX idx_mensajes_tenant_fecha ON mensajes(tenant_id, fecha);
CREATE INDEX idx_clientes_telefono ON clientes(telefono);
CREATE INDEX idx_clientes_tenant ON clientes(tenant_id);
```
---

## Regla SEG-008: Keepalive SSH Configurado

**Descripción:** SSH debe tener keepalive para evitar conexiones huérfanas.

**Configuración obligatoria en /etc/ssh/sshd_config:**

ClientAliveInterval 60
ClientAliveCountMax 3

**Justificación:** Cierra conexiones inactivas después de 3 minutos.

---

## Regla SEG-009: Root Login Deshabilitado

**Descripción:** Root login directo debe estar deshabilitado cuando sea posible.

**Configuración recomendada:**

PermitRootLogin no

**Excepción:** PermitRootLogin prohibit-password si se requiere acceso root emergencial.

---

## Regla SEG-010: Auditoría de Logs Obligatória

**Descripción:** Todos los accesos deben ser logueados para auditoría.

**Logs obligatorios:**

- /var/log/auth.log (accesos SSH)
- /var/log/ufw.log (firewall)
- /var/log/fail2ban.log (bans)
- n8n execution logs (por tenant)

**Retención:** 90 días mínimo.

---

## Checklist de Validación de Seguridad

- [ ] UFW activo y configurado en todos los VPS
- [ ] SSH solo con claves (sin password)
- [ ] fail2ban instalado y activo
- [ ] .env nunca commiteado a Git
- [ ] Backups encriptados con AES-256
- [ ] tenant_id validado en cada consulta
- [ ] Índices de base de datos creados
- [ ] Keepalive SSH configurado
- [ ] Root login deshabilitado o restringido
- [ ] Logs de auditoría activos

---

## Matriz de Puertos por VPS

|Puerto	 | Servicio	 | VPS 1	| VPS 2	    | VPS 3	| Público            |
|--------|-----------|--------|-----------|-------|--------------------|
|22	     | SSH	     | Sí	    | Sí	      | Sí	  | No (IPs conocidas) | 
|80	     | HTTP	     | Sí	    | Sí	      | Sí	  | Sí                 |
|443	   | HTTPS	   | Sí	    | Sí	      | Sí	  | Sí                 |
|3306	   | MySQL	   | No	    | Sí	      | No	  | No                 |
|6333	   | Qdrant	   | No	    | Sí	      | No	  | No                 |
|5678	   | n8n	     | Sí	    | No	      | Sí    | No                 |
|8080	   | uazapi	   | Sí	    | No	      |Sí	    | No                 |

Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev
Licencia: Creative Commons para uso interno del proyecto




## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/01-ARCHITECTURE-RULES.md]]
[[01-RULES/02-RESOURCE-GUARDRAILS.md]]
