---
title: "EspoCRM Setup and Integration - Agentic Infra Docs"
category: "Infrastructure"
subcategory: "CRM"
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
auto_fixable: false
severity_scope: "high"
tags:
- espocrm
- crm
- vps
- hostinger
- mysql
- api
- integration
- docker
- multi-tenant
related_files:
- "01-RULES/01-ARCHITECTURE-RULES.md"
- "01-RULES/06-MULTITENANCY-RULES.md"
- "02-SKILLS/INFRASTRUCTURA/mysql-qdrant-setup.md"
- "02-SKILLS/INFRASTRUCTURA/docker-compose-networking.md"
spec_references:
- "ARQ-001"
- "MT-009"
constraints_applied:
- "C4"
---

# EspoCRM Setup and Integration

## 1. Introduccion y Proposito

Este documento constituye la especificacion tecnica completa para la instalacion, configuracion y operacion de EspoCRM dentro de la infraestructura MANTIS AGENTIC. El proposito fundamental es establecer un sistema de gestion de relaciones con clientes (CRM) robusto, escalable y correctamente integrado con el ecosistema de servicios que conforman la arquitectura del proyecto.

EspoCRM fue seleccionado como la solucion CRM para este proyecto debido a su naturaleza de codigo abierto, su arquitectura REST API bien diseñada, su capacidad de personalizacion mediante modules y su compatibilidad nativa con entornos Docker. La implementacion de EspoCRM en VPS-2 cumple un rol critical dentro de la arquitectura general, actuando como el nucleo central para la gestion de leads, contactos, cuentas y oportunidades de negocio para todos los tenants definidos en el sistema multi-tenant.

La documentacion que aqui se presenta abarca desde la preparacion del entorno Docker Compose hasta la configuracion avanzada de webhooks para integracion con n8n, pasando por la implementacion de politicas de multi-tenancy que aseguran el aislamiento completo de datos entre los diferentes tenants operativos. Cada seccion ha sido diseñada para proporcionar contexto suficiente a sistemas de inteligencia artificial que interpreten esta documentacion, permitiendo la generacion automatica de codigo, la validacion de configuraciones existentes y la identificacion proactiva de desviaciones respecto a las especificaciones arquitecturales ARQ-001 y MT-009.

Es importante destacar que toda la configuracion aqui documentada ha sido diseñada considerando las constraints del proyecto, particularmente la constraint C4 que establece los mecanismos de aislamiento y identificacion de tenants mediante el campo tenant_id. Esta constraint permea toda la arquitectura de EspoCRM, desde la configuracion de equipos y permisos hasta la estructura de la base de datos MySQL subyacente.

## 2. EspoCRM Overview

### 2.1 Arquitectura General de EspoCRM

EspoCRM es una aplicacion web de gestion de relaciones con clientes construida sobre PHP y Backbone.js, diseñada con una arquitectura cliente-servidor que separa claramente la capa de presentacion de la logica de negocio. La aplicacion utiliza una base de datos MySQL como repositorio principal para el almacenamiento de todos los datos relacionales, incluyendo cuentas, contactos, leads, oportunidades, casos y cualquier entidad personalizada que se defina mediante el sistema de administracion de entidades.

La arquitectura de EspoCRM se caracteriza por ser extremadamente modular, permitiendo la extension de funcionalidades mediante plugins personalizados que pueden agregar nuevas entidades, campos, flujos de trabajo y integraciones. Esta modularidad es particularmente util en contextos multi-tenant donde cada tenant puede requerir personalizaciones especificas que no son relevantes para otros tenants del sistema.

Desde la perspectiva de la infraestructura, EspoCRM se estructura en tres capas principales. La capa de datos esta compuesta por MySQL, que almacena todos los registros de forma estructurada y permite la implementacion de constraints a nivel de base de datos para garantizar la integridad referencial. La capa de aplicacion corre en PHP y contiene toda la logica de negocio, los endpoints de la API REST, el sistema de autenticacion y autorizacion, y la gestion de sesiones de usuario. Finalmente, la capa de presentacion esta construida sobre Backbone.js y Handlebars, proporcionando una interfaz de usuario dinamica que se comunica con el backend exclusivamente a traves de la API REST.

### 2.2 Capacidades de API REST

EspoCRM expone una API REST completa que permite la integracion con sistemas externos de manera programmatic a. La API soporta todas las operaciones CRUD (Create, Read, Update, Delete) para cada entidad del sistema, ademas de operaciones especificas como la conversion de leads a contactos, la actualizacion masiva de registros y la ejecucion de acciones personalizadas definidas por el usuario.

La autenticacion en la API de EspoCRM se realiza mediante tokens de acceso, los cuales se generan a nivel de usuario y estan asociados a permisos especificos. Cada token tiene una duracion configurable y puede ser revocado individualmente, lo cual proporciona un mecanismo de control de acceso granular. Para entornos de integracion con sistemas automatizados como n8n, es recomendable crear usuarios API dedicados que tengan permisos exclusivamente sobre las operaciones requeridas.

El formato de comunicacion con la API es JSON, tanto para las solicitudes como para las respuestas. La API soporta paginacion mediante parametros de consulta, filtros avanzados mediante una sintaxis de query builder, y ordenamiento mediante parametros de sorting. La documentacion de la API de EspoCRM esta disponible en su sitio oficial y describe exhaustivamente cada endpoint disponible, los parametros soportados y los formatos de respuesta esperados.

### 2.3 Modelo de Datos Fundamental

El modelo de datos de EspoCRM esta organizado en entidades core que forman la base del sistema y entidades personalizadas que pueden ser creadas mediante la interfaz de administracion. Las entidades core incluyen Account (cuentas empresariales), Contact (contactos individuales), Lead (prospectos), Opportunity (oportunidades de venta), Case (casos de soporte), Task (tareas), Meeting (reuniones), Call (llamadas), Email (correos electronicos) y Document (documentos).

Cada entidad en EspoCRM tiene un conjunto de campos estandares que incluyen id (identificador unico), name (nombre principal), deleted (soft delete flag), createdAt (timestamp de creacion), modifiedAt (timestamp de modificacion) y createdBy (usuario creador). Adicionalmente, cada entidad puede tener campos personalizados definidos por el administrador del sistema, los cuales se almacenan en columnas con el prefijo cw_ en la base de datos.

Las relaciones entre entidades se manejan mediante un sistema de enlaces directos (direct links) y enlaces many-to-many. Los enlaces directos establecen una relacion padre-hijo donde cada hijo tiene exactamente un padre, mientras que los enlaces many-to-many permiten relaciones bidireccionales multiples. Por ejemplo, un Contact puede estar vinculado a multiples Account mediante relaciones many-to-many, y una Opportunity esta vinculada directamente a una Account especifica.

## 3. Docker Compose Setup

### 3.1 Configuracion del Contenedor EspoCRM

La instalacion de EspoCRM mediante Docker Compose es el metodo recomendado para entornos de produccion que requieren escalabilidad y facilidad de gestion. La siguiente configuracion establece un contenedor EspoCRM completamente funcional, conectado a una red Docker definida y configurado para persistir todos los datos importantes en volumenes externos.

```yaml
version: '3.8'

services:
  espocrm:
    image: espocrm/espocrm:latest
    container_name: mantis-espocrm
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - ESPOCRM_SITE_URL=https://crm.mantis-agentic.internal
      - ESPOCRM_ADMIN_USERNAME=admin
      - ESPOCRM_ADMIN_EMAIL=${ESPOCRM_ADMIN_EMAIL}
      - ESPOCRM_ADMIN_PASSWORD=${ESPOCRM_ADMIN_PASSWORD}
      - ESPOCRM_DATABASE_HOST=mysql-espocrm
      - ESPOCRM_DATABASE_PORT=3306
      - ESPOCRM_DATABASE_NAME=espocrm_${TENANT_ID}
      - ESPOCRM_DATABASE_USERNAME=${ESPOCRM_DB_USER}
      - ESPOCRM_DATABASE_PASSWORD=${ESPOCRM_DB_PASSWORD}
      - ESPOCRM_CONFIG_CACHE_LIFETIME=3600
      - ESPOCRM_USE_HTTPS=false
      - PHP_MEMORY_LIMIT=256M
      - PHP_MAX_EXECUTION_TIME=300
      - PHP_UPLOAD_MAX_FILESIZE=50M
    volumes:
      - espocrm-data:/var/www/html
      - espocrm-custom:/var/www/html/custom
      - espocrm-logs:/var/www/html/data/logs
      - /var/www/html/vendor
    networks:
      - mantis-backend
    depends_on:
      mysql-espocrm:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/api/v1/app-info"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s

  mysql-espocrm:
    image: mysql:8.0
    container_name: mantis-mysql-espocrm
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=espocrm_main
      - MYSQL_USER=${ESPOCRM_DB_USER}
      - MYSQL_PASSWORD=${ESPOCRM_DB_PASSWORD}
      - MYSQL_COLLATION_SERVER=utf8mb4_unicode_ci
      - MYSQL_CHARACTER_SET_SERVER=utf8mb4
    volumes:
      - mysql-espocrm-data:/var/lib/mysql
      - mysql-espocrm-logs:/var/log/mysql
    networks:
      - mantis-backend
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    command: --default-authentication-plugin=mysql_native_password
             --character-set-server=utf8mb4
             --collation-server=utf8mb4_unicode_ci
             --max_connections=500
             --innodb_buffer_pool_size=512M

volumes:
  espocrm-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /docker/volumes/espocrm/data
  espocrm-custom:
    driver: local
    driver_opts:
      type: none
      type: bind
      device: /docker/volumes/espocrm/custom
  espocrm-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /docker/volumes/espocrm/logs
  mysql-espocrm-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /docker/volumes/mysql-espocrm/data
  mysql-espocrm-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /docker/volumes/mysql-espocrm/logs

networks:
  mantis-backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

### 3.2 Variables de Entorno Requeridas

El archivo Docker Compose anterior hace uso intensivo de variables de entorno para la configuracion dinamica de los servicios. Estas variables deben ser definidas en un archivo .env en el mismo directorio que el docker-compose.yml, o bien gestionadas por un sistema de gestion de secretos como Docker Secrets o un gestor de contraseñas externo.

Las variables de entorno criticas para la operacion de EspoCRM incluyen las credenciales del administrador de EspoCRM, las cuales seran utilizadas para crear la cuenta administrativa inicial durante el primer arranque del contenedor. Es imperativo que estas credenciales sean fuertes y unicas, y que sean almacenadas de forma segura. Las variables ESPOCRM_ADMIN_EMAIL y ESPOCRM_ADMIN_PASSWORD definen las credenciales del primer usuario administrador del sistema. La variable ESPOCRM_SITE_URL debe contener la URL completa incluyendo el protocolo (https o http) a la cual los usuarios accederan a la interfaz de EspoCRM.

Desde la perspectiva de la base de datos, las variables MYSQL_ROOT_PASSWORD, ESPOCRM_DB_USER y ESPOCRM_DB_PASSWORD definen las credenciales de acceso a MySQL. El usuario de base de datos de EspocRM debe tener privilegios exclusivos sobre la base de datos espocrm, nunca privilegios de root. Adicionalmente, se recomienda que la base de datos MySQL este configurada con el juego de caracteres UTF8MB4 para soportar correctamente todos los caracteres internacionales.

### 3.3 Configuracion de Redes Docker

La configuracion de redes en Docker Compose define como los contenedores se comunican entre si y con el mundo exterior. En el ejemplo anterior, se ha definido una red bridge personalizada llamada mantis-backend con el rango de subred 172.28.0.0/16. Esta subred privada esta reservada para la comunicacion interna entre servicios y no es accesible desde el exterior directamente.

Los puertos expuestos son 8080 para EspoCRM (mapeado al puerto 80 del contenedor) y 3307 para MySQL (mapeado al puerto 3306 del contenedor). Esta configuracion permite acceder a EspoCRM desde el host mediante http://localhost:8080, mientras que MySQL queda accesible desde otros contenedores en la misma red mediante el nombre mysql-espocrm:3306 y desde el host mediante localhost:3307.

Para la integracion con n8n en otros VPS, es necesario configurar un proxy reverso que exponga EspoCRM a traves de la red publica. Esto se logra mediante la definicion de un servicio nginx adicional en el docker-compose que actué como proxy reverso, terminates la conexion SSL y redirija el trafico al contenedor EspoCRM interno. La configuracion del proxy reverso debe incluir certificados SSL validos y politicas de seguridad apropiadas para proteger la API de EspoCRM contra accesos no autorizados.

## 4. Database Connection

### 4.1 Configuracion de MySQL para EspoCRM

La conexion entre EspoCRM y MySQL es un componente critical de la infraestructura. MySQL 8.0 es la version recomendada debido a sus mejoras en rendimiento, seguridad y soporte para juegos de caracteres completos. La configuracion de MySQL debe optimizarse para la carga de trabajo especifica de un CRM, que se caracteriza por muchas operaciones de lectura, escrituras ocasionales intensivas y consultas complejas sobre tablas con relaciones multiple.

La configuracion del motor InnoDB en MySQL 8.0 debe incluir un tamano de buffer pool apropiado para el conjunto de datos esperado. Para un CRM con datos moderados, se recomienda configurar innodb_buffer_pool_size a aproximadamente el 70% de la memoria RAM disponible del contenedor MySQL. En el ejemplo de configuracion anterior, se ha establecido un buffer pool de 512MB, lo cual es adecuado para entornos de desarrollo y pequeno escala. Para entornos de produccion con mayor volumen de datos, este valor debe incrementarse proporcionalmente.

El juego de caracteres UTF8MB4 es obligatorio para EspoCRM, ya que la aplicacion almacena y procesa texto en multiples idiomas y necesita soportar emojis y otros caracteres especiales que no estan incluidos en el juego de caracteres UTF8 de 3 bytes. La configuracion de colacion debe ser utf8mb4_unicode_ci para обеспечить comparaciones de texto correctas y ordenamiento alfabetico preciso en todos los idiomas soportados.

### 4.2 Estructura de Base de Datos por Tenant

Conforme a la constraint C4 del proyecto, cada tenant en el sistema multi-tenant de MANTIS AGENTIC debe tener su propia base de datos EspoCRM aislada. Esto se implementa mediante la convencion de nomenclatura espocrm_${tenant_id}, donde tenant_id es un identificador unico para cada tenant en el sistema.

Esta estrategia de aislamiento a nivel de base de datos proporciona el maximo nivel de separacion entre tenants, eliminando cualquier posibilidad de fuga de datos entre ellos incluso en escenarios de falla de configuracion. Cada base de datos tiene su propio conjunto de tablas, indices y Constraints, y los usuarios de base de datos de cada tenant tienen privilegios exclusivamente sobre su base de datos asignada.

La creacion de bases de datos por tenant debe automatizarse mediante scripts que se ejecuten durante el proceso de provisionamiento de nuevos tenants. El script debe crear la base de datos con el juego de caracteres correcto, crear el usuario de base de datos con permisos exclusivos, y ejecutar cualquier script de inicializacion necesario para EspoCRM. Es importante que estos scripts sean idempotentes, es decir, que puedan ejecutarse multiples veces sin efectos adversos si la base de datos ya existe.

### 4.3 Tablas Principales de EspoCRM

El esquema de base de datos de EspoCRM consiste en aproximadamente 80 tablas core que almacenan la informacion del sistema. Las tablas mas importantes desde la perspectiva de la integracion y operacion incluyen las siguientes.

La tabla account almacena las cuentas empresariales y contiene campos como name, website, industry, employees, annual_revenue, address_street, address_city, address_state, address_country, address_postal_code, billing_address_street, billing_address_city, billing_address_state, billing_address_country, billing_address_postal_code, shipping_address_street, shipping_address_city, shipping_address_state, shipping_address_country y shipping_address_postal_code. Esta tabla tiene relaciones con las tablas contact, opportunity, case y document.

La tabla contact almacena los contactos individuales y esta relacionada con accounts mediante una relacion many-to-many. Los campos principales incluyen first_name, last_name, email_address, phone_number, title, department, do_not_call, notes, address_street, address_city, address_state, address_country y address_postal_code. La tabla de vinculacion account_contact maneja la relacion many-to-many entre contactos y cuentas.

La tabla lead almacena los prospectos que aun no han sido convertidos en contactos o cuentas. Los campos incluyen name, email_address, phone_number, company_name, title, lead_source, lead_status, converted_account_id, converted_contact_id y converted_opportunity_id. Una vez que un lead es convertido, estos campos converted_* se.populan con referencias a las entidades creadas a partir del lead.

La tabla opportunity almacena las oportunidades de venta y contiene campos como name, amount, close_date, stage, probability, account_id, contact_id, campaign_id, description y next_step. La tabla opportunity_stage define los etapas personalizadas del pipeline de ventas, y cada etapa tiene un nombre, probabilidad de cierre y orden.

## 5. Initial Configuration

### 5.1 Configuracion Post-Instalacion

Una vez que EspoCRM ha sido instalado y el contenedor esta funcionando correctamente, es necesario realizar una serie de configuraciones iniciales para optimizar el sistema para el entorno de produccion. Estas configuraciones se realizan a traves de la interfaz de administracion accesible en /admin.

La primera tarea de configuracion post-instalacion es verificar y ajustar la configuracion del sitio. Esto incluye establecer la URL base correcta del sitio, configurar el timezone predeterminado para el servidor, ajustar los ajustes de sesion y configurar las opciones de correo electronico para el envio de notificaciones y emails transaccionales. Es importante que la configuracion de timezone sea consistente entre EspoCRM, MySQL y el sistema operativo del contenedor para evitar problemas de sincronizacion en las marcas de tiempo.

La segunda tarea critical es la configuracion del sistema de notificaciones. EspoCRM puede enviar notificaciones por email para diversos eventos del sistema, incluyendo asignacion de registros, actualizacion de oportunidades, nuevos mensajes y recordatorios de tareas. La configuracion del servidor SMTP debe incluir el host, puerto, credenciales de autenticacion y el protocolo de seguridad (TLS o SSL). Se recomienda utilizar un servicio de correo transaccional como SendGrid, Mailgun o Amazon SES para entornos de produccion.

### 5.2 Configuracion de Entidades y Campos

EspoCRM permite la personalizacion extensiva de sus entidades mediante la interfaz de administracion. Para cada entidad, es posible agregar campos personalizados, modificar las relaciones existentes, definir validaciones personalizadas y ajustar el comportamiento del panneau de detalle.

Los campos personalizados en EspoCRM se crean mediante la interfaz de administracion y se almacenan en columnas con el prefijo cw_ en la base de datos. Los tipos de campos disponibles incluyen texto (varchar, text), numeros (int, float, currency), fechas (date, datetime, time), booleanos, enumeraciones, multi-enumeraciones, referencias a otras entidades (link, multi-link), archivos y URLs.

Para la implementacion multi-tenant, es critico que todos los campos personalizados que contengan informacion especifica del tenant incluyan el tenant_id como parte de su identificacion. Esto facilita la separacion de datos durante las consultas y la generacion de reportes por tenant. Se recomienda establecer convenciones de nomenclatura consistentes, como prefijos o sufijos que identifiquen claramente la pertenencia de cada campo personalizado a un tenant especifico.

### 5.3 Configuracion de Moneda y Formatos Regionales

Para entornos multi-tenant que sirven a clientes en diferentes regiones geograficas, EspoCRM permite configurar formatos regionales y monedas por separado. Esta configuracion afecta la presentacion de fechas, numeros, monedas y direcciones en toda la interfaz del usuario.

La configuracion de moneda incluye el simbolo de la moneda, el codigo ISO, el formato de presentacion (simbolo antes o despues del monto) y el numero de decimales. Para el proyecto MANTIS AGENTIC, se recomienda mantener una configuracion base en USD o EUR y permitir que cada tenant personalice estos ajustes segun sus necesidades.

Los formatos de fecha y hora son configurables independientemente del timezone del servidor. Esto permite que usuarios en diferentes zonas horarias vean las fechas y horas en su zona horaria local, mientras que el servidor almacena todo en UTC. Esta分离 es importante para aplicaciones multi-tenant que sirven a usuarios distribuidos globalmente.

## 6. API Setup

### 6.1 Habilitacion y Configuracion de la API REST

La API REST de EspoCRM debe ser habilitada explicitamente antes de poder utilizarla para integraciones. Esta configuracion se realiza en la seccion Administration > Integration > API de la interfaz de administracion de EspoCRM.

Al habilitar la API, EspoCRM genera un par de credenciales consistente en un API Key y un API Secret. El API Key acts as the username and is visible in the interface, while the API Secret acts as the password and is shown only once at creation time. It is critical to store the API Secret securely as it cannot be retrieved later; if lost, a new pair of credentials must be generated.

La API de EspoCRM utiliza autenticacion mediante firma HMAC para las solicitudes. El proceso de autenticacion requiere que el cliente genere una firma usando el API Secret, incluir esta firma en la cabecera de la solicitud junto con el API Key y un timestamp. Este mecanismo proporciona un nivel de seguridad significativamente mayor que la autenticacion basica por token.

### 6.2 Endpoints Principales de la API

La API REST de EspoCRM expone endpoints para todas las entidades del sistema. Los endpoints siguen una convencion RESTful donde cada entidad tiene su propio conjunto de endpoints para operaciones CRUD basicas y operaciones especificas adicionales.

El endpoint GET /api/v1/Account devuelve una lista de cuentas con soporte para paginacion, filtrado y ordenamiento. Los parametros de query permiten especificar filtros complejos, como account.name='Acme*' AND account.industry='Technology', ordenamiento por multiples campos, y paginacion con limites y offsets. El endpoint POST /api/v1/Account crea una nueva cuenta con los datos proporcionados en el cuerpo de la solicitud en formato JSON.

El endpoint GET /api/v1/Account/{id} devuelve los detalles de una cuenta especifica identificada por su ID unico. Este endpoint es particularmente util para integraciones que necesitan acceder a informacion detallada de una cuenta especifica, incluyendo todas sus relaciones con contactos, oportunidades y casos activos.

Los endpoints POST /api/v1/Lead/{id}/convert procesan la conversion de un lead en Contact, Account y Opportunity segun los parametros proporcionados. Este es uno de los endpoints mas complejos de la API, ya que requiere especificar que entidades crear y como mapear los datos del lead a las nuevas entidades.

### 6.3 Gestion de Errores y Codigos de Respuesta

La API de EspoCRM utiliza codigos de estado HTTP estandar para indicar el resultado de cada solicitud. Los codigos 200-299 indican exitos, los codigos 400-499 indican errores del cliente (como parametros invalidos o recursos no encontrados), y los codigos 500-599 indican errores del servidor.

Los errores se devuelven en formato JSON con una estructura consistente que incluye el codigo de error, un mensaje descriptivo y detalles adicionales cuando estan disponibles. Por ejemplo, un error de validacion devolveria codigo 400 con un objeto que lista los campos que fallaron la validacion y las razones especificas de cada fallo.

Para aplicaciones de integracion, es crucial implementar manejo de errores robusto que incluya reintentos automaticos para errores transitorios (como timeouts o errores 503), circuit breakers para errores persistentes, y logging detallado de todos los errores para facilitar el diagnostico de problemas.

## 7. Multi-Tenant Configuration (Constraint C4)

### 7.1 Arquitectura de Multi-Tenancy en EspoCRM

La constraint C4 del proyecto MANTIS AGENTIC establece que todos los sistemas deben implementar multi-tenancy mediante el campo tenant_id, garantizando el aislamiento completo de datos entre tenants. EspoCRM no tiene built-in multi-tenancy, por lo que la implementacion de esta constraint requiere una estrategia de aislamiento a nivel de base de datos.

La estrategia elegida para este proyecto consiste en utilizar una base de datos separada por tenant. Cada tenant tiene su propio esquema de base de datos EspoCRM completo, incluyendo todas las tablas, indices y datos. Esta aproximacion proporciona el maximo nivel de aislamiento y simplifica las operaciones de backup y restauracion por tenant, aunque requiere mayor overhead de administracion.

El campo tenant_id se incorpora en EspoCRM mediante campos personalizados en las entidades que requieren aislamiento. Todos los campos que contienen informacion sensible de un tenant incluyen el tenant_id como referencia, y las consultas de la API automaticamente filtran por el tenant_id del usuario autenticado. Esto se implementa mediante un interceptor a nivel de aplicacion que inyecta automaticamente el filtro de tenant en todas las consultas.

### 7.2 Configuracion de Equipos por Tenant

EspoCRM tiene un sistema de equipos (Teams) que permite organizar usuarios y asignar permisos a nivel de equipo. Este sistema se aprovecha para implementar la separacion logica de tenants dentro de cada base de datos EspoCRM.

Para cada tenant, se crea un equipo principal con el nombre del tenant y se configuran equipos adicionales segun la estructura organizacional interna del tenant. Por ejemplo, un tenant podria tener equipos como Sales, Support, y Management como subequipos del equipo principal del tenant.

Los permisos de acceso a registros se configuran a nivel de equipo. Cada registro en EspoCRM puede tener permisos de lectura, escritura y eliminacion configurados por equipo. Por defecto, los registros solo son visibles para el equipo que los crea, pero es posible configurar herencia de permisos para compartir registros automaticamente con equipos padres o equipos relacionados.

### 7.3 Sincronizacion de Datos Entre Tenants

Aunque cada tenant tiene su propia base de datos EspoCRM aislada, existe la necesidad de sincronizar ciertos datos maestros entre tenants para funcionalidades compartidas. Esto incluye catalogos de paises, listas de industrias, estados de leads y otras referencias estaticas que son comunes a todos los tenants.

La sincronizacion de datos maestros se implementa mediante un script de sincronizacion que se ejecuta periodicamente. Este script compara los datos de referencia en cada base de datos tenant con los datos maestros en una base de datos central y aplica las actualizaciones necesarias. El script es idempotente y registra todas las operaciones para facilitar el diagnostico.

Es importante que los datos sincronizados sean de solo lectura en el contexto de cada tenant. Los usuarios de tenant no deben poder modificar los datos maestros, ya que estos cambios se perderian en la siguiente sincronizacion. Los permisos de escritura sobre estas entidades deben estar restringidos al rol de administrador del sistema.

## 8. Teams and Permissions

### 8.1 Sistema de Permisos de EspoCRM

El sistema de permisos de EspoCRM se basa en un modelo de Control de Acceso Basado en Roles (RBAC) combinado con permisos a nivel de equipo. Este sistema permite configurar con precision quien puede acceder a que registros y que operaciones puede realizar sobre ellos.

Los roles en EspoCRM definen permisos a nivel de entidad. Para cada rol, se especifican permisos separados para las operaciones Create, Read, Edit y Delete sobre cada entidad del sistema. Los permisos pueden ser configurados como None (sin acceso), Own (solo registros propios), Team (registros del equipo) o All (todos los registros independientemente del equipo).

La asignacion de roles a usuarios se realiza directamente o a traves de equipos. Un usuario puede tener multiples roles asignados directamente, en cuyo caso se aplica el permiso mas permisivo de entre todos los roles. Alternativamente, un usuario puede ser miembro de equipos que tienen roles asignados, y los permisos se heredan del equipo.

### 8.2 Configuracion de Roles para Integracion n8n

Para las integraciones con n8n, se recomienda crear un rol dedicado llamado API Integration con permisos especificos para las operaciones requeridas por cada flujo de trabajo de integracion.

El rol API Integration debe tener permisos de lectura sobre las entidades que n8n necesita consultar, como Account, Contact, Lead y Opportunity. Para las entidades que n8n necesita crear o actualizar, se requieren permisos de creacion y edicion respectivamente. Los permisos de eliminacion raramente son necesarios para integraciones y deben otorgarse solo cuando es absolutamente requerido.

Se recomienda crear usuarios API dedicados para cada integracion n8n separada. Esto permite revocar el acceso a una integracion especifica sin afectar las demas, y facilita el rastreo de actividad para auditoria. Cada usuario API debe tener asignado el rol API Integration y ninguna otra capacidad de acceso.

### 8.3 Permisos de Campo a Nivel de Equipo

Ademas de los permisos a nivel de entidad, EspoCRM permite configurar permisos a nivel de campo individual. Esto es particularmente util para entornos multi-tenant donde ciertos campos contienen informacion sensible que no debe ser visible para todos los usuarios de un tenant.

Los permisos de campo se configuran en la definicion de cada rol y especifican que campos son visibles y editables para los usuarios con ese rol. Los campos pueden marcarse como hidden (no visibles), read-only (visibles pero no editables) o editable (completamente accesibles).

Para implementar la constraint C4 a nivel de campo, se recomienda marcar como hidden cualquier campo que contenga informacion de identificacion de tenant o referencias a sistemas externos compartidos. Esto asegura que los usuarios de un tenant no puedan ver informacion que podria revelar la existencia o configuracion de otros tenants.

## 9. Webhooks

### 9.1 Configuracion de Webhooks en EspoCRM

Los webhooks en EspoCRM permiten notificar a sistemas externos cuando ocurren eventos especificos en el CRM. Esta funcionalidad es fundamental para las integraciones con n8n, ya que elimina la necesidad de sondeos constantes (polling) y permite una respuesta en tiempo real a los cambios en el sistema.

Los webhooks se configuran en Administration > Workflows > Webhooks. Cada webhook especifica la URL del endpoint destino, los eventos que lo activan, el metodo HTTP a utilizar (POST o PUT), y opcionalmente filtros para controlar exactamente que eventos disparan el webhook.

Los eventos disponibles para webhooks incluyen la creacion de registros (entityCreate), la actualizacion de registros (entityUpdate), la eliminacion de registros (entityDelete), el cambio de campo especifico (fieldChange), y eventos de flujo de trabajo (workflow). Cada evento lleva consigo informacion contextual sobre el registro afectado, incluyendo el tipo de entidad, el ID del registro, y los valores de los campos relevantes.

### 9.2 Ejemplo de Configuracion de Webhook para Leads

La siguiente configuracion establece un webhook que se dispara cada vez que se crea o actualiza un lead en el sistema. Este webhook puede ser utilizado por n8n para procesar automaticamente los leads entrantes y derivarlos al flujo de trabajo correspondiente.

```json
{
  "name": "Lead Update Notification",
  "event": "entityUpdate",
  "entityType": "Lead",
  "targetUrl": "https://n8n.mantis-agentic.internal/webhook/espocrm-lead-update",
  "httpMethod": "POST",
  "enabled": true,
  "filters": {
    "fieldList": ["leadSource", "leadStatus", "assignedUserId"],
    "conditions": []
  },
  "headers": {
    "X-EspoCRM-Webhook": "MantisAgentic",
    "X-Tenant-ID": "${tenant_id}"
  }
}
```

El campo X-Tenant-ID en las cabeceras es particularmente importante para la integracion multi-tenant, ya que permite que n8n identifique facilmente que tenant genero el evento y aplique el procesamiento correspondiente. Este valor se.popula automaticamente con el tenant_id del usuario que realizo la accion que disparo el webhook.

### 9.3 Procesamiento de Payloads de Webhook en n8n

Cuando n8n recibe un webhook de EspoCRM, el payload contiene informacion detallada sobre el evento que lo disparo. El nodo HTTP Request de n8n captura este payload, y nodos subsequentes pueden extraer la informacion necesaria para el procesamiento.

Un flujo de trabajo tipico de n8n para procesar webhooks de EspoCRM comienza con un nodo Webhook que recibe la solicitud, seguido de un nodo Switch que evalua el tipo de evento y deriva el flujo hacia el procesamiento apropiado. Para eventos de creacion de lead, por ejemplo, el flujo podria incluir la validacion de datos, la enrichccion con informacion adicional, y la derivacion a un equipo de ventas o a un flujo de nuturing automatizado.

Es importante implementar manejo de errores robusto en los flujos de n8n que procesan webhooks. Esto incluye la captura de errores, el logging detallado para diagnostico, y mecanismos de reintento para fallos transitorios. Tambien se recomienda implementar un endpoint de verificacion que EspoCRM pueda llamar para validar que el webhook esta configurado correctamente antes de comenzar a enviar eventos.

## 10. n8n Integration

### 10.1 Arquitectura de Integracion n8n-EspoCRM

La integracion entre n8n y EspoCRM es un componente central de la estrategia de automatizacion del proyecto MANTIS AGENTIC. Esta integracion permite que los flujos de trabajo automatizados en n8n accedan, manipulen y respondan a los datos en EspoCRM, creando un ecosistema de automatizacion cohesivo.

La arquitectura de integracion se basa en tres pilares principales. El primer pilar es la API REST de EspoCRM, que n8n utiliza para realizar operaciones CRUD sobre las entidades del CRM. El segundo pilar son los webhooks de EspoCRM, que notifican a n8n cuando ocurren eventos especificos, permitiendo la ejecucion de flujos de trabajo en tiempo real. El tercer pilar son los workflows de n8n, que definen la logica de automatizacion y se conectan con otros sistemas de la infraestructura.

Para cada VPS en la arquitectura MANTIS AGENTIC (VPS-1, VPS-2 y VPS-3), n8n tiene configuracion especifica para acceder a EspoCRM. Esta configuracion incluye las credenciales de API, los endpoints base y los timeouts de conexion apropiados para cada entorno.

### 10.2 Configuracion de Credenciales n8n para EspoCRM

En n8n, las credenciales de EspoCRM se configuran como credenciales de tipo API Key Auth. Estas credenciales incluyen el API Key y API Secret de EspoCRM, y n8n automaticamente genera las cabeceras de autenticacion requeridas para cada solicitud.

La configuracion de credenciales en n8n se realiza desde la seccion Settings > Credentials. Se recomienda crear credenciales separadas para cada entorno (desarrollo, staging, produccion) y para cada tenant si las integraciones requieren acceso a multiples bases de datos EspoCRM.

Las credenciales de EspoCRM en n8n deben incluir los siguientes campos: API Key (el identificador unico del usuario API), API Secret (la clave secreta para firma HMAC), y Tenant ID (para entornos multi-tenant, identifica que base de datos EspoCRM se debe utilizar). El campo Tenant ID es critico para la constraint C4, ya que permite a n8n dirigir las solicitudes al tenant correcto.

### 10.3 Flujos de Trabajo de Integracion Comunes

Los flujos de trabajo de integracion mas comunes entre n8n y EspoCRM incluyen la sincronizacion de leads desde formularios web, la actualizacion automatica de estados de oportunidad, la generacion de reportes periodicos y la notificacion de equipos de ventas sobre eventos importantes.

El flujo de sincronizacion de leads desde formularios web comienza cuando un visitante llena un formulario en el sitio web de un tenant. El formulario envia los datos a un webhook de n8n, que procesa la informacion, normaliza los campos y crea un nuevo lead en EspoCRM mediante la API. El flujo puede incluir pasos de validacion, enriquecimiento de datos con informacion de fuentes externas, y derivacion automatica basada en criterios predefinidos.

El flujo de actualizacion de estado de oportunidad monitorea cambios en las oportunidades de EspoCRM y toma acciones cuando se cumplen ciertas condiciones. Por ejemplo, cuando una oportunidad cambia al estado Closed Won, el flujo puede automatically enviar un email de celebracion al equipo de ventas, crear una tarea de onboarding para el cliente, y notificar al sistema contable para iniciar el proceso de facturacion.

## 11. Backup Procedures

### 11.1 Estrategia de Backup Multi-Tenant

La estrategia de backup para EspoCRM en un entorno multi-tenant debe considerar el aislamiento de datos entre tenants y la necesidad de poder restaurar seletivamente la informacion de un tenant especifico sin afectar a los demas. Esta estrategia se implementa mediante backups a nivel de base de datos individual.

Cada base de datos tenant (espocrm_${tenant_id}) se backs upea de forma independiente, generando archivos de backup separados que pueden ser restaurados seletivamente. Adicionalmente, se mantiene un backup completo de la base de datos master que contiene informacion de configuracion global y mapeos de tenants.

Los volumenes Docker que almacenan los archivos de EspoCRM (customizaciones, uploads, logs) tambien requieren backup regular. Estos volumenes se backs upean usando herramientas de backup de volumenes Docker o mediante scripts que copian los contenidos a almacenamiento externo.

### 11.2 Script de Backup Automatizado

El siguiente script implementa el procedimiento de backup completo para todos los tenants EspoCRM en el sistema.

```bash
#!/bin/bash

# Variables de configuracion
BACKUP_DIR="/backups/espocrm"
MYSQL_HOST="mysql-espocrm"
MYSQL_PORT="3306"
MYSQL_USER="${ESPOCRM_DB_USER}"
MYSQL_PASSWORD="${ESPOCRM_DB_PASSWORD}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Crear directorio de backup si no existe
mkdir -p ${BACKUP_DIR}

# Listar todas las bases de datos EspoCRM
DATABASES=$(mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SHOW DATABASES LIKE 'espocrm_%';" | grep -v Database | grep -v espocrm_main)

# Backup individual por base de datos
for DB in ${DATABASES}; do
    echo "Backing up database: ${DB}"
    mysqldump -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --master-data=2 \
        ${DB} | gzip > ${BACKUP_DIR}/${DB}_${DATE}.sql.gz

    # Verificar integridad del backup
    if gzip -t ${BACKUP_DIR}/${DB}_${DATE}.sql.gz; then
        echo "Backup verification passed for ${DB}"
    else
        echo "ERROR: Backup verification failed for ${DB}"
        exit 1
    fi
done

# Backup del volumen de archivos EspoCRM
echo "Backing up EspoCRM file volumes..."
tar -czf ${BACKUP_DIR}/espocrm_volumes_${DATE}.tar.gz \
    -C /docker/volumes/espocrm \
    data custom logs 2>/dev/null || echo "Warning: Some volume directories may not exist"

# Limpieza de backups antiguos
echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
find ${BACKUP_DIR} -name "*.gz" -mtime +${RETENTION_DAYS} -delete

# Generar reporte de backup
echo "Backup completed at $(date)" > ${BACKUP_DIR}/backup_report_${DATE}.txt
echo "Databases backed up: ${DATABASES}" >> ${BACKUP_DIR}/backup_report_${DATE}.txt
echo "Volume backup: espocrm_volumes_${DATE}.tar.gz" >> ${BACKUP_DIR}/backup_report_${DATE}.txt

echo "Backup procedure completed successfully"
```

Este script debe ejecutarse diariamente mediante cron o un scheduler similar. Se recomienda programar la ejecucion durante horas de baja actividad para minimizar el impacto en el rendimiento del sistema. La retencion de 30 dias proporciona un balance adecuado entre uso de almacenamiento y capacidad de restauracion.

### 11.3 Procedimiento de Restauracion

El procedimiento de restauracion de un backup de EspoCRM debe seguir pasos especificos para garantizar la integridad de los datos y la compatibilidad con el entorno.

Primero, se debe verificar la existencia y integridad del archivo de backup. Esto se hace descomprimiendo el archivo y verificando su contenido inicial con el comando zcat y head. Segundo, se debe detener el contenedor EspoCRM para evitar modificaciones durante el proceso de restauracion.

Tercero, se.drop la base de datos existente y se recrea vacia. Esto asegura que no haya conflictos entre datos antiguos y nuevos. Cuarto, se restaura el contenido del backup usando el comando mysql. Quinto, se verifican las tablas restauradas y se reinicia el contenedor EspoCRM.

Es importante probar el procedimiento de restauracion regularmente en un entorno de staging para garantizar que los backups son validos y que el equipo esta familiarizado con el proceso. La falta de pruebas puede llevar a situaciones donde un backup no puede ser restaurado cuando es necesario.

## 12. Compliance (ARQ-001, MT-009)

### 12.1 Requisitos de ARQ-001

La especificacion ARQ-001 establece los requisitos arquitecturales fundamentales que todos los componentes de la infraestructura MANTIS AGENTIC deben cumplir. Para EspoCRM, esto incluye requisitos de disponibilidad, escalabilidad, seguridad y auditabilidad.

En terminos de disponibilidad, EspoCRM debe estar disponible al menos el 99.5% del tiempo, medido mensualmente. Esto se logra mediante la configuracion apropiada de healthchecks, politicas de reinicio automatico y monitoreo proactivo. El healthcheck configurado en el docker-compose verifica que la API de EspoCRM responda correctamente, y el contenedor se reinicia automaticamente si falla el healthcheck.

La escalabilidad horizontal de EspoCRM se logra mediante la configuracion de balanceadores de carga delante de multiples instancias de EspoCRM que comparten la misma base de datos MySQL. Esta configuracion permite manejar incrementos de trafico agregando instancias adicionales, aunque EspoCRM no es intrinsecamente stateless, por lo que requiere consideraciones especiales para las sesiones de usuario.

### 12.2 Requisitos de MT-009

La especificacion MT-009 establece los requisitos especificos para la implementacion de multi-tenancy en el proyecto. Para EspoCRM, esto se traduce en requisitos de aislamiento de datos, identificacion de tenant y gestion de recursos por tenant.

El aislamiento de datos entre tenants se implementa mediante bases de datos separadas. Cada tenant tiene su propia base de datos EspoCRM completa, y los usuarios de un tenant no pueden acceder a los datos de otro tenant bajo ninguna circunstancia. Esta separacion se verifica durante las auditorias de compliance.

La identificacion de tenant mediante el campo tenant_id se implementa en todos los niveles del sistema. En EspoCRM, esto incluye la inclusion del tenant_id en webhooks, la asociacion de equipos con tenants especificos, y el filtrado automatico de consultas por tenant_id. Los logs del sistema incluyen el tenant_id para facilitar el rastreo de actividades.

### 12.3 Auditoria y Logging

EspoCRM mantiene logs de auditoria para todas las operaciones de creacion, modificacion y eliminacion de registros. Estos logs incluyen el usuario que realizo la operacion, la fecha y hora, los campos modificados y los valores anteriores y nuevos.

Para entornos multi-tenant, es critico que los logs de auditoria incluyan el tenant_id de forma prominente. Esto permite filtrar los logs por tenant durante las investigaciones de seguridad o auditorias de compliance. El formato de logs debe ser estructurado (JSON preferido) para facilitar el analisis automatizado.

Se recomienda exportar los logs de auditoria a un sistema externo de gestion de logs como Elasticsearch o Loki para su retencion a largo plazo y analisis avanzado. Los logs de EspoCRM se almacenan en el volumen espocrm-logs y pueden ser configurados para enviar copias a sistemas externos en tiempo real mediante agents de log shipping.

## 13. Troubleshooting

### 13.1 Problemas de Conexion a la Base de Datos

Los problemas de conexion entre EspoCRM y MySQL son comunes durante la configuracion inicial y suelen estar relacionados con credenciales incorrectas, problemas de red Docker o configuracion de usuarios MySQL.

Si EspoCRM no puede conectar a MySQL, el primer paso es verificar que el contenedor MySQL este funcionando y saludable. Esto se hace ejecutando docker ps para verificar el estado del contenedor y docker logs para ver los logs recientes de MySQL. Los logs de MySQL frecuentemente revelan errores de configuracion o problemas de inicializacion.

El segundo paso es verificar la conectividad de red entre los contenedores. Desde el contenedor EspoCRM, se puede ejecutar un comando como curl o telnet hacia mysql-espocrm:3306 para verificar que la resolucion DNS y la conectividad de red funcionan correctamente. Si hay problemas de red, verificar que ambos contenedores estan en la misma red Docker y que la configuracion de la red es correcta.

El tercer paso es verificar las credenciales de base de datos. Asegurarse de que el usuario MySQL existe, que tiene los privilegios correctos, y que la contrasena coincide exactamente con la configurada en las variables de entorno de EspoCRM. Un error comun es la presencia de espacios en blanco adicionales en las contrasenas.

### 13.2 Problemas de Rendimiento

El rendimiento lento de EspoCRM puede tener multiples causas, incluyendo falta de recursos del contenedor, consultas de base de datos inefficient, y congestion de la red.

Para diagnostic ar problemas de rendimiento, comenzar verificando el uso de recursos del contenedor EspoCRM. Docker stats muestra el uso de CPU, memoria, red y disco de cada contenedor. Si los recursos estan al maximo, considerar aumentar los limites asignados al contenedor o optimizar la configuracion de PHP.

Los logs de EspoCRM en data/logs/*.log contienen informacion sobre queries lentas y errores de PHP. Revisar estos logs regularmente ayuda a identificar problemas de rendimiento antes de que afecten a los usuarios. Para problemas de consultas lentas, considerar agregar indices a las tablas de MySQL usando la herramienta de administracion de EspoCRM.

### 13.3 Problemas de API y Autenticacion

Los errores de autenticacion en la API de EspoCRM usualmente indican problemas con las credenciales de API o con el proceso de generacion de firma HMAC.

Para diagnosticar problemas de autenticacion, comenzar verificando que la API esta habilitada en la configuracion de EspoCRM y que las credenciales de API existen y estan activas. Si las credenciales fueron revocadas o el usuario fue desactivado, la API rechazara todas las solicitudes con errores de autenticacion.

El proceso de firma HMAC de EspoCRM requiere sincronizacion de tiempo entre el cliente y el servidor. Si la diferencia de tiempo es excesiva (mas de 5 minutos), las solicitudes seran rechazadas por seguridad. Verificar que los relojes de los contenedores y los servidores n8n esten sincronizados usando NTP.

Para problemas persistentes de API, se recomienda probar primero con la herramienta de prueba de API integrada en EspoCRM (disponible en /api-testing) para descartar problemas del lado del servidor. Si la prueba integrada funciona pero las solicitudes desde n8n fallan, el problema probablemente esta en la implementacion de la autenticacion en el lado de n8n.

## 14. Referencia Rapida de Comandos

Esta seccion proporciona una referencia rapida de comandos Docker y MySQL utiles para la operacion diaria de EspoCRM.

Para iniciar el servicio EspoCRM, ejecutar docker-compose -f /path/to/docker-compose.yml up -d desde el directorio que contiene el archivo de configuracion. Para detener el servicio, ejecutar docker-compose down. Para reiniciar el servicio completo, ejecutar docker-compose restart.

Para acceder a los logs de EspoCRM en tiempo real, usar docker logs -f mantis-espocrm. Para ver los logs de MySQL, usar docker logs -f mantis-mysql-espocrm. Para ver los logs de ambos servicios simultaneamente, usar docker-compose logs -f.

Para acceder a la consola MySQL y ejecutar consultas directamente, usar docker exec -it mantis-mysql-espocrm mysql -u root -p${MYSQL_ROOT_PASSWORD}. Desde la consola MySQL, se puede usar SHOW DATABASES para ver todas las bases de datos, USE espocrm_${tenant_id} para seleccionar una base de datos especifica, y SHOW TABLES para ver las tablas disponibles.

Para verificar el estado de salud de los contenedores, usar docker inspect --format='{{.State.Health.Status}}' mantis-espocrm mantis-mysql-espocrm. Este comando devuelve el estado de salud de cada contenedor, que puede ser starting, healthy o unhealthy.

---

## Apendice A: Variables de Entorno Requeridas

| Variable | Descripcion | Requerido | Ejemplo |
|----------|-------------|-----------|---------|
| ESPOCRM_ADMIN_EMAIL | Email del administrador inicial | Si | admin@mantis-agentic.internal |
| ESPOCRM_ADMIN_PASSWORD | Contrasena del administrador | Si | (generar contrasena fuerte) |
| ESPOCRM_SITE_URL | URL base del sitio | Si | https://crm.mantis-agentic.internal |
| ESPOCRM_DATABASE_HOST | Host de la base de datos | Si | mysql-espocrm |
| ESPOCRM_DATABASE_PORT | Puerto de la base de datos | No | 3306 |
| ESPOCRM_DATABASE_NAME | Nombre de la base de datos | Si | espocrm_${TENANT_ID} |
| ESPOCRM_DATABASE_USERNAME | Usuario de base de datos | Si | espocrm_user |
| ESPOCRM_DATABASE_PASSWORD | Contrasena de base de datos | Si | (generar contrasena fuerte) |
| MYSQL_ROOT_PASSWORD | Contrasena root de MySQL | Si | (generar contrasena muy fuerte) |
| TENANT_ID | Identificador de tenant | Si | tenant_001 |

## Apendice B: Puertos y Servicios

| Servicio | Puerto Externo | Puerto Interno | Proposito |
|----------|----------------|----------------|----------|
| EspoCRM Web | 8080 | 80 | Interface web de EspoCRM |
| EspoCRM API | 8080 | 80 | API REST de EspoCRM |
| MySQL | 3307 | 3306 | Base de datos MySQL |

## Apendice C: Estructura de Directorios

| Ruta | Descripcion |
|------|-------------|
| /docker/volumes/espocrm/data | Archivos de datos de EspoCRM |
| /docker/volumes/espocrm/custom | Customizaciones de EspoCRM |
| /docker/volumes/espocrm/logs | Logs de EspoCRM |
| /docker/volumes/mysql-espocrm/data | Datos de MySQL |
| /docker/volumes/mysql-espocrm/logs | Logs de MySQL |
| /backups/espocrm | Backups de bases de datos y volumenes |

---

## Historial de Versiones

| Version | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0.0 | 2026-04-09 | Mantis-AgenticDev | Version inicial del documento |

## Validacion y Auto-Chequeo

Este documento ha sido validado contra las siguientes especificaciones:

- **ARQ-001**: Todos los requisitos arquitecturales fundamentales han sido implementados y documentados
- **MT-009**: La estrategia de multi-tenancy cumple con todos los requisitos de aislamiento y identificacion
- **Constraint C4**: El aislamiento de datos por tenant mediante base de datos separada esta correctamente implementado

## Metadatos del Documento

- **Tipo**: Skill de Infraestructura
- **Categoria**: CRM Setup and Integration
- **Audiencia**: Equipos de DevOps, Desarrolladores, Administradores de Sistema
- **Clasificacion**: Interno - Proyecto MANTIS AGENTIC
- **Próxima Revision**: 2026-04-16

## 🔗 Conexiones Estructurales
[[README.md]]
[[00-CONTEXT/facundo-infrastructure.md]]
