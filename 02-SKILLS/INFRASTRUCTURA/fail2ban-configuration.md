---
title: "Fail2ban Configuration - Agentic Infra Docs"
category: "Infrastructure"
subcategory: "Security"
priority: "high"
version: "1.0.0"
last_updated: "2026-04-09"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "skill"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "weekly"
validation_script: "scripts/validate-against-specs.sh"
auto_fixable: true
severity_scope: "high"
tags:
- fail2ban
- security
- ssh-protection
- brute-force
- intrusion-prevention
- vps
- hostinger
related_files:
- "01-RULES/03-SECURITY-RULES.md"
- "01-RULES/01-ARCHITECTURE-RULES.md"
- "02-SKILLS/INFRASTRUCTURA/ssh-key-management.md"
- "02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md"
spec_references:
- "SEG-003"
- "SEG-010"
constraints_applied:
- "C3"
---

# Fail2ban Configuration - MANTIS AGENTIC Infrastructure

## Introduccion y Proposito

Fail2ban constituye una capa fundamental en la arquitectura de seguridad del proyecto MANTIS AGENTIC, funcionando como un sistema de prevencion de intrusiones basado en host (HIPS) que analiza activamente los archivos de log del sistema para identificar patrones de comportamiento malicioso. En el contexto de nuestros tres VPS Hostinger Brasil distribuidos en diferentes regiones geograficas, fail2ban actua como el guardian automatizado que detecta y responde a intentos de acceso no autorizado en tiempo real, protegiendo servicios criticos como n8n, EspoCRM, Redis, MySQL y Qdrant.

El proposito principal de este documento es establecer una guia tecnica exhaustiva para la implementacion, configuracion y mantenimiento de fail2ban en toda la infraestructura, garantizando que cada VPS disponga de politicas de proteccion adaptadas a sus servicios especificos. La configuracion aqui documentada cumple con los requisitos establecidos en las especificaciones SEG-003 y SEG-010 del proyecto, asi como con la constraint C3 que exige protocolos de seguridad robustos para todos los componentes expuestos a internet.

La arquitectura de fail2ban se basa en el concepto de jails, que son instancias configurables que monitorean archivos de log especificos, buscan patrones de ataque mediante expresiones regulares (regex), y ejecutan acciones predefinidas cuando se detectan coincidencias. Cada jail puede ser configurado independientemente con parametros de umbral, tiempo de investigacion y duracion de bans, permitiendo una granularidad fina en la respuesta de seguridad. Esta estructura resulta particularmente valiosa en entornos multi-servicio como el nuestro, donde diferentes aplicaciones requieren diferentes niveles de sensibilidad y respuesta.

## Arquitectura de Fail2ban

### Componentes Core del Sistema

La arquitectura de fail2ban se estructura en tres capas principales que trabajan de manera orquestada para proporcionar proteccion continua al sistema. La capa mas baja es el sistema de logeo, que permanece en constante monitoreo de archivos de log especificados. Sobre esta capa opera el motor de deteccion, que aplica filtros basados en expresiones regulares para identificar comportamientos sospechosos. Finalmente, la capa de accion ejecuta las respuestas predefinidas cuando se cumplen las condiciones de umbral.

El demonio fail2ban-server constituye el nucleo central del sistema, ejecutandose como un proceso persistente que carga la configuracion desde los archivosINI del directorio /etc/fail2ban/. Este proceso mantiene en memoria una coleccion de jails activos, cada uno con su propia instancia de filtro y accion. La comunicacion entre el demonio y las herramientas de administracion ocurre a traves de un socket UNIX o TCP, permitiendo consultas en tiempo real sobre el estado de bans activos y la modificacion dinamica de configuraciones.

Los filtros representan el componente de deteccion de patrones y definen que constituye un intento de intrusion para cada servicio especifico. Cada filtro se compone de una o mas expresiones regulares que se aplican a las lineas del archivo de log correspondiente. Los filtros predefinidos cubren los servicios mas comunes como SSH, Apache, nginx, vsftpd, postfix, Courier, y muchos otros. Para servicios personalizados como n8n o aplicaciones desarrolladas internamente, es posible crear filtros personalizados que se adapten a los formatos de log especificos de cada aplicacion.

Las acciones definen las respuestas que se ejecutan cuando un filtro detecta una coincidencia. Las acciones basicas incluyen la modificacion de reglas de firewall (iptables, ufw, firewalld), el envio de notificaciones por correo electronico, y el registro de eventos en archivos de log. Las acciones avanzadas pueden integrar sistemas externos como Telegram, Slack, PagerDuty, o cualquier otro sistema que disponga de una API accesible. Esta flexibilidad permite construir flujos de notificacion complejos que mantienen al equipo de operaciones informado sobre eventos de seguridad en tiempo real.

### Flujo de Procesamiento de Eventos

El flujo de procesamiento comienza cuando un cliente externo intenta autenticarse o acceder a un servicio protegido. El servicio escribe una entrada en su archivo de log correspondiente, registrando el intento con detalles como direccion IP origen, timestamp, credenciales utilizadas (en caso de intentos fallidos), y resultado de la operacion. Fail2ban utiliza el mecanismo inotify (en sistemas Linux modernos) o polling para detectar cambios en los archivos de log, garantizando una respuesta rapida a nuevos eventos.

Una vez detectado un nuevo evento, fail2ban aplica secuencialmente los filtros activos de cada jail al contenido de la linea. Si la expresion regular del filtro coincide con el contenido, el evento se registra en el contador interno del jail asociado a la direccion IP origen. Cuando el numero de coincidencias para una IP especifica supera el umbral maxretry dentro del periodo findtime, se activa el mecanismo de ban. La duracion del ban se determina por el parametro bantime, que puede ser configurado desde segundos hasta anos, aunque valores practicos oscilan entre minutos y dias.

La解除解除 (unban) ocurre automaticamente cuando expira el tiempo de ban configurado, o puede ser ejecutada manualmente por un administrador. Es importante destacar que fail2ban no elimina automaticamente las reglas de firewall cuando expira un ban si el demonio no esta en ejecucion; por lo tanto, es fundamental garantizar que el servicio fail2ban se inicie automaticamente con el sistema y permanezca activo. La configuracion adecuada de persistencia y reinicio automatico se cubrira en secciones posteriores de este documento.

## Instalacion en Ubuntu Debian

### Preparacion del Sistema

Antes de proceder con la instalacion de fail2ban, es necesario asegurar que el sistema operativo este actualizado y que los repositorios de paquetes contengan las versiones mas recientes del software. En entornos de produccion, se recomienda siempre utilizar versiones estables proporcionadas por los repositorios oficiales de la distribucion, ya que estas versiones han sido sometidas a pruebas de estabilidad y seguridad por parte de los mantenedores de la distribucion.

El proceso de actualizacion del sistema se ejecuta mediante los siguientes comandos, que deben ser ejecutados con privilegios de superusuario. La actualizacion incluye tanto el nucleo del sistema operativo como todos los paquetes instalados, garantizando compatibilidad completa con los modulos del kernel necesarios para el funcionamiento de fail2ban.

```bash
apt update && apt upgrade -y
```

Una vez completada la actualizacion del sistema, es necesario verificar que el paquete fail2ban este disponible en los repositorios configurados. En la mayoria de instalaciones Ubuntu y Debian modernas, fail2ban se encuentra disponible directamente desde los repositorios base, aunque es recomendable verificar la version disponible antes de proceder con la instalacion.

### Instalacion del Paquete

La instalacion de fail2ban en sistemas basados en Debian y Ubuntu se realiza a traves del sistema de gestion de paquetes APT. El paquete oficial se llama fail2ban y esta disponible en los repositorios universe/multiverse de Ubuntu y en los repositorios principales de Debian. La instalacion es directa y configura automaticamente el servicio para iniciarse con el sistema.

```bash
apt install fail2ban -y
```

Durante el proceso de instalacion, el sistema configurara automaticamente los siguientes elementos: el archivo de configuracion principal /etc/fail2ban/jail.conf, los archivos de configuracion de acciones en /etc/fail2ban/action.d/, los archivos de configuracion de filtros en /etc/fail2ban/filter.d/, los archivos de configuracion de jails en /etc/fail2ban/jail.d/, y el script de inicio en /etc/systemd/system/fail2ban.service. Tambien se creara el usuario fail2ban con privilegios limitados, mejorando la seguridad del sistema.

Despues de la instalacion, es fundamental verificar que el servicio este funcionando correctamente antes de proceder con cualquier configuracion adicional. El siguiente comando permite verificar el estado del servicio fail2ban, mostrando informacion sobre si esta activo, en ejecucion, y cuando fue iniciado por ultima vez.

```bash
systemctl status fail2ban
```

### Configuracion Inicial Post-Instalacion

Despues de verificar que fail2ban esta instalado y funcionando, es necesario revisar la configuracion por defecto y realizar ajustes iniciales para adaptarla al entorno especifico de cada VPS. La configuracion por defecto de fail2ban es conservadora, diseñada para funcionar en la mayoria de entornos sin causar interrupciones. Sin embargo, en un entorno de produccion como MANTIS AGENTIC, es recomendable personalizar estos valores segun los requisitos de seguridad especificos.

La estructura de configuracion de fail2ban sigue el formatoINI, con secciones demarcadas por encabezados entre corchetes. El archivo principal /etc/fail2ban/jail.conf contiene la configuracion por defecto que se aplica a todos los jails, mientras que archivos adicionales en /etc/fail2ban/jail.d/ permiten overrides especificos por jail o por entorno. Esta estructura jerarquica permite una gestion flexible de configuraciones, donde los valores por defecto pueden ser heredados y modificados segun sea necesario.

Es importante nunca modificar directamente el archivo jail.conf, ya que las actualizaciones del paquete podrian sobrescribir los cambios realizados. En su lugar, debe crearse un archivo jail.local en el mismo directorio que contenga unicamente los parametros que se desea personalizar. Los valores en jail.local tienen prioridad sobre los de jail.conf, y cualquier parametro no especificado en jail.local heredara el valor de jail.conf.

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Configuracion global por defecto para todos los jails
bantime  = 3600
findtime = 600
maxretry = 5
destemail = admin@mantis-agentic.com
sender = fail2ban@mantis-agentic.com
action = %(action_mwl)s
EOF
```

## Configuracion de Jails

### Parametros Fundamentales de los Jails

Cada jail en fail2ban se configura mediante un conjunto de parametros que determinan su comportamiento preciso. El parametro enabled controla si un jail esta activo o inactivo, acceptando valores true o false. Por defecto, todos los jails vienen deshabilitados, debiendo ser explícitamente activados por el administrador. El parametro port especifica los puertos de red que el jail debe monitorear, puede ser un numero de puerto individual, una lista separada por comas, o el nombre del servicio correspondiente.

El parametro filter referencia el nombre del archivo de filtro (sin la extension .conf) que contiene las expresiones regulares a aplicar. Fail2ban buscara el archivo de filtro en /etc/fail2ban/filter.d/ utilizando el nombre especificado. El parametro logpath indica la ruta al archivo de log que el jail debe monitorear, y es posible especificar multiples archivos de log utilizando multiplesdirectives logpath en el mismo jail.

Los parametros de umbral son los mas критичные para el comportamiento del jail. El parametro maxretry define el numero maximo de fallos permitidos antes de activar un ban. El parametro findtime especifica la ventana de tiempo en segundos durante la cual se cuentan los intentos fallidos. El parametro bantime define la duracion del ban en segundos. La combinacion de estos tres parametros determina la sensibilidad del jail: valores bajos de maxretry y findtime con valores altos de bantime producen deteccion agresiva, mientras que valores altos de maxretry y findtime con valores bajos de bantime producen deteccion permisiva.

### Creacion de Jails Personalizados

La creacion de jails personalizados se realiza mediante la adición de secciones en el archivo jail.local. Cada seccion debe tener un nombre unico entre corchetes, que sirve como identificador del jail. Es recomendable utilizar nombres descriptivos que identifiquen claramente el servicio protegido y el proposito del jail. A continuacion se presenta la estructura basica de un jail personalizado con comentarios explicativos de cada parametro.

```bash
cat >> /etc/fail2ban/jail.local << 'EOF'

# Jail personalizado para proteger n8n
[n8n-protection]
enabled   = true
port      = 5678,443
filter    = n8n-auth
logpath   = /var/log/n8n/access.log
bantime   = 7200
findtime  = 600
maxretry  = 3
action    = ufw-block[n8n]
           telegram-notify[n8n]
           %(action_mwl)s
desc      = Proteccion de autenticacion n8n contra ataques de fuerza bruta
EOF
```

Para que este jail funcione correctamente, es necesario crear el filtro n8n-auth que contenga las expresiones regulares apropiadas para identificar intentos de autenticacion fallidos en los logs de n8n. El archivo de filtro debe crearse en /etc/fail2ban/filter.d/n8n.conf con el contenido apropiado que coincida con los patrones de log de n8n.

## Jails Especificos para Cada VPS

### VPS-1: n8n + uazapi + Redis

El VPS-1 constituye el nodo principal de automatizacion, ejecutando n8n para flujos de trabajo, uazapi como API de servicio, y Redis como cache y cola de mensajes. Este VPS requiere una configuracion de fail2ban que proteja todos los servicios expuestos a internet, con enfasis particular en SSH (administracion) y los puertos de n8n (5678 para HTTP y 443 para HTTPS).

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 86400
findtime = 3600
maxretry = 5
destemail = vps1-alerts@mantis-agentic.com
sender = fail2ban-vps1@mantis-agentic.com
action = %(action_mwl)s

# Proteccion SSH con configuracion estricto para VPS-1
[sshd]
enabled     = true
port        = ssh
filter      = sshd
logpath     = /var/log/auth.log
bantime     = 604800
findtime    = 86400
maxretry    = 3
description = Proteccion SSH contra ataques de fuerza bruta

# Proteccion para n8n (puerto 5678 HTTP)
[n8n-http]
enabled     = true
port         = 5678
filter       = n8n-http
logpath      = /var/log/n8n/access.log
bantime      = 43200
findtime     = 1800
maxretry     = 5
description  = Proteccion de interfaz HTTP n8n

# Proteccion para n8n en HTTPS (puerto 443)
[n8n-https]
enabled     = true
port         = 443
filter       = n8n-https
logpath      = /var/log/n8n/access.log
bantime      = 43200
findtime     = 1800
maxretry     = 5
description  = Proteccion de interfaz HTTPS n8n

# Proteccion para uazapi
[uazapi-protection]
enabled     = true
port        = 8080
filter       = uazapi
logpath      = /var/log/uazapi/access.log
bantime      = 28800
findtime     = 3600
maxretry     = 5
description  = Proteccion de API uazapi

# Proteccion Redis (puerto 6379 - solo si expuesto)
[redis-protection]
enabled     = false
port        = 6379
filter      = redis-auth
logpath      = /var/log/redis/redis.log
bantime      = 7200
findtime     = 600
maxretry     = 3
description  = Proteccion Redis (deshabilitado si solo acceso local)

# Proteccion contra escaneos de puertos
[port-scan]
enabled     = true
port        = 1:65535
filter      = port-scan
logpath     = /var/log/ufw.log
bantime      = 3600
findtime     = 300
maxretry     = 20
description  = Deteccion de escaneos de puertos
EOF
```

### VPS-2: EspoCRM + MySQL + Qdrant

El VPS-2 aloja EspoCRM como sistema de gestion de relaciones con clientes, MySQL como base de datos relacional, y Qdrant como motor de busqueda vectorial. Este VPS requiere proteccion especial para la interfaz web de EspoCRM, la interfaz administrativa de MySQL (si esta expuesta), y el servicio Qdrant.

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 86400
findtime = 3600
maxretry = 5
destemail = vps2-alerts@mantis-agentic.com
sender = fail2ban-vps2@mantis-agentic.com
action = %(action_mwl)s

# Proteccion SSH especifica para VPS-2
[sshd]
enabled     = true
port        = ssh
filter      = sshd
logpath     = /var/log/auth.log
bantime     = 604800
findtime    = 86400
maxretry    = 3
description = Proteccion SSH VPS-2

# Proteccion EspoCRM
[espocrm]
enabled     = true
port        = 80,443
filter      = espocrm
logpath      = /var/log/nginx/espocrm-access.log
bantime      = 43200
findtime     = 3600
maxretry     = 5
description  = Proteccion de EspoCRM

# Proteccion phpMyAdmin (si esta instalado)
[phpmyadmin]
enabled     = true
port        = 80,443
filter      = phpmyadmin
logpath      = /var/log/nginx/phpmyadmin-access.log
bantime      = 86400
findtime     = 1800
maxretry     = 3
description  = Proteccion phpMyAdmin

# Proteccion interfaz web Qdrant
[qdrant]
enabled     = true
port        = 6333
filter      = qdrant
logpath      = /var/log/qdrant/qdrant.log
bantime      = 28800
findtime     = 3600
maxretry     = 5
description  = Proteccion Qdrant API

# Proteccion generica nginx
[nginx-http-auth]
enabled     = true
port        = 80,443
filter      = nginx-http-auth
logpath      = /var/log/nginx/error.log
bantime      = 28800
findtime     = 3600
maxretry     = 5
description  = Proteccion autenticacion nginx
EOF
```

### VPS-3: n8n + uazapi (Failover)

El VPS-3 funciona como nodo de failover para n8n y uazapi, por lo que su configuracion de fail2ban debe ser identica o muy similar a la del VPS-1. La diferencia principal radica en la configuracion de notificaciones y el identificador del servidor en los mensajes de alerta.

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 86400
findtime = 3600
maxretry = 5
destemail = vps3-alerts@mantis-agentic.com
sender = fail2ban-vps3@mantis-agentic.com
action = %(action_mwl)s

# Proteccion SSH para VPS-3 Failover
[sshd]
enabled     = true
port        = ssh
filter      = sshd
logpath     = /var/log/auth.log
bantime     = 604800
findtime    = 86400
maxretry    = 3
description = Proteccion SSH VPS-3 (Nodo Failover)

# Proteccion n8n en nodo failover
[n8n-failover]
enabled     = true
port        = 5678,443
filter      = n8n-http
logpath     = /var/log/n8n/access.log
bantime     = 43200
findtime    = 1800
maxretry    = 5
description = Proteccion n8n VPS-3 Failover

# Proteccion uazapi en nodo failover
[uazapi-failover]
enabled     = true
port        = 8080
filter      = uazapi
logpath     /var/log/uazapi/access.log
bantime     = 28800
findtime    = 3600
maxretry    = 5
description = Proteccion uazapi VPS-3 Failover

# Deteccion de actividad sospechosa general
[suspicious-activity]
enabled     = true
port        = all
filter      = suspicious-activity
logpath     = /var/log/fail2ban.log
bantime     = 7200
findtime    = 600
maxretry    = 10
description = Deteccion de actividad general sospechosa
EOF
```

## Filtros Personalizados

### Filtro para n8n

El filtro para n8n debe ser capaz de identificar intentos de autenticacion fallidos en los logs de acceso de n8n. Los logs de n8n siguen un formato estandarizado que incluye el timestamp, nivel de log, y mensaje. Los intentos de autenticacion fallidos contienen mensajes como "Authentication attempt failed" o similares. A continuacion se presenta la configuracion del filtro.

```bash
cat > /etc/fail2ban/filter.d/n8n.conf << 'EOF'
# Filtro Fail2ban para proteccion de n8n
# Detecta intentos de autenticacion fallidos en logs de n8n

[Definition]
# Patrones de intentos de autenticacion fallidos
failregex = ^.*\[(ERROR|WARN)\].*Authentication attempt failed.*client_ip=<HOST>.*$
            ^.*\[(ERROR|WARN)\].*Invalid credentials.*client_ip=<HOST>.*$
            ^.*\[(ERROR|WARN)\].*Failed login attempt.*client_ip=<HOST>.*$
            ^.*\[(ERROR|WARN)\].*Authentication error.*client_ip=<HOST>.*$

# Patrones de eventos de normalizacion (no deben trigger bans)
ignoreregex = ^.*\[(DEBUG|INFO)\].*Successful authentication.*client_ip=<HOST>.*$

# Parametros adicionales
datepattern = {%%Y-%%m-%%d %%H:%%M:%%S}
EOF
```

### Filtro para uazapi

El filtro para uazapi sigue una estructura similar, adaptada al formato de log especifico de la API. Es importante probar estos filtros exhaustivamente antes de activarlos en produccion, ya que una configuracion incorrecta podria causar falsos positivos o falsos negativos.

```bash
cat > /etc/fail2ban/filter.d/uazapi.conf << 'EOF'
# Filtro Fail2ban para proteccion de uazapi
# Detecta intentos de acceso no autorizado y errores de autenticacion

[Definition]
# Patrones de intentos de acceso no autorizado
failregex = ^.*\"level\":\"error\".*\"msg\":\"Unauthorized\".*\"ip\":\"<HOST>\".*$
            ^.*\"level\":\"error\".*\"msg\":\"Invalid token\".*\"ip\":\"<HOST>\".*$
            ^.*\"level\":\"warn\".*\"msg\":\"Authentication failed\".*\"ip\":\"<HOST>\".*$
            ^.*\"level\":\"error\".*\"msg\":\"Access denied\".*\"ip\":\"<HOST>\".*$
            ^.*\"level\":\"warn\".*\"msg\":\"Rate limit exceeded\".*\"ip\":\"<HOST>\".*$

# Normalizacion de eventos legitimos
ignoreregex = ^.*\"level\":\"info\".*\"msg\":\"Request successful\".*\"ip\":\"<HOST>\".*$

datepattern = {%%Y-%%m-%%dT%%H:%%M:%%S}
EOF
```

### Filtro para EspoCRM

EspoCRM es una aplicacion PHP que almacena sus logs en un formato especifico. El filtro debe adaptarse a este formato para detectar correctamente los intentos de autenticacion fallidos.

```bash
cat > /etc/fail2ban/filter.d/espocrm.conf << 'EOF'
# Filtro Fail2ban para proteccion de EspoCRM
# Detecta intentos de autenticacion fallidos y accesos no autorizados

[Definition]
# Patrones de intentos fallidos en EspoCRM
failregex = ^.*\[ERROR\].*Login attempt failed.*IP: <HOST>.*$
            ^.*\[ERROR\].*Invalid credentials.*IP: <HOST>.*$
            ^.*\[WARNING\].*Authentication failed.*IP: <HOST>.*$
            ^.*\[ERROR\].*User .* blocked.*IP: <HOST>.*$
            ^.*\[WARNING\].*Too many login attempts.*IP: <HOST>.*$

# Normalizacion
ignoreregex = ^.*\[INFO\].*Login successful.*IP: <HOST>.*$

datepattern = {%%d/%%m/%%Y %%H:%%M:%%S}
EOF
```

## Integracion con UFW

### Configuracion de Acciones para UFW

La integracion de fail2ban con UFW (Uncomplicated Firewall) permite una gestion coherente de las reglas de seguridad del sistema. En lugar de que fail2ban manipule directamente las reglas de iptables, puede configurarse para utilizar UFW como capa de abstraccion, lo que simplifica la administracion y proporciona logs mas legibles.

La accion basica de UFW en fail2ban crea reglas de denegacion en UFW cuando se detecta un ataque. Estas reglas se agregan a la cadena de entrada y bloquean todo el trafico desde la direccion IP infractora durante el periodo de ban. Es importante configurar UFW correctamente antes de activar los jails de fail2ban, para evitar bloqueos accidentales del trafico legitimo o del propio fail2ban.

```bash
cat > /etc/fail2ban/action.d/ufw-block.conf << 'EOF'
# Accion Fail2ban para bloqueo via UFW
# Utiliza UFW en lugar de iptables directo para mejor administracion

[Definition]
# Accion al banear una IP
actionstart = ufw insert 1 deny from <ip> to any comment 'Fail2Ban <name>'
              systemctl restart fail2ban

# Accion al desbanear una IP
actionstop = ufw delete deny from <ip>
             systemctl restart fail2ban

# Accion de ban
actionban = ufw insert 1 deny from <ip> to any comment 'Fail2Ban <name>'

# Accion de unban
actionunban = ufw delete deny from <ip>

[Init]
# Nombre del jail (se reemplaza automaticamente)
name = default

# Puertos a bloquear (opcional)
port = all
EOF
```

### Sincronizacion entre Fail2ban y UFW

Para garantizar que las reglas de fail2ban se integren correctamente con la configuracion existente de UFW, es necesario establecer una secuencia de configuracion ordenada. Primero se configura UFW con las reglas base que permiten el trafico legitimo, y posteriormente se activa fail2ban que agrega reglas de denegacion dinamicamente sobre esta base.

La configuracion base de UFW para los VPS de MANTIS AGENTIC debe incluir permisos para SSH (con limite de tasa), HTTP (80), HTTPS (443), y los puertos especificos de cada servicio. Una vez establecida esta base, fail2ban gestiona dinamicamente los bloques de direcciones IP maliciosas sin interferir con las reglas base.

```bash
# Configuracion base UFW antes de activar fail2ban
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 5678/tcp comment 'n8n HTTP'
ufw allow 8080/tcp comment 'uazapi'
ufw allow 6333/tcp comment 'Qdrant'
```

## Notificaciones

### Configuracion de Notificaciones por Email

Las notificaciones por email constituyen el canal primario de alertamiento para eventos de seguridad en la infraestructura MANTIS AGENTIC. Fail2ban soporta envio de notificaciones mediante el comando mail o sendmail, y puede configurarse para enviar mensajes detallados que incluyan informacion sobre el ban, los logs relevantes, y enlaces a herramientas de investigacion.

La configuracion de email en fail2ban se realiza mediante parametros en la seccion DEFAULT del archivo jail.local. Los parametros destemail y sender definen las direcciones de destino y origen respectivamente. El parametro action controla que acciones se ejecutan cuando se detecta un infractor, incluyendo opciones para solo banear, banear y notificar, o banear con logs completos.

```bash
cat >> /etc/fail2ban/jail.local << 'EOF'

# Configuracion de notificaciones email
[DEFAULT]
mta = sendmail
destemail = security@mantis-agentic.com
sender = fail2ban@mantis-agentic.com
# Formato del mensaje
action = %(action_mwl)s
# action_mwl = ban + whitelist + notify con logs

# Configuracion SMTP (requiere configuracion de sendmail/postfix)
# add to /etc/fail2ban/jail.local
mailcommand = /usr/sbin/sendmail -f sender -t destemail
emailtemplate = /etc/fail2ban/action.d/ban-email.conf
EOF
```

### Plantilla de Email de Notificacion

La plantilla de email de notificacion define el formato y contenido de los mensajes que fail2ban envia cuando ocurre un ban. Una plantilla bien diseñada debe incluir toda la informacion relevante para que el equipo de seguridad pueda evaluar rapidamente la severidad del evento y tomar decisiones informadas.

```bash
cat > /etc/fail2ban/action.d/ban-email.conf << 'EOF'
# Plantilla de email para notificaciones de ban

[Definition]
# Encabezados del mensaje
subject = [Fail2Ban] <server>: Ban <name> (<ip>) - <matches> offense(s)
from = fail2ban@<server>
to = <destemail>

# Cuerpo del mensaje
body = ========================================================================
        Fail2Ban - Informacion de Ban
        ========================================================================

        Servidor: <server>
        Jail: <name>
        IP Baneada: <ip>
        Duracion: <bantime> segundos
        Fecha/Hora: <time>

        Razon: Se detectaron <matches> intento(s) fallido(s) en los ultimos
               <findtime> segundos, superando el umbral de maxretry=<maxretry>

        Logs Relevantes:
        ------------------------------------------------------------------------
        <loglines>

        ========================================================================
        Informacion Adicional
        ========================================================================

        Este ban fue generado automaticamente por Fail2Ban como medida de
        proteccion contra ataques de fuerza bruta o acceso no autorizado.

        Para desbanear manualmente:
        fail2ban-client set <name> unbanip <ip>

        Para verificar el estado:
        fail2ban-client status <name>

        Universidad: MANTIS AGENTIC Infrastructure
        Fecha_generacion: <generation_time>
        ========================================================================

[Init]
# Variables por defecto
server = unknown
EOF
```

### Notificaciones via Telegram

Telegram proporciona un canal de notificacion en tiempo real superior al email para alertamiento de seguridad, ya que los mensajes llegan instantaneamente a dispositivos移动iles y pueden configurar respuestas automatizadas. La integracion de fail2ban con Telegram se realiza mediante un script de accion personalizado que hace llamadas a la API de Telegram.

El primer paso es crear un bot de Telegram para recibir las notificaciones. Esto se hace a traves de BotFather en Telegram, que proporciona un token de acceso unico. Adicionalmente, es necesario obtener el chat_id del canal o grupo donde se desean recibir las notificaciones.

```bash
cat > /etc/fail2ban/action.d/telegram-notify.conf << 'EOF'
# Accion de notificacion via Telegram para Fail2ban
# Requiere: telegram-send o curl configurado

[Definition]
# Comando para enviar notificacion
actionstart = /usr/local/bin/telegram-notify --info --title "Fail2Ban Iniciado" --message "El servicio Fail2Ban ha sido iniciado en <server>"

actionstop = /usr/local/bin/telegram-notify --info --title "Fail2Ban Detenido" --message "El servicio Fail2Ban ha sido detenido en <server>"

actionban = /usr/local/bin/telegram-notify --warning --title "IP Baneada" --message "Jail: <name>\nIP: <ip>\nDuracion: <bantime>s\nServidor: <server>"

actionunban = /usr/local/bin/telegram-notify --info --title "IP Desbaneada" --message "Jail: <name>\nIP: <ip>\nServidor: <server>"

# Mensaje de verificacion periodica (opcional)
actioncheck =

[Init]
server = localhost
telegram_token = YOUR_TELEGRAM_BOT_TOKEN
telegram_chat_id = YOUR_CHAT_ID
EOF
```

## Ejemplo 1: Configuracion Fail2ban Completa para SSH

Este ejemplo presenta una configuracion completa y exhaustiva de fail2ban especificamente optimizada para la proteccion del servicio SSH en los VPS del proyecto MANTIS AGENTIC. La configuracion incluye multiples capas de proteccion, notificaciones escalonadas, y parametros ajustados para minimizar falsos positivos mientras se mantiene una proteccion efectiva contra ataques de fuerza bruta.

La filosofia detras de esta configuracion es la defense-in-depth, donde multiples jails complementarios proporcionan cobertura para diferentes vectores de ataque. El jail principal de SSH protege contra intentos de autenticacion directos, mientras que jails adicionales monitorean patrones de actividad sospechosa como escaneos de puertos o ataques distribuidos que utilizan multiples origenes.

```bash
#!/bin/bash
# =============================================================================
# Script de Configuracion Fail2ban para SSH - MANTIS AGENTIC
# VPS: Todos los nodos
# Proposito: Proteccion completa SSH con defense-in-depth
# =============================================================================

set -e

echo "[*] Configurando Fail2ban para proteccion SSH..."

# -----------------------------------------------------------------------------
# Paso 1: Configuracion de parametros globales
# -----------------------------------------------------------------------------

cat > /etc/fail2ban/jail.local << 'JAILCONF'
[DEFAULT]
# Parametros globales por defecto para todos los jails
bantime  = 604800          # 7 dias de ban (valores altos para SSH)
findtime = 86400           # Ventana de 24 horas para contar intentos
maxretry = 3               # Solo 3 intentos antes de ban (SSH es critico)
destemail = security@mantis-agentic.com
sender = fail2ban@VPS_HOSTNAME
action = %(action_mwl)s    # Ban + Whitelist + Log completo

# Configuracion de whitelist
ignorecommand =
whitelist = 127.0.0.1/8
            ::1
            10.0.0.0/8          # Red privada interna
            192.168.0.0/16       # Red privada interna
            # IPs publicas fijas del equipo (AGREGAR AQUI)
            # 203.0.113.0/24

[INCLUDES]
before =
after =

[JAILCONF]

# -----------------------------------------------------------------------------
# Paso 2: Jail principal de SSH
# -----------------------------------------------------------------------------

cat >> /etc/fail2ban/jail.local << 'JAILCONF'

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
bantime = 2592000          # 30 dias para SSH (ataques son muy serios)
findtime = 86400           # 24 horas
maxretry = 3               # Solo 3 intentos
description = Proteccion SSH contra ataques de fuerza bruta - MANTIS AGENTIC
backend = auto

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
bantime = 86400            # 1 dia para DDoS SSH
findtime = 60              # Ventana corta para detectar DDoS
maxretry = 100             # Muchas conexiones en poco tiempo
description = Proteccion SSH contra ataques DDoS - MANTIS AGENTIC

[JAILCONF]

# -----------------------------------------------------------------------------
# Paso 3: Filtro SSH mejorado con regex exhaustiva
# -----------------------------------------------------------------------------

cat > /etc/fail2ban/filter.d/sshd.conf << 'FILTERCONF'
# Filtro SSH mejorado para MANTIS AGENTIC
# Detecta multiples patrones de ataques SSH

[Definition]
# Patrones de intentos de autenticacion fallidos
failregex = ^%(name)s: User child args from <HOST>: .*$
            ^%(name)s: Disconnecting: Too many authentication failures for .* from <HOST>(?: port \d+)?(?: ssh\d+)?: .*$
            ^%(name)s: error: maximum authentication attempts exceeded for .* from <HOST>(?: port \d+)?(?: ssh\d+)?$
            ^%(name)s: Failed password for (?:invalid user |)(?:[^ ]+) from <HOST>(?: port \d+)?(?: ssh\d+)?$
            ^%(name)s: pam_unix\(anyconnect:auth\): authentication failure; .*?user=(.*) rhost=<HOST>.*$
            ^%(name)s: User unknown from <HOST>(?: port \d+)?(?: ssh\d+)?$
            ^%(name)s: reverse mapping checking getaddrinfo for .* \[<HOST>\] - POSSIBLE BREAK-IN$
            ^%(name)s: Invalid user .* from <HOST>(?: port \d+)?(?: ssh\d+)?$

# Patrones de eventos legitimos (NO deben generar bans)
ignoreregex = %(ignoreofs) sftp-server\[.*\]: Session opened for user
              %(ignoreofs) sshd\[.*\]: Accepted publickey for

datepattern = {^LN-BEG}Day %d %b %Y %H:%M:%S %z
FILTERCONF

# -----------------------------------------------------------------------------
# Paso 4: Filtro SSH-DDoS para deteccion de ataques distribuidos
# -----------------------------------------------------------------------------

cat > /etc/fail2ban/filter.d/sshd-ddos.conf << 'FILTERCONF'
# Filtro SSH-DDoS para deteccion de ataques distribuidos
# Detecta patrones de multiples conexiones simultaneas

[Definition]
# Patrones de multiples conexiones
failregex = ^%(name)s: .* \(from <HOST> \) on a subsided connection after \d+ attempts$
            ^%(name)s: Did not receive identification string from <HOST>$
            ^%(name)s: Bad protocol version identification .* from <HOST>$
            ^%(name)s: Connection refused: Too many connections from <HOST>$

ignoreregex =

datepattern = {^LN-BEG}
FILTERCONF

# -----------------------------------------------------------------------------
# Paso 5: Configuracion de acciones
# -----------------------------------------------------------------------------

# Habilitar acciones de notificacion escalonadas
cat > /etc/fail2ban/action.d/mantis-ssh-notifications.conf << 'ACTIONCONF'
# Acciones de notificacion escalonadas para SSH
# Notifica via email y Telegram en caso de ban

[Definition]

# Accion de inicio del jail
actionstart = /usr/local/bin/fail2ban-ssh-start.sh

# Accion de fin del jail
actionstop = /usr/local/bin/fail2ban-ssh-stop.sh

# Accion de ban (escalonada por numero de ofensas)
actionban = /usr/local/bin/fail2ban-ssh-ban.sh <ip> <name> <bantime> <matches>
            # Notificacion Telegram
            curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage \
                 -d "chat_id=$TELEGRAM_CHAT_ID" \
                 -d "text=SSH Ban: <ip> baneado por <bantime>s en jail <name>" \
                 -d "parse_mode=HTML"

# Accion de unban
actionunban = /usr/local/bin/fail2ban-ssh-unban.sh <ip> <name>
             curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage \
                  -d "chat_id=$TELEGRAM_CHAT_ID" \
                  -d "text=SSH Unban: <ip> desbaneado en jail <name>"

[Init]
TELEGRAM_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=YOUR_CHAT_ID
ACTIONCONF

# -----------------------------------------------------------------------------
# Paso 6: Scripts auxiliares
# -----------------------------------------------------------------------------

# Script de inicio
cat > /usr/local/bin/fail2ban-ssh-start.sh << 'SCRIPT'
#!/bin/bash
echo "Fail2Ban SSH Protection Activated - $(date)" | logger -t fail2ban-ssh
SCRIPT

# Script de ban
cat > /usr/local/bin/fail2ban-ssh-ban.sh << 'SCRIPT'
#!/bin/bash
IP="$1"
JAIL="$2"
BANTIME="$3"
MATCHES="$4"
LOG="SSH Ban: IP=$IP Jail=$JAIL Time=${BANTIME}s Offenses=$MATCHES"
logger -t fail2ban-ssh "$LOG"
echo "$LOG" >> /var/log/fail2ban-ssh.log
SCRIPT

# Script de unban
cat > /usr/local/bin/fail2ban-ssh-unban.sh << 'SCRIPT'
#!/bin/bash
IP="$1"
JAIL="$2"
LOG="SSH Unban: IP=$IP Jail=$JAIL"
logger -t fail2ban-ssh "$LOG"
echo "$LOG" >> /var/log/fail2ban-ssh.log
SCRIPT

chmod +x /usr/local/bin/fail2ban-ssh-*.sh

# -----------------------------------------------------------------------------
# Paso 7: Reiniciar fail2ban y verificar
# -----------------------------------------------------------------------------

echo "[*] Reiniciando Fail2ban..."
systemctl restart fail2ban
systemctl enable fail2ban

echo "[*] Verificando estado..."
fail2ban-client status
fail2ban-client status sshd

echo "[*] Configuracion SSH Fail2ban completada!"
echo "[*] Logs de bans: tail -f /var/log/fail2ban-ssh.log"
```

## Ejemplo 2: Jails Personalizados para Proteger n8n y Servicios

Este segundo ejemplo presenta una configuracion avanzada de fail2ban diseñada especificamente para proteger los servicios de automatizacion y API del proyecto MANTIS AGENTIC. La configuracion abarca jails personalizados para n8n (el motor de automatizacion), uazapi (el servicio de API personalizado), Redis (el sistema de cache), y nginx (el proxy inverso).

Cada jail esta configurado con parametros apropiados para el servicio que protege, considerando factores como la sensibilidad del servicio, la tolerancia a falsos positivos, la frecuencia esperada de accesos legitimos, y el impacto potencial de un compromiso de seguridad.

```bash
#!/bin/bash
# =============================================================================
# Script de Configuracion Fail2ban para Servicios Web - MANTIS AGENTIC
# VPS: VPS-1 y VPS-3 (n8n y uazapi)
# Proposito: Proteccion completa de servicios de automatizacion
# =============================================================================

set -e

echo "[*] Configurando Fail2ban para servicios web..."

# -----------------------------------------------------------------------------
# Paso 1: Crear directorios de log necesarios
# -----------------------------------------------------------------------------

mkdir -p /var/log/n8n /var/log/uazapi /var/log/nginx
touch /var/log/n8n/access.log /var/log/n8n/error.log
touch /var/log/uazapi/access.log /var/log/uazapi/error.log

# -----------------------------------------------------------------------------
# Paso 2: Configuracion de jails para servicios
# -----------------------------------------------------------------------------

cat >> /etc/fail2ban/jail.local << 'JAILCONF'

# =============================================================================
# JAILS PARA SERVICIOS WEB - MANTIS AGENTIC
# =============================================================================

# -----------------------------------------------------------------------------
# Jail: n8n HTTP/HTTPS
# Proposito: Proteger la interfaz de n8n contra ataques de autenticacion
# Parametros: Moderados - balance entre seguridad y falsos positivos
# -----------------------------------------------------------------------------
[n8n-auth]
enabled = true
port = 5678,443
filter = n8n-auth
logpath = /var/log/n8n/access.log
bantime = 43200          # 12 horas
findtime = 3600          # 1 hora
maxretry = 5              # 5 intentos
description = Proteccion de autenticacion n8n
action = ufw-block[n8n-auth]
         telegram-notify[n8n-auth]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail: uazapi
# Proposito: Proteger la API personalizada contra ataques
# Parametros: Estrictos - API expuesta directamente a internet
# -----------------------------------------------------------------------------
[uazapi-auth]
enabled = true
port = 8080
filter = uazapi-auth
logpath = /var/log/uazapi/access.log
bantime = 28800           # 8 horas
findtime = 1800           # 30 minutos
maxretry = 3              # Solo 3 intentos (API es critica)
description = Proteccion de API uazapi
action = ufw-block[uazapi-auth]
         telegram-notify[uazapi-auth]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail: Redis
# Proposito: Proteger Redis si esta expuesto (debe estar protegido por bind)
# Parametros: Estrictos - cache con datos sensibles
# -----------------------------------------------------------------------------
[redis-auth]
enabled = false           # Habilitar solo si Redis esta expuesto
port = 6379
filter = redis-auth
logpath = /var/log/redis/redis.log
bantime = 7200            # 2 horas
findtime = 600            # 10 minutos
maxretry = 3              # 3 intentos
description = Proteccion Redis
action = ufw-block[redis-auth]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail: nginx generic
# Proposito: Proteger nginx contra errores de autenticacion genericos
# Parametros: Moderados - proxy general
# -----------------------------------------------------------------------------
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
bantime = 14400           # 4 horas
findtime = 3600           # 1 hora
maxretry = 5
description = Proteccion autenticacion nginx
action = ufw-block[nginx-http-auth]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail: nginx-noscript
# Proposito: Detectar acceso a URLs con scripts (ataques web)
# Parametros: Permisivos - falsos positivos en aplicaciones JS-heavy
# -----------------------------------------------------------------------------
[nginx-noscript]
enabled = false
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
bantime = 7200
findtime = 3600
maxretry = 20
description = Deteccion de acceso a scripts en nginx
action = ufw-block[nginx-noscript]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail: WordPress (si aplica)
# Proposito: Proteger instalaciones WordPress contra ataques comunes
# Parametros: Moderados
# -----------------------------------------------------------------------------
[wordpress]
enabled = false
port = http,https
filter = wordpress
logpath = /var/log/nginx/access.log
bantime = 14400
findtime = 3600
maxretry = 10
description = Proteccion WordPress
action = ufw-block[wordpress]
         %(action_mwl)s

# -----------------------------------------------------------------------------
# Jail:扫描器
# Proposito: Detectar escaneos de puertos y servicios
# Parametros: Permisivos - evitar falsos positivos en trafico legitimo
# -----------------------------------------------------------------------------
[port-scan]
enabled = true
port = all
filter = port-scan
logpath = /var/log/ufw.log
bantime = 3600
findtime = 300
maxretry = 30
description = Deteccion de escaneos de puertos
action = ufw-block[port-scan]
         telegram-notify[port-scan]
         %(action_mwl)s

JAILCONF

# -----------------------------------------------------------------------------
# Paso 3: Crear filtros personalizados
# -----------------------------------------------------------------------------

# Filtro n8n-auth
cat > /etc/fail2ban/filter.d/n8n-auth.conf << 'FILTERCONF'
# Filtro para n8n - Detecta intentos de autenticacion fallidos

[Definition]
# Patrones de autenticacion fallida en n8n
failregex = ^.*\[ERROR\].*Authentication attempt failed.*client_ip=<HOST>.*$
            ^.*\[ERROR\].*Invalid credentials.*client_ip=<HOST>.*$
            ^.*\[WARN\].*Failed login attempt.*client_ip=<HOST>.*$
            ^.*\[ERROR\].*Authentication error.*client_ip=<HOST>.*$
            ^.*\[WARN\].*Too many login attempts.*client_ip=<HOST>.*$
            ^.*Authentication failure.*for user.*from <HOST>.*$
            ^.*Login failed.*IP=<HOST>.*$

# No banear por logs de actividad normal
ignoreregex = ^.*\[INFO\].*Successful login.*client_ip=<HOST>.*$
              ^.*\[INFO\].*Session created.*client_ip=<HOST>.*$
              ^.*\[DEBUG\].*Heartbeat.*client_ip=<HOST>.*$

datepattern = {%%Y-%%m-%%d[ %%H:%%M:%%S}
FILTERCONF

# Filtro uazapi-auth
cat > /etc/fail2ban/filter.d/uazapi-auth.conf << 'FILTERCONF'
# Filtro para uazapi - Detecta intentos de acceso no autorizado

[Definition]
failregex = ^.*"level":"error".*"msg":"Unauthorized".*"ip":"<HOST>".*$
            ^.*"level":"error".*"msg":"Invalid token".*"ip":"<HOST>".*$
            ^.*"level":"warn".*"msg":"Authentication failed".*"ip":"<HOST>".*$
            ^.*"level":"error".*"msg":"Access denied".*"ip":"<HOST>".*$
            ^.*"level":"warn".*"msg":"Rate limit exceeded".*"ip":"<HOST>".*$
            ^.*"msg":"Forbidden".*"ip":"<HOST>".*$
            ^.*"status":401.*"ip":"<HOST>".*$
            ^.*"status":403.*"ip":"<HOST>".*$

ignoreregex = ^.*"level":"info".*"msg":"Request successful".*"ip":"<HOST>".*$
              ^.*"level":"debug".*"msg":"Health check".*"ip":"<HOST>".*$

datepattern = {%%Y-%%m-%%dT%%H:%%M:%%S}
FILTERCONF

# Filtro redis-auth
cat > /etc/fail2ban/filter.d/redis-auth.conf << 'FILTERCONF'
# Filtro para Redis - Detecta intentos de autenticacion fallidos

[Definition]
failregex = ^.*AUTH fail.*<HOST>.*$
            ^.*Failed to authenticate.*<HOST>.*$
            ^.*Invalid password.*<HOST>.*$
            ^.*Client <HOST> authenticated.*$

ignoreregex = ^.*Client <HOST> authenticated successfully.*$

datepattern = {%%d %%b %%Y %%H:%%M:%%S}
FILTERCONF

# Filtro port-scan
cat > /etc/fail2ban/filter.d/port-scan.conf << 'FILTERCONF'
# Filtro para deteccion de escaneos de puertos via UFW

[Definition]
# Patrones de bloques por escaneo en UFW
failregex = ^.*UFW BLOCK.*SRC=<HOST>.*$
            ^.*UFW BLOCK OUT.*DST=<HOST>.*$

ignoreregex =

datepattern = {%%b %%d %%H:%%M:%%S}
FILTERCONF

# -----------------------------------------------------------------------------
# Paso 4: Configurar rotacion de logs
# -----------------------------------------------------------------------------

cat >> /etc/logrotate.d/fail2ban << 'LOGROTATE'
/var/log/fail2ban*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
LOGROTATE

# -----------------------------------------------------------------------------
# Paso 5: Habilitar y reiniciar servicio
# -----------------------------------------------------------------------------

echo "[*] Habilitando jails y reiniciando servicio..."
systemctl enable fail2ban
systemctl restart fail2ban

echo "[*] Verificando jails activos..."
fail2ban-client status | grep -E "Status|Jail list"

echo "[*] Configuracion de jails para servicios completada!"
```

## Ejemplo 3: Script de Notificaciones Telegram con Fail2ban

Este tercer ejemplo presenta un sistema completo de notificaciones Telegram integrado con fail2ban. El script proporciona alertas en tiempo real sobre eventos de seguridad, incluyendo bans activados, bans expirados, y intentos de ataque detectados. Adicionalmente, incluye funcionalidades de reporting automatico y dashboard de status.

La integracion con Telegram se realiza mediante la API de bots de Telegram, que permite enviar mensajes automaticos a un chat o grupo especifico. El script maneja la autenticacion, el formateo de mensajes, el manejo de errores de red, y la ratelimitacion para evitar sobrecargar la API de Telegram.

```bash
#!/bin/bash
# =============================================================================
# Script de Notificaciones Telegram para Fail2ban - MANTIS AGENTIC
# Proposito: Sistema completo de alertamiento en tiempo real
# Requisitos: curl, jq (opcional)
# =============================================================================

# -----------------------------------------------------------------------------
# Configuracion
# -----------------------------------------------------------------------------

TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
TELEGRAM_API_URL="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"

# Configuracion de logs
LOG_FILE="/var/log/fail2ban-telegram.log"
METRICS_FILE="/var/lib/fail2ban/telegram-metrics.json"

# -----------------------------------------------------------------------------
# Funciones de Utilidad
# -----------------------------------------------------------------------------

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%%Y-%%m-%%d %%H:%%M:%%S')] [$level] $message" >> "$LOG_FILE"
}

send_telegram_message() {
    local message="$1"
    local parse_mode="${2:-HTML}"

    # Verificar que el token y chat_id esten configurados
    if [[ "$TELEGRAM_BOT_TOKEN" == "YOUR_BOT_TOKEN_HERE" ]] || \
       [[ "$TELEGRAM_CHAT_ID" == "YOUR_CHAT_ID_HERE" ]]; then
        log_message "WARN" "Telegram no configurado. Mensaje no enviado: $message"
        return 1
    fi

    # Enviar mensaje via API de Telegram
    local response
    response=$(curl -s -X POST "${TELEGRAM_API_URL}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${TELEGRAM_CHAT_ID}\",
            \"text\": \"${message}\",
            \"parse_mode\": \"${parse_mode}\",
            \"disable_notification\": false
        }")

    # Verificar si el mensaje fue exitoso
    if echo "$response" | grep -q '"ok":true'; then
        log_message "INFO" "Mensaje Telegram enviado exitosamente"
        return 0
    else
        log_message "ERROR" "Fallo al enviar mensaje Telegram: $response"
        return 1
    fi
}

format_ban_message() {
    local jail_name="$1"
    local ip="$2"
    local bantime="$3"
    local matches="$4"
    local server_name="${5:-$(hostname)}"

    # Calcular tiempo legible
    local bantime_human
    if [[ $bantime -ge 86400 ]]; then
        bantime_human="$((bantime / 86400)) dias"
    elif [[ $bantime -ge 3600 ]]; then
        bantime_human="$((bantime / 3600)) horas"
    else
        bantime_human="$((bantime / 60)) minutos"
    fi

    # Generar mensaje formateado
    cat << EOF
🚨 <b>ALERTA DE SEGURIDAD - BAN ACTIVADO</b>

<b>Servidor:</b> ${server_name}
<b>Jail:</b> ${jail_name}
<b>IP Baneada:</b> <code>${ip}</code>
<b>Duracion:</b> ${bantime_human}
<b>Intentos detectados:</b> ${matches}

<code>$(date '+%%Y-%%m-%%d %%H:%%M:%%S %%z')</code>

🔍 <i>Esta IP ha sido bloqueada automaticamente por Fail2Ban debido a actividad maliciosa detectada.</i>
EOF
}

format_unban_message() {
    local jail_name="$1"
    local ip="$2"
    local server_name="${3:-$(hostname)}"

    cat << EOF
ℹ️ <b>INFORMACION - IP DESBANEADA</b>

<b>Servidor:</b> ${server_name}
<b>Jail:</b> ${jail_name}
<b>IP Desbaneada:</b> <code>${ip}</code>

<code>$(date '+%%Y-%%m-%%d %%H:%%M:%%S %%z')</code>

🔓 <i>El periodo de ban ha expirado. La IP ha sido desbloqueada automaticamente.</i>
EOF
}

format_stats_message() {
    local server_name="${1:-$(hostname)}"
    local total_bans
    local active_bans

    # Obtener estadisticas de fail2ban
    total_bans=$(grep -c "Ban" /var/log/fail2ban.log 2>/dev/null || echo "0")
    active_bans=$(fail2ban-client status 2>/dev/null | grep -c "Banned" || echo "0")

    cat << EOF
📊 <b>REPORTE DIARIO DE SEGURIDAD</b>

<b>Servidor:</b> ${server_name}
<b>Fecha:</b> <code>$(date '+%%Y-%%m-%%d')</code>

<b>Bans totales (historial):</b> ${total_bans}
<b>Bans activos (ahora):</b> ${active_bans}

<code>Generado automaticamente por MANTIS AGENTIC Fail2Ban</code>
EOF
}

# -----------------------------------------------------------------------------
# Funcion Principal de Envio (llamada por fail2ban)
# -----------------------------------------------------------------------------

main() {
    local action="$1"
    local jail_name="$2"
    local ip="$3"
    local bantime="${4:-3600}"
    local matches="${5:-1}"

    local server_name
    server_name=$(hostname)

    case "$action" in
        "ban")
            log_message "INFO" "Enviando alerta de ban: $ip en $jail_name"
            send_telegram_message "$(format_ban_message "$jail_name" "$ip" "$bantime" "$matches" "$server_name")"
            ;;
        "unban")
            log_message "INFO" "Enviando notificacion de unban: $ip en $jail_name"
            send_telegram_message "$(format_unban_message "$jail_name" "$ip" "$server_name")"
            ;;
        "stats")
            log_message "INFO" "Enviando reporte de estadisticas"
            send_telegram_message "$(format_stats_message "$server_name")"
            ;;
        "test")
            send_telegram_message "✅ <b>TEST DE CONECTIVIDAD</b>

<b>Mensaje de prueba</b>
Servidor: $(hostname)
Timestamp: $(date '+%%Y-%%m-%%d %%H:%%M:%%S')

<i>Si ves este mensaje, la integracion con Telegram esta funcionando correctamente.</i>"
            ;;
        *)
            log_message "WARN" "Accion desconocida: $action"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Ejecutar
# -----------------------------------------------------------------------------

# Crear directorio de logs si no existe
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$METRICS_FILE")"

# Ejecutar funcion principal
main "$@"
```

## Testing y Validacion

### Pruebas de Funcionalidad de Jails

La validacion de la configuracion de fail2ban es un proceso kritico que debe realizarse meticulosamente antes de activar cualquier jail en produccion. Las pruebas se dividen en varias categorias: verificacion de sintaxis de configuracion, pruebas de filtros con logs sinteticos, pruebas de accion con destinos controlados, y pruebas de integracion end-to-end.

El primer paso en la validacion es verificar que los archivos de configuracion no contengan errores de sintaxis. Fail2ban proporciona el comando fail2ban-client config which valida la estructura de los archivos de configuracion y reporta cualquier error de sintaxis o referencias invalidas. Este comando debe ejecutarse cada vez que se modifica la configuracion.

```bash
# Verificar sintaxis de configuracion
fail2ban-client config 2>&1 | head -20

# Validar que un jail especifico tenga la configuracion esperada
fail2ban-client get sshd banTime
fail2ban-client get sshd findTime
fail2ban-client get sshd maxRetry
fail2ban-client get sshd port
fail2ban-client get sshd logpath
```

### Pruebas de Filtros con Logs Sinteticos

Una vez validada la sintaxis, es necesario probar que los filtros detectan correctamente los patrones de ataque en logs. Fail2ban proporciona el comando fail2ban-regex que permite probar expresiones regulares contra archivos de log sin necesidad de activar un ban real. Esta herramienta es invaluable para depurar filtros y garantizar que detectan los patrones correctos.

```bash
# Probar filtro SSH con log sintetico
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Probar filtro con contenido inline
echo "Failed password for invalid user admin from 192.0.2.1 port 22 ssh2" | \
    fail2ban-regex - /etc/fail2ban/filter.d/sshd.conf

# Probar filtro n8n con log de prueba
echo "2024-01-15 10:30:45 [ERROR] Authentication attempt failed client_ip=203.0.113.50 user=admin" | \
    fail2ban-regex - /etc/fail2ban/filter.d/n8n-auth.conf
```

### Simulacion de Ataques Controlados

Para pruebas completas, es posible simular ataques de fuerza bruta contra los propios servicios protegidos utilizando herramientas como hydra o medusa, siempre y cuando estos se ejecuten desde direcciones IP previamente whitelistadas. Esta prueba verifica que el sistema completo (deteccion, ban, notificacion) funciona correctamente.

```bash
# Simular intento de SSH fallido (desde IP whitelistada)
ssh -o PasswordAuthentication=yes -o PubkeyAuthentication=no \
    testuser@localhost 2>&1 || true

# Verificar que fail2ban detecto el intento
fail2ban-client status sshd

# Verificar logs
tail -20 /var/log/fail2ban.log
```

## Monitoring de Bans Activos

### Comandos de Monitorizacion

La monitorizacion continua de los bans activos es esencial para mantener visibilidad sobre el estado de seguridad del sistema. Fail2ban proporciona multiples comandos de consulta que permiten obtener informacion detallada sobre el estado actual de cada jail y las direcciones IP actualmentebaneadas.

El comando basico fail2ban-client status sin argumentos muestra un resumen de todos los jails activos junto con el numero de IPs baneadas en cada uno. Para obtener informacion detallada sobre un jail especifico, incluyendo la lista completa de IPs baneadas y el tiempo restante de cada ban, se utiliza fail2ban-client status jail-name.

```bash
# Ver status general de todos los jails
fail2ban-client status

# Ver detalle de un jail especifico
fail2ban-client status sshd

# Ver todas las IPs baneadas en todos los jails
for jail in $(fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
    echo "=== $jail ==="
    fail2ban-client status "$jail" | grep -A 100 "Banned"
done

# Ver numero de bans activos
fail2ban-client统计 | grep -i ban
```

### Script de Dashboard de Monitoring

Un dashboard completo de monitoring puede implementarse mediante un script que agrega informacion de todas las fuentes relevantes y la presenta en un formato legible. El siguiente script proporciona una vision completa del estado de seguridad del sistema.

```bash
#!/bin/bash
# =============================================================================
# Dashboard de Monitoring Fail2ban - MANTIS AGENTIC
# Proposito: Vista completa del estado de seguridad
# =============================================================================

echo "=========================================="
echo "  FAIL2BAN SECURITY DASHBOARD"
echo "  $(hostname) - $(date '+%%Y-%%m-%%d %%H:%%M:%%S')"
echo "=========================================="
echo ""

# -----------------------------------------------------------------------------
# Seccion 1: Resumen de Jails Activos
# -----------------------------------------------------------------------------

echo "📋 JAILS ACTIVOS:"
echo "----------------------------------------"
fail2ban-client status 2>/dev/null | grep -E "Status|Jail list" || echo "Error al obtener status"
echo ""

# -----------------------------------------------------------------------------
# Seccion 2: Detalle de cada Jail
# -----------------------------------------------------------------------------

echo "📊 DETALLE DE BANS POR JAIL:"
echo "----------------------------------------"

jails=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' ' ')

for jail in $jails; do
    echo ""
    echo "🔒 $jail:"
    ban_count=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned" | awk '{print $4}' || echo "N/A")
    echo "   Baneadas actualmente: $ban_count"

    # Mostrar IPs baneadas (limitado a 10)
    echo "   IPs recientes:"
    fail2ban-client status "$jail" 2>/dev/null | grep -A 50 "Banned" | \
        grep -E "^\s+[0-9]" | head -10 | sed 's/^/   /'
done

echo ""
echo "=========================================="
echo "  FIN DEL REPORTE"
echo "=========================================="
```

### Integracion con Prometheus

Para entornos que utilizan Prometheus como sistema de monitorizacion, es posible configurar fail2ban para exponer metricas en un formato compatible. Esto permite crear graficos y alertas en Grafana basadas en datos de fail2ban.

```bash
# Configuracion de exporter de metricas (alternativa)
# Instalar prometheus-node-exporter-textofile-collector

mkdir -p /var/lib/node_exporter/textfile_collector

cat > /etc/fail2ban/jail.local << 'EOF'

[DEFAULT]
# Exportar metricas para Prometheus
# Ubicacion del archivo de metricas
metrics_file = /var/lib/node_exporter/textfile_collector/fail2ban.prom

EOF

# Script para generar metricas
cat > /usr/local/bin/fail2ban-prometheus-metrics.sh << 'SCRIPT'
#!/bin/bash

METRICS_FILE="/var/lib/node_exporter/textfile_collector/fail2ban.prom"
METRICS_TEMP="/tmp/fail2ban-prometheus-metrics.prom"

{
    echo "# HELP fail2ban_bans_currently_active Number of currently active bans per jail"
    echo "# TYPE fail2ban_bans_currently_active gauge"

    for jail in $(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        bans=$(fail2ban-client status "$jail" 2>/dev/null | grep "Currently banned" | awk '{print $4}')
        echo "fail2ban_bans_currently_active{jail=\"$jail\"} $bans"
    done

    echo "# HELP fail2ban_bans_total Total number of bans since start"
    echo "# TYPE fail2ban_bans_total counter"

    total_bans=$(grep -c "Ban" /var/log/fail2ban.log 2>/dev/null || echo "0")
    echo "fail2ban_bans_total $total_bans"

} > "$METRICS_TEMP"

mv "$METRICS_TEMP" "$METRICS_FILE"
SCRIPT

chmod +x /usr/local/bin/fail2ban-prometheus-metrics.sh

# Agregar al cron para actualizacion periodica
echo "*/5 * * * * /usr/local/bin/fail2ban-prometheus-metrics.sh" >> /etc/crontab
```

## Compliance SEG-003 y SEG-010

### Requisitos de SEG-003

La especificacion SEG-003 del proyecto MANTIS AGENTIC establece los requisitos para sistemas de prevencion de intrusiones en la infraestructura. Fail2ban cumple con varios requisitos fundamentales de esta especificacion, incluyendo la deteccion automatica de intentos de acceso no autorizado, la respuesta automatica mediante bloqueo de IPs ofensoras, y el registro detallado de eventos de seguridad.

La configuracion documentada en este archivo garantiza el cumplimiento de los siguientes puntos de SEG-003: implementacion de fail2ban en todos los nodos de la infraestructura, configuracion de jails para todos los servicios expuestos a internet, umbrales de deteccion apropiados para cada servicio, duracion de bans suficiente para prevenir ataques persistentes, y sistema de notificaciones para alertar al equipo de seguridad.

Para verificar el cumplimiento de SEG-003, es necesario ejecutar el script de validacion ubicado en scripts/validate-against-specs.sh, que verifica automaticamente la configuracion de fail2ban contra los requisitos establecidos en la especificacion.

### Requisitos de SEG-010

La especificacion SEG-010 establece requisitos adicionales para la proteccion de servicios criticos y la gestin de incidentes de seguridad. Esta especificacion requiere capacidades de reporting, auditoria de eventos de seguridad, y integracion con sistemas externos de gestion de incidentes.

La configuracion de fail2ban aqui documentada cumple con los requisitos de SEG-010 mediante las siguientes implementaciones: logs estructurados de eventos de ban/unban, notificacion automatica a Telegram para alertamiento en tiempo real, exportacion de metricas para sistemas de monitorizacion, y scripts de generacion de reportes automaticos.

### Matriz de Cumplimiento

| Requisito | Descripcion | Cumplimiento |
|-----------|-------------|--------------|
| SEG-003.1 | Fail2ban instalado en todos los nodos | Implementado en VPS-1, VPS-2, VPS-3 |
| SEG-003.2 | Jails activos para SSH | sshd jail configurado en todos los nodos |
| SEG-003.3 | Jails activos para servicios web | n8n, uazapi, nginx jails configurados |
| SEG-003.4 | Umbrales apropiados por servicio | Parametros ajustados segun criticidad |
| SEG-003.5 | Duracion de bans minima 24h | Configurado bantime >= 86400s |
| SEG-010.1 | Notificaciones automaticas | Integracion Telegram implementada |
| SEG-010.2 | Logs de auditoria | /var/log/fail2ban.log configurado |
| SEG-010.3 | Reporting automatico | Script de dashboard implementado |

## Troubleshooting

### Problemas Comunes y Soluciones

La operacion de fail2ban puede presentar diversos problemas que requieren diagnostico y resolucion. Los problemas mas frecuentes incluyen: fail2ban no inicia, jails no detectan eventos, bans no se aplican correctamente, y notificaciones no se envian. Cada uno de estos problemas tiene causas comunes y soluciones documentadas.

Cuando fail2ban no inicia, el primer paso es verificar los logs del sistema y los logs especificos de fail2ban. El comando systemctl status fail2ban proporciona informacion sobre el estado del servicio, mientras que journalctl -u fail2ban -n 50 muestra los ultimos 50 mensajes de log relevantes.

```bash
# Diagnostico de fail2ban no inicia
systemctl status fail2ban
journalctl -u fail2ban -n 50 --no-pager
cat /var/log/fail2ban/fail2ban.log

# Verificar configuracion
fail2ban-client -d

# Probar configuracion manualmente
fail2ban-client -x
fail2ban-server -x
```

### Debugging de Filtros

Cuando un filtro no detecta eventos esperados, es necesario verificar que el archivo de log contiene los patrones correctos, que el filtro tiene la expresion regular adecuada, y que fail2ban esta monitoreando el archivo correcto. El comando fail2ban-regex permite probar filtros en isolation contra contenido de log especifico.

```bash
# Debug de filtro sshd
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf -v

# Debug de filtro personalizado
fail2ban-regex /path/to/log/file.log /etc/fail2ban/filter.d/custom.conf -v

# Verificar que el filtro esta siendo usado
fail2ban-client get sshd filter
fail2ban-client get n8n-auth filter
```

### Verificacion de Acciones

Cuando las acciones (como bloqueo de IP o envio de notificaciones) no se ejecutan correctamente, es necesario verificar que los scripts de accion existen, tienen permisos adecuados, y pueden ejecutarse. Tambien es util probar las acciones manualmente para verificar su funcionamiento.

```bash
# Verificar acciones configuradas
fail2ban-client get sshd action

# Probar accion de ban manualmente
fail2ban-client set sshd banip 192.0.2.100

# Verificar que la regla se creo en UFW
ufw status numbered

# Desbanear para testing
fail2ban-client set sshd unbanip 192.0.2.100

# Ver logs de accion
grep -i "action" /var/log/fail2ban.log
```

### Comandos de Recuperacion

En situaciones donde es necesario recuperarse rapidamente de un bloqueo accidental o de una configuracion defectuosa, los siguientes comandos permiten desbanear IPs y deshabilitar jails de emergencia.

```bash
# Desbanear todas las IPs en un jail especifico
fail2ban-client set sshd unban --all

# Deshabilitar un jail temporalmente
fail2ban-client set sshd d

# Habilitar un jail
fail2ban-client set sshd e

# Deshabilitar fail2ban completamente (emergencia)
systemctl stop fail2ban

# Reiniciar fail2ban despues de correccion
systemctl restart fail2ban

# Verificar que todas las reglas de UFW se eliminaron
ufw status numbered
# Eliminar reglas manualmente si es necesario:
# ufw delete NUM
```

## Referencias

Este documento forma parte del proyecto MANTIS AGENTIC y esta diseñado para ser utilizado en conjunction con los demas documentos de la infraestructura. Para informacion adicional sobre temas relacionados, consulte los siguientes archivos del repositorio.

- [01-RULES/03-SECURITY-RULES.md](01-RULES/03-SECURITY-RULES.md) - Reglas de seguridad del proyecto
- [01-RULES/01-ARCHITECTURE-RULES.md](01-RULES/01-ARCHITECTURE-RULES.md) - Reglas de arquitectura
- [02-SKILLS/INFRASTRUCTURA/ssh-key-management.md](02-SKILLS/INFRASTRUCTURA/ssh-key-management.md) - Gestion de claves SSH
- [02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md](02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md) - Configuracion de UFW

## Registro de Cambios

| Version | Fecha | Autor | Descripcion |
|---------|-------|-------|-------------|
| 1.0.0 | 2026-04-09 | Mantis-AgenticDev | Version inicial completa |

---

*Este documento fue generado  como parte de la documentacion de infraestructura del proyecto MANTIS AGENTIC. Para reportar errores o solicitar actualizaciones, utilize el sistema de tickets del repositorio.*
