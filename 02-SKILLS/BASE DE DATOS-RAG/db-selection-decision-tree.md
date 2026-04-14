---
ai_optimized: true
title: "db-selection-decision-tree"
version: "1.0.0"
canonical_path: "02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md"
category: "Skill"
domain: ["database", "decision", "multi-tenant", "rag", "vertical"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
gate_status: "PASSED (7/7)"
tags:
  - sdd/skill/database
  - sdd/skill/decision-tree
  - sdd/skill/vertical
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "[[02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]"
  - "[[05-CONFIGURATIONS/environment/.env.example]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
  - "[[01-RULES/07-SCALABILITY-RULES.md]]"
---

# 🌳 Árbol de Decisión — Base de Datos por Cliente MANTIS AGENTIC

> **Para juniors:** Este documento responde la pregunta más frecuente del proyecto:
> *"¿En qué base de datos pongo los datos de este cliente?"*
> Existe una respuesta correcta para cada situación. Este árbol la encuentra.
>
> **Para el ZIP generator:** Leer frontmatter de `bootstrap-company.json` del cliente,
> recorrer el árbol, obtener el `db_stack`, cargar los schemas correspondientes
> de `vertical-db-schemas.md`.

---

## 📐 Fundamentos — ¿Por qué hay varias opciones?

Cada motor de base de datos tiene un "superpoder" y una limitación. La clave es elegir el que mejor sirve al cliente según **3 variables**:

| Variable | Pregunta | Opciones |
|---|---|---|
| **Infraestructura** | ¿Tiene VPS propio o usa plan cloud? | VPS propio · Sin servidor |
| **Volumen** | ¿Cuántos registros espera por mes? | < 5K · 5K-50K · > 50K |
| **Necesidades** | ¿Qué tiene que hacer con los datos? | Buscar · Relacionar · Ver visualmente · Todo |

### El mapa de motores del stack MANTIS

```
MOTOR          SUPERPODER                      LIMITACIÓN               COSTO
─────────────────────────────────────────────────────────────────────────────
MySQL         Relaciones complejas, SQL        Requiere VPS             Gratis
              robusto, EspoCRM nativo          servidor

PostgreSQL    SQL avanzado + JSONB +           Requiere VPS o cloud     Gratis
/Prisma       RLS nativo                       más complejo de tunar

Qdrant        Búsqueda semántica vectorial     No es BD relacional      Gratis (self)
              (RAG, IA, similitud)             necesita motor relacional Cloud desde $0

Supabase      Postgres cloud + RLS +           Límites en plan free     Free/Pro $25
              no necesita VPS                  (500MB, 50K filas)

Google        Gratis, visual, sin servidor     < 5K registros,          Gratis
Sheets        el cliente puede editar          sin tipos de dato

Airtable      Relaciones visuales, imágenes,   Límites agresivos        Free/Team $20
              pipeline Kanban                  en plan gratuito

Redis         Sesiones ultra-rápidas,          NO es persistencia       Gratis
              cache, dedup mensajes            primaria de datos
```

---

## 🌳 Árbol Principal de Decisión

```
╔══════════════════════════════════════════════════════════════════════╗
║  INICIO: Nuevo cliente solicita sistema agéntico WhatsApp            ║
╚══════════════════════════════════════════════════════════════════════╝
                            │
                            ▼
           ┌────────────────────────────────────┐
           │  ¿El cliente tiene VPS propio       │
           │  o está dispuesto a contratar uno?  │
           └────────────────────────────────────┘
                  │                    │
                 SÍ                   NO
                  │                    │
                  ▼                    ▼
     ┌────────────────────┐    ┌──────────────────────────┐
     │ ¿Cuántos registros │    │ ¿Cuántos registros espera │
     │ espera por mes?    │    │ por mes?                  │
     └────────────────────┘    └──────────────────────────┘
       │          │    │          │           │          │
    < 5K      5K-50K  >50K     < 1K       1K-5K      > 5K
       │          │    │          │           │          │
       ▼          ▼    ▼          ▼           ▼          ▼
   [STACK A]  [STACK B] [STACK C] [STACK D] [STACK E] [STACK F]
```

---

## 📦 Los 6 Stacks de BD del Proyecto

### STACK A — VPS + Volumen Bajo (< 5K/mes)
**Para:** Restaurante pequeño, consultorio dental 1 silla, pousada rural con < 10 hab.

```
STACK A:
├── MySQL           → Metadata RAG, conversaciones, tokens
├── Qdrant          → Vectores para búsqueda semántica (RAG)
├── Redis           → Sesiones WhatsApp (TTL 4h)
└── Google Sheets   → BD operativa del negocio (reservas, menú, agenda)
    (opcional)        el dueño la edita directamente

Cuándo elegir Google Sheets sobre MySQL para datos operativos:
  → El dueño NO tiene conocimientos técnicos
  → Quiere ver y editar sus datos en una planilla
  → Los registros son simples (< 20 columnas)
  → Volumen < 5.000 registros en la hoja

Cuándo usar MySQL directo incluso con volumen bajo:
  → El dueño tiene equipo técnico
  → Los datos tienen relaciones (paciente → citas → tratamientos)
  → Se necesitan consultas complejas (reportes, estadísticas)
```

**Variables de entorno para STACK A:**
```bash
DB_STACK=A
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
QDRANT_URL=http://127.0.0.1:6333
REDIS_URL=redis://:${REDIS_PASSWORD}@127.0.0.1:6379/0
GOOGLE_SHEETS_ENABLED=true
SHEETS_ID_${TENANT_ID_UPPER}=${SPREADSHEET_ID}
```

---

### STACK B — VPS + Volumen Medio (5K-50K/mes)
**Para:** Restaurante activo, clínica dental 3+ sillas, hotel 20+ habitaciones, empresa marketing.

```
STACK B:
├── MySQL           → BD principal (C4: todas las tablas con tenant_id)
├── Qdrant          → Vector store RAG
├── Redis           → Sesiones + cache de consultas frecuentes
└── EspoCRM         → CRM de contactos y leads (usa MySQL del mismo VPS2)

Sin Google Sheets — a este volumen las hojas se degradan.
EspoCRM reemplaza Google Sheets para gestión de clientes.
```

**Variables de entorno para STACK B:**
```bash
DB_STACK=B
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
QDRANT_URL=http://127.0.0.1:6333
REDIS_URL=redis://:${REDIS_PASSWORD}@127.0.0.1:6379/0
ESPOCRM_URL=https://${CRM_DOMAIN}
ESPOCRM_API_KEY=${ESPOCRM_API_KEY}
```

---

### STACK C — VPS + Volumen Alto (> 50K/mes)
**Para:** Cadena de restaurantes, red de clínicas, hotel con múltiples propiedades, agencia marketing grande.

```
STACK C:
├── PostgreSQL+Prisma → BD principal con RLS, JSONB, particionamiento
├── Qdrant            → Vector store RAG (colecciones separadas por tenant)
├── Redis             → Sesiones + cache de alta disponibilidad
├── MySQL             → Solo para EspoCRM (BD separada en VPS2)
└── Supabase          → Opcional: analytics y dashboards read-only
                        (no modifica datos — solo consulta replica)

PostgreSQL reemplaza MySQL porque:
  → JSONB nativo más eficiente que JSON de MySQL para metadata RAG
  → RLS enforcea C4 a nivel de BD (no solo aplicación)
  → Particionamiento por tenant más maduro
  → pgvector extensión (vectores in-DB si se quiere eliminar Qdrant)
```

**Variables de entorno para STACK C:**
```bash
DB_STACK=C
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}
QDRANT_URL=http://127.0.0.1:6333
REDIS_URL=redis://:${REDIS_PASSWORD}@127.0.0.1:6379/0
MYSQL_HOST=127.0.0.1   # Solo para EspoCRM
```

---

### STACK D — Sin VPS + Volumen Muy Bajo (< 1K/mes)
**Para:** Negocio unipersonal, demo para prospecto, prototipo para validar.

```
STACK D:
├── Google Sheets   → TODA la BD operativa (sin servidor)
├── Qdrant Cloud    → Vector store (free tier: 1 colección, 1GB)
└── Redis Cloud     → Sesiones (Upstash free: 10K requests/día)

Costo mensual: $0 (dentro de los free tiers)
Limitación: si el negocio crece → migrar a STACK E o F
```

**Variables de entorno para STACK D:**
```bash
DB_STACK=D
SHEETS_ID_${TENANT_ID_UPPER}=${SPREADSHEET_ID}
QDRANT_URL=https://${QDRANT_CLOUD_CLUSTER}.aws.cloud.qdrant.io
QDRANT_API_KEY=${QDRANT_CLOUD_KEY}
REDIS_URL=rediss://:${UPSTASH_TOKEN}@${UPSTASH_HOST}:6380
```

---

### STACK E — Sin VPS + Volumen Medio (1K-5K/mes)
**Para:** Pousada mediana sin IT, consultorio dental 1-2 sillas, cafetería con delivery.

```
STACK E:
├── Supabase       → BD principal cloud (PostgreSQL + RLS automático)
├── Airtable       → Menú, catálogo, datos visuales (el dueño los gestiona)
├── Qdrant Cloud   → Vector store RAG (plan starter)
└── Upstash Redis  → Sesiones (plan pay-as-you-go)

Supabase para datos transaccionales (reservas, citas, pedidos).
Airtable para catálogos que el dueño quiere ver visualmente (menú, precios).
```

**Variables de entorno para STACK E:**
```bash
DB_STACK=E
SUPABASE_URL=https://${PROJECT}.supabase.co
SUPABASE_SERVICE_KEY=${SUPABASE_SERVICE_KEY}
AIRTABLE_API_TOKEN=${AIRTABLE_TOKEN}
AIRTABLE_BASE_${TENANT_ID_UPPER}=${BASE_ID}
QDRANT_URL=https://${CLUSTER}.aws.cloud.qdrant.io
QDRANT_API_KEY=${QDRANT_CLOUD_KEY}
REDIS_URL=rediss://:${UPSTASH_TOKEN}@${UPSTASH_HOST}:6380
```

---

### STACK F — Sin VPS + Volumen Alto (> 5K/mes)
**Para:** Hotel con sistema de reservas activo, clínica dental grande, agencia de marketing con muchos clientes propios.

```
STACK F:
├── Supabase Pro   → BD principal (50K filas, 8GB storage)
├── Qdrant Cloud   → Vector store (plan Standard)
├── Upstash Redis  → Sesiones
└── → Migración planificada a VPS con STACK B o C

STACK F es transitorio: si el negocio justifica Supabase Pro ($25/mes),
probablemente en 3-6 meses justifica un VPS ($5-10/mes) con más control.
Documentar la migración en el onboarding del cliente.
```

---

## 🎯 Matriz de Decisión Rápida

| Vertical | VPS disponible | Registros/mes | Stack recomendado | Motor principal |
|---|---|---|---|---|
| Restaurante pequeño | No | < 500 | **D** | Google Sheets + Qdrant Cloud |
| Cafetería con delivery | No | 1K-3K | **E** | Supabase + Airtable |
| Restaurante activo | Sí | 5K-20K | **B** | MySQL + Qdrant + EspoCRM |
| Churrascaria / Delivery | Sí | 20K+ | **B/C** | MySQL o PostgreSQL + Qdrant |
| Sushi bar / Bar nocturno | Sí | 10K-30K | **B** | MySQL + Qdrant |
| Pousada rural pequeña | No | < 500 | **D** | Google Sheets + Qdrant Cloud |
| Hotel 20+ habitaciones | Sí | 5K-15K | **B** | MySQL + Qdrant + EspoCRM |
| Hotel con múltiples props | Sí | 50K+ | **C** | PostgreSQL + Qdrant |
| Camping | No/Sí | < 2K | **D/E** | Google Sheets o Supabase |
| Consultorio dental 1 silla | No | < 1K | **D** | Google Sheets + Qdrant Cloud |
| Clínica dental 3+ sillas | Sí | 5K-20K | **B** | MySQL + Qdrant |
| Clínica dental especialidades | Sí | 20K+ | **C** | PostgreSQL + Qdrant |
| Agencia marketing pequeña | No | 2K-8K | **E** | Supabase + Airtable |
| Agencia marketing mediana | Sí | 10K-50K | **B** | MySQL + Qdrant + EspoCRM |
| Estudio de abogados | Sí | 5K-20K | **B** | MySQL + Qdrant (KB legal) |
| Empresa de turismo | Sí | 10K-30K | **B/C** | MySQL + Qdrant |
| Empresa IA (KB interna) | Sí | 20K-100K | **C** | PostgreSQL + Qdrant |
| Corp-KB (empresa grande) | Sí | 50K+ | **C** | PostgreSQL + Qdrant |

---

## 🤖 Función de Decisión para el ZIP Generator

```python
# db_selector.py
# Función que el ZIP generator llama con el bootstrap-company.json
# Retorna el stack_id y la configuración de BD recomendada

from dataclasses import dataclass
from typing import Literal

DBStack = Literal["A", "B", "C", "D", "E", "F"]

@dataclass
class ClientProfile:
    tenant_id:       str
    vertical:        str      # restaurante, hotel, dental, marketing, corp-kb, legal, turismo
    has_vps:         bool
    monthly_records: int      # Registros estimados por mes
    needs_crm:       bool     # ¿Necesita EspoCRM?
    needs_rag:       bool     # ¿Necesita búsqueda semántica?
    visual_editing:  bool     # ¿El dueño quiere editar datos visualmente?
    budget_usd:      float    # Presupuesto mensual en USD (0 = solo free)

@dataclass
class DBRecommendation:
    stack_id:        DBStack
    primary_db:      str
    vector_db:       str
    session_db:      str
    optional_db:     str
    monthly_cost:    float
    migration_path:  str
    rationale:       str

def select_db_stack(profile: ClientProfile) -> DBRecommendation:
    """
    C4: tenant_id obligatorio en el perfil.
    Retorna la recomendación de stack de BD.
    """
    if not profile.tenant_id:
        raise ValueError("C4_VIOLATION: tenant_id required in ClientProfile")

    # ── Sin VPS ────────────────────────────────────────────────────────────
    if not profile.has_vps:
        if profile.monthly_records < 1000:
            return DBRecommendation(
                stack_id="D",
                primary_db="google_sheets",
                vector_db="qdrant_cloud_free",
                session_db="upstash_redis_free",
                optional_db=None,
                monthly_cost=0.0,
                migration_path="D → E cuando records > 1K/mes",
                rationale="Volumen muy bajo. Google Sheets es suficiente y el dueño lo gestiona sin IT."
            )
        elif profile.monthly_records < 5000:
            return DBRecommendation(
                stack_id="E",
                primary_db="supabase" if not profile.visual_editing else "supabase+airtable",
                vector_db="qdrant_cloud_starter",
                session_db="upstash_redis",
                optional_db="airtable" if profile.visual_editing else None,
                monthly_cost=25.0 if profile.budget_usd >= 25 else 0.0,
                migration_path="E → STACK B con VPS cuando budget > R$50/mes",
                rationale="Volumen medio sin servidor. Supabase da SQL real con RLS automático."
            )
        else:
            return DBRecommendation(
                stack_id="F",
                primary_db="supabase_pro",
                vector_db="qdrant_cloud_standard",
                session_db="upstash_redis_pro",
                optional_db=None,
                monthly_cost=50.0,
                migration_path="F → STACK C con VPS KVM2 en 3-6 meses",
                rationale="Volumen alto sin servidor. Supabase Pro es temporal — planificar migración a VPS."
            )

    # ── Con VPS ────────────────────────────────────────────────────────────
    if profile.monthly_records < 5000:
        return DBRecommendation(
            stack_id="A",
            primary_db="mysql" if not profile.visual_editing else "mysql+google_sheets",
            vector_db="qdrant_self",
            session_db="redis_self",
            optional_db="google_sheets" if profile.visual_editing else None,
            monthly_cost=0.0,
            migration_path="A → B cuando records > 5K/mes",
            rationale="VPS + volumen bajo. MySQL para metadatos RAG, Sheets opcional para datos operativos del dueño."
        )
    elif profile.monthly_records < 50000:
        return DBRecommendation(
            stack_id="B",
            primary_db="mysql",
            vector_db="qdrant_self",
            session_db="redis_self",
            optional_db="espocrm" if profile.needs_crm else None,
            monthly_cost=0.0,
            migration_path="B → C con PostgreSQL cuando records > 50K/mes",
            rationale="VPS + volumen medio. Stack principal del proyecto. MySQL maduro para multi-tenant."
        )
    else:
        return DBRecommendation(
            stack_id="C",
            primary_db="postgresql_prisma",
            vector_db="qdrant_self",
            session_db="redis_self",
            optional_db="mysql_espocrm",   # MySQL solo para EspoCRM
            monthly_cost=0.0,
            migration_path="C es el stack final — escalar hardware si es necesario",
            rationale="VPS + volumen alto. PostgreSQL con RLS y JSONB supera a MySQL en este escenario."
        )
```

---

## 📋 Guía por Vertical — Decisiones Predefinidas

Esta sección mapea verticales específicos al stack sin pasar por el árbol completo.

### 🍕 Verticales de Gastronomía

| Sub-vertical | Stack | Notas |
|---|---|---|
| Restaurante tradicional | **B** (con VPS) / **D** (sin VPS) | Si tiene delivery: sumar Airtable para menú |
| Churrascaria | **B** | Volumen medio-alto de reservas y comanda |
| Fondue / Temático | **A o D** | Volumen bajo, experiencia exclusiva |
| Pizzaria con delivery | **B** | Pedidos + tracking = necesita MySQL |
| Sushi bar | **A o B** | Menú pequeño pero mesa rotación alta |
| Bar nocturno con shows | **A** | Eventos irregulares, volumen bajo |
| Delivery de alimentos (multi-resto) | **C** | Múltiples tenants → PostgreSQL + RLS |
| Cafetería corporativa | **E** | Sin VPS, control visual del menú |
| Venta de chocolates / Confitería | **D o E** | Catálogo visual → Airtable ideal |
| Parrilla gaucha tradicional | **A** | Reservas + menú del día |
| Restaurante italiano | **A o B** | Según tamaño y volumen |

### 🏨 Verticales de Hospedaje

| Sub-vertical | Stack | Notas |
|---|---|---|
| Pousada rural (< 10 hab) | **D** | Google Sheets para reservas, Qdrant para FAQs |
| Pousada urbana (10-30 hab) | **E o A** | Supabase si no tiene VPS |
| Hotel boutique (< 50 hab) | **B** | EspoCRM para CRM de huéspedes |
| Hotel mediano (50-200 hab) | **B** | MySQL + Qdrant obligatorio |
| Hotel grande / cadena | **C** | PostgreSQL + RLS por propiedad |
| Camping / Glamping | **D o E** | Temporada = volumen bajo en off-season |
| Hostel | **A** | Mix de alojamiento + café |

### 🦷 Verticales de Odontología

| Sub-vertical | Stack | Notas |
|---|---|---|
| Consultorio 1 dentista | **D** | Google Sheets + Qdrant Cloud para FAQs |
| Clínica 2-3 sillas | **A o B** | Depende de volumen de pacientes |
| Clínica especialidades (implantes, ortodoncia, estética) | **B** | MySQL + RAG para protocolos |
| Clínica universitaria / enseñanza | **C** | Muchos usuarios, PostgreSQL + RLS |
| Red de clínicas (multi-ciudad) | **C** | Multi-tenant real → PostgreSQL |
| Clínica con laboratorio propio | **B** | Tabla extra: lab_pedidos, materiales |

**Nota LGPD para dental:** Los datos de pacientes en Brasil son datos sensibles bajo la LGPD. Para clínicas con > 100 pacientes, recomendar VPS (STACK B o C) con datos on-premises en vez de cloud (Supabase). MySQL en VPS propio del cliente = datos nunca salen del servidor del cliente.

### 📱 Verticales de Marketing y Turismo

| Sub-vertical | Stack | Notas |
|---|---|---|
| Agencia marketing pequeña | **E** | Supabase + Airtable para pipelines |
| Agencia marketing mediana | **B** | MySQL + EspoCRM para CRM de clientes |
| Agencia marketing grande | **C** | PostgreSQL multi-tenant (cada cliente es un tenant) |
| Agencia turismo local | **B** | Paquetes + itinerarios en RAG |
| Agencia turismo online | **C** | Alto volumen de consultas |
| Promoción turística redes sociales | **B o E** | Depende de escala |

### 📚 Verticales de Base de Conocimiento (Corp-KB)

| Sub-vertical | Stack | Notas |
|---|---|---|
| Estudio de abogados | **B** | RAG para jurisprudencia, contratos |
| Empresa generadora de agentes IA | **C** | PostgreSQL como el propio stack MANTIS |
| Empresa turismo (KB interna) | **B** | RAG para empleados sobre destinos |
| Empresa gastronómica (franquicias) | **C** | KB multi-tenant por franquicia |
| Hotel (KB para staff) | **B** | Protocolos de atención en RAG |
| Clínica dental (KB) | **B** | Protocolos clínicos en RAG |
| Empresa corporativa genérica | **C** | Multi-departamento = multi-tenant |

---

## 🔄 Árbol de Migración (cuando el stack actual ya no alcanza)

```
SEÑALES de que hay que migrar:
├── Google Sheets: hojas > 5.000 filas o queries lentan > 2s
├── Supabase Free: > 500MB storage o > 50K registros
├── MySQL KVM1: docker stats muestra > 85% RAM constante
└── Cualquier stack: latencia de respuesta WhatsApp > 5s

CAMINOS DE MIGRACIÓN:
D (Sheets) ──────► A (MySQL+VPS)       → Contratar VPS KVM1, migrar datos
D (Sheets) ──────► E (Supabase)        → Exportar CSV, importar en Supabase
E (Supabase) ────► B (MySQL+VPS)       → pg_dump → mysql import
E (Supabase) ────► C (Postgres+VPS)    → pg_dump → restore (más simple)
A (MySQL low) ──► B (MySQL medium)     → Solo ampliar VPS a KVM2
B (MySQL) ───────► C (Postgres)        → Migración de schema con scripts
F (Supabase Pro) ► C (Postgres+VPS)    → Supabase export → VPS restore
```

---

## ✅ Tabla de Validación del Árbol de Decisión

| # | Verificación | Cómo comprobar | ✅ Correcto | ❌ Incorrecto |
|---|---|---|---|---|
| 1 | Stack elegido está en la tabla de la vertical | Buscar el sub-vertical en las tablas de esta sección | Stack en tabla coincide con el elegido | Stack no aparece en tabla |
| 2 | Variables de entorno del stack cargadas | `echo $DB_STACK` | `A`, `B`, `C`, `D`, `E` o `F` | vacío |
| 3 | tenant_id presente en perfil del cliente | `echo $TENANT_ID` | UUID válido `tenant-xxxx` | vacío o `undefined` |
| 4 | Motor de BD del stack está corriendo | `docker ps` (VPS) o curl al endpoint cloud | Servicio healthy | No encontrado |
| 5 | Qdrant configurado con filtro tenant_id | `grep tenant_id` en el código de búsqueda | Filtro presente en toda búsqueda | Sin filtro |

---

## 🔗 Referencias Cruzadas

- [[02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md]] — Schemas SQL por vertical
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]] — Stack B: MySQL patterns
- [[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]] — Stack C: PostgreSQL patterns
- [[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]] — Stack E/F: Supabase patterns
- [[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]] — Stack A/D: Sheets patterns
- [[02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md]] — Stack E: Airtable patterns
- [[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]] — Setup Stack B/C en VPS2
- [[05-CONFIGURATIONS/environment/.env.example]] — Variables base de todos los stacks

---

# 🟢 VALIDATION: 
# 1. ./05-CONFIGURATIONS/validation/check-wikilinks.sh 02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md
# 2. ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --type md --strict 02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md
# 3. mysql -e "SOURCE 02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md" --dry-run  # validación sintáctica

<!-- ai:file-end marker — do not remove -->
Versión 1.0.0 — 2026-04-13 — Mantis-AgenticDev
