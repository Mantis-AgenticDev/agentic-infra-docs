---
title: "Aislamiento Multi-Tenant de Datos"
category: "Skill"
domain: ["security", "backend", "database"]
constraints: ["C4", "C3"]
priority: "Crítica"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/multi-tenant
  - sdd/skill/security
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "validation-checklist.md"
---

## 🎯 Propósito y Alcance

Define patrones de aislamiento de datos para arquitecturas multi-tenant garantizando que **NINGÚN** cliente pueda ver datos de otros clientes. Este skill es la implementación práctica del constraint C4 (tenant_id obligatorio) aplicado a MySQL, PostgreSQL, Supabase y Qdrant.

**Alcance:**
- Aislamiento a nivel de fila (Row Level Security)
- Aislamiento a nivel de schema/base de datos
- Validación de tenant_id en TODAS las queries
- Prevención de leaks entre tenants
- Testing de aislamiento

**Fuera de alcance:**
- Single-tenant deployments (cada cliente en servidor separado)
- Aislamiento a nivel de container (no es suficiente sin C4)

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es Multi-tenancy?
Arquitectura donde múltiples clientes ("tenants") comparten la misma infraestructura (app, BD, servidor) pero sus datos están completamente separados.

### Niveles de Aislamiento

| Nivel | Descripción | Seguridad | Complejidad | Costo |
|-------|-------------|-----------|-------------|-------|
| **Shared DB + Shared Schema (C4)** | Misma BD, mismas tablas, filtro por tenant_id | ⭐⭐⭐ | ⭐ | $ |
| **Shared DB + Separate Schemas** | Misma BD, schema por tenant | ⭐⭐⭐⭐ | ⭐⭐ | $$ |
| **Separate Databases** | BD separada por tenant | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | $$$ |
| **Separate Servers** | Servidor dedicado por tenant | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $$$$ |

**MANTIS AGENTIC usa Nivel 1** (Shared DB + tenant_id) por:
- **Económico:** 100 tenants en 1 servidor vs. 100 servidores
- **Simple:** Código unificado, un solo deploy
- **Suficientemente seguro** si C4 se respeta estrictamente

### ¿Por qué es Critical C4?

**Escenario sin C4:**
```sql
SELECT * FROM messages WHERE chat_id = 'abc123';
-- Retorna mensaje si existe, SIN verificar tenant
```

**Resultado:** Restaurante A puede ver mensajes de Restaurante B si adivina el chat_id.

**Escenario con C4:**
```sql
SELECT * FROM messages WHERE tenant_id = ? AND chat_id = ?;
-- Solo retorna si el mensaje pertenece al tenant correcto
```

**Resultado:** Aislamiento perfecto a nivel de datos.

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Topología Multi-Tenant en VPS Limitado

```
┌─────────────────────────────────────────────────────────────┐
│                   VPS 2 (4GB RAM)                            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  MySQL 8.0 (2GB RAM limit)                           │   │
│  │                                                       │   │
│  │  Database: mantis_production                         │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │ Table: messages                              │    │   │
│  │  │ Columns: id, tenant_id, chat_id, content    │    │   │
│  │  │ Index: idx_tenant_chat (tenant_id, chat_id) │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  Queries:                                            │   │
│  │  ✅ SELECT * FROM messages WHERE tenant_id=? ...     │   │
│  │  ❌ SELECT * FROM messages WHERE chat_id=? (SIN C4)  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Qdrant 1.8+ (1.5GB RAM limit)                       │   │
│  │                                                       │   │
│  │  Collection: mantis_docs                             │   │
│  │  Payload: {tenant_id, text, source, ...}            │   │
│  │                                                       │   │
│  │  Searches:                                           │   │
│  │  ✅ filter: {must: [{key: "tenant_id", ...}]}        │   │
│  │  ❌ search sin filter (SIN C4)                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Optimización de Índices para Multi-Tenancy

**Índices Compuestos con tenant_id PRIMERO:**
```sql
-- ✅ CORRECTO: tenant_id como primera columna
CREATE INDEX idx_tenant_chat ON messages(tenant_id, chat_id);
CREATE INDEX idx_tenant_date ON messages(tenant_id, created_at);

-- ❌ INCORRECTO: tenant_id como segunda columna
CREATE INDEX idx_chat_tenant ON messages(chat_id, tenant_id);
-- Este índice NO ayuda en queries con WHERE tenant_id = ?
```

**Razón:** MySQL usa índices de izquierda a derecha. `idx_tenant_chat` es eficiente para:
```sql
WHERE tenant_id = 'A'                    -- Usa índice ✅
WHERE tenant_id = 'A' AND chat_id = 'X'  -- Usa índice completo ✅
WHERE chat_id = 'X'                      -- NO usa índice ❌
```

## 🔗 Conexión Local vs Externa

### Variables de Entorno por Ambiente

```bash
# .env.development (local)
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=dev_user
DB_PASSWORD=dev_pass
DB_NAME=mantis_dev
DB_SSL_MODE=DISABLED

# .env.production (VPS)
DB_HOST=vps2-mysql.internal
DB_PORT=3306
DB_USER=app_user
DB_PASSWORD=${SECRET_DB_PASSWORD}  # Desde vault
DB_NAME=mantis_production
DB_SSL_MODE=REQUIRED
```

### Conexión con Validación de tenant_id

```javascript
// db.js
const mysql = require('mysql2/promise');

class MultiTenantDB {
  constructor() {
    this.pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      ssl: process.env.DB_SSL_MODE === 'REQUIRED' ? {} : false,
      connectionLimit: 10  // C1: Limitar conexiones
    });
  }

  /**
   * Query seguro que SIEMPRE incluye tenant_id (C4).
   * 
   * spec_referenced: MT-001, PAT-002
   * constraints_applied: C4
   */
  async query(sql, params, tenantId) {
    // Validación C4
    if (!tenantId || typeof tenantId !== 'string') {
      throw new Error('tenant_id is MANDATORY for all queries (C4)');
    }

    // Inyectar tenant_id en WHERE clause
    const safeSql = this.injectTenantFilter(sql, tenantId);
    
    return this.pool.execute(safeSql, params);
  }

  injectTenantFilter(sql, tenantId) {
    // Detectar si ya tiene WHERE
    if (sql.toUpperCase().includes('WHERE')) {
      return sql.replace(
        /WHERE/i,
        `WHERE tenant_id = '${this.escape(tenantId)}' AND`
      );
    } else {
      // Agregar WHERE antes de ORDER BY, LIMIT, etc.
      return sql.replace(
        /(ORDER BY|LIMIT|GROUP BY)/i,
        `WHERE tenant_id = '${this.escape(tenantId)}' $1`
      );
    }
  }

  escape(value) {
    return value.replace(/'/g, "''");  // Escape básico
  }
}

module.exports = new MultiTenantDB();

// Uso
const db = require('./db');
const tenantId = req.user.tenant_id;  // Del JWT

const [rows] = await db.query(
  'SELECT * FROM messages WHERE chat_id = ?',
  ['chat_123'],
  tenantId  // C4: SIEMPRE pasar tenant_id
);
```

## 📘 Guía de Estructura de Tablas

### Tabla con Multi-Tenancy (MySQL)

```sql
CREATE TABLE messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  
  -- C4: tenant_id OBLIGATORIO, primera columna en índices
  tenant_id VARCHAR(255) NOT NULL,
  
  -- Datos de negocio
  chat_id VARCHAR(255) NOT NULL,
  user_id VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Índices multi-tenant (tenant_id PRIMERO)
  INDEX idx_tenant_chat (tenant_id, chat_id),
  INDEX idx_tenant_user (tenant_id, user_id),
  INDEX idx_tenant_date (tenant_id, created_at),
  
  -- Foreign keys CON tenant_id
  FOREIGN KEY (tenant_id, user_id) 
    REFERENCES users(tenant_id, id) 
    ON DELETE CASCADE,
  
  -- Constraint para prevenir tenant_id NULL
  CHECK (tenant_id IS NOT NULL AND LENGTH(tenant_id) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Tabla de Tenants (Metadata)

```sql
CREATE TABLE tenants (
  id VARCHAR(255) PRIMARY KEY,  -- 'restaurant_123'
  name VARCHAR(255) NOT NULL,
  subscription_plan ENUM('free', 'pro', 'enterprise') DEFAULT 'free',
  max_users INT DEFAULT 5,
  max_storage_mb INT DEFAULT 100,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  
  INDEX idx_active (is_active),
  INDEX idx_plan (subscription_plan)
) ENGINE=InnoDB;

-- Ejemplo de datos
INSERT INTO tenants (id, name, subscription_plan) VALUES
  ('restaurant_123', 'Pizzería Don José', 'pro'),
  ('clinic_456', 'Clínica Dental Sol', 'enterprise');
```

## 🛠️ 4 Ejemplos Centrales (Copy-Paste)

### Ejemplo 1: Helper de Query Multi-Tenant (Node.js)

```javascript
// multi-tenant-helper.js
class TenantQueryBuilder {
  constructor(tenantId) {
    if (!tenantId) throw new Error('tenant_id required (C4)');
    this.tenantId = tenantId;
  }

  /**
   * Construye query SELECT con tenant_id automático.
   * 
   * spec_referenced: MT-001
   * constraints_applied: C4
   */
  select(table, columns = '*', conditions = {}) {
    const cols = Array.isArray(columns) ? columns.join(', ') : columns;
    
    // C4: SIEMPRE incluir tenant_id
    const where = Object.entries({tenant_id: this.tenantId, ...conditions})
      .map(([k, v]) => `${k} = ?`)
      .join(' AND ');
    
    const values = Object.values({tenant_id: this.tenantId, ...conditions});
    
    return {
      sql: `SELECT ${cols} FROM ${table} WHERE ${where}`,
      values
    };
  }

  /**
   * INSERT con tenant_id obligatorio.
   */
  insert(table, data) {
    // C4: Forzar tenant_id
    const fullData = {tenant_id: this.tenantId, ...data};
    
    const columns = Object.keys(fullData).join(', ');
    const placeholders = Object.keys(fullData).map(() => '?').join(', ');
    const values = Object.values(fullData);
    
    return {
      sql: `INSERT INTO ${table} (${columns}) VALUES (${placeholders})`,
      values
    };
  }

  /**
   * UPDATE solo para datos del tenant (C4).
   */
  update(table, data, conditions) {
    const setClauses = Object.keys(data).map(k => `${k} = ?`).join(', ');
    
    // C4: tenant_id en WHERE
    const where = Object.entries({tenant_id: this.tenantId, ...conditions})
      .map(([k, v]) => `${k} = ?`)
      .join(' AND ');
    
    const values = [...Object.values(data), this.tenantId, ...Object.values(conditions)];
    
    return {
      sql: `UPDATE ${table} SET ${setClauses} WHERE ${where}`,
      values
    };
  }

  /**
   * DELETE solo para datos del tenant (C4).
   */
  delete(table, conditions) {
    // C4: NUNCA permitir DELETE sin tenant_id
    const where = Object.entries({tenant_id: this.tenantId, ...conditions})
      .map(([k, v]) => `${k} = ?`)
      .join(' AND ');
    
    const values = Object.values({tenant_id: this.tenantId, ...conditions});
    
    return {
      sql: `DELETE FROM ${table} WHERE ${where}`,
      values
    };
  }
}

// Uso
const tenant = new TenantQueryBuilder('restaurant_123');

// SELECT
const {sql, values} = tenant.select('messages', ['id', 'content'], {chat_id: 'abc'});
// sql: SELECT id, content FROM messages WHERE tenant_id = ? AND chat_id = ?
// values: ['restaurant_123', 'abc']

// INSERT
const insert = tenant.insert('messages', {chat_id: 'xyz', content: 'Hola'});
// Automáticamente incluye tenant_id

// UPDATE
const update = tenant.update('messages', {content: 'Nuevo'}, {id: 123});
// WHERE tenant_id = 'restaurant_123' AND id = 123

// DELETE
const del = tenant.delete('messages', {id: 123});
// WHERE tenant_id = 'restaurant_123' AND id = 123

module.exports = TenantQueryBuilder;

// spec_referenced: MT-001, PAT-002
// constraints_applied: C4
```

---

### Ejemplo 2: Row Level Security (RLS) en Supabase/PostgreSQL

```sql
-- 1. Habilitar RLS en tabla
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 2. Crear política para SELECT
CREATE POLICY select_own_tenant ON messages
  FOR SELECT
  USING (tenant_id = current_setting('app.current_tenant_id')::text);

-- 3. Crear política para INSERT
CREATE POLICY insert_own_tenant ON messages
  FOR INSERT
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::text);

-- 4. Política para UPDATE
CREATE POLICY update_own_tenant ON messages
  FOR UPDATE
  USING (tenant_id = current_setting('app.current_tenant_id')::text)
  WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::text);

-- 5. Política para DELETE
CREATE POLICY delete_own_tenant ON messages
  FOR DELETE
  USING (tenant_id = current_setting('app.current_tenant_id')::text);

-- Función para setear tenant_id en sesión
CREATE OR REPLACE FUNCTION set_tenant_id(tenant_id text)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_tenant_id', tenant_id, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Uso desde aplicación:
-- SELECT set_tenant_id('restaurant_123');
-- SELECT * FROM messages;  -- Solo retorna mensajes de restaurant_123

-- spec_referenced: MT-010, MT-011
-- constraints_applied: C4
```

**Uso en JavaScript:**
```javascript
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_KEY
);

async function queryWithTenant(tenantId) {
  // Setear tenant_id en sesión (C4)
  await supabase.rpc('set_tenant_id', { tenant_id: tenantId });
  
  // Ahora todas las queries respetan RLS
  const { data, error } = await supabase
    .from('messages')
    .select('*');  // RLS aplica filtro automáticamente
  
  return data;
}

// Uso
const messages = await queryWithTenant('restaurant_123');
// Solo retorna mensajes de restaurant_123
```

---

### Ejemplo 3: Validador Middleware de tenant_id (Express)

```javascript
// middleware/validate-tenant.js

/**
 * Middleware que valida y extrae tenant_id del JWT.
 * Bloquea requests sin tenant_id válido (C4).
 * 
 * spec_referenced: MT-001, SEG-001
 * constraints_applied: C4
 */
function validateTenant(req, res, next) {
  // Extraer tenant_id del JWT (ya decodificado por middleware anterior)
  const tenantId = req.user?.tenant_id;
  
  // C4: Rechazar si falta tenant_id
  if (!tenantId || typeof tenantId !== 'string' || tenantId.length < 3) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Valid tenant_id is required (C4)',
      code: 'MISSING_TENANT_ID'
    });
  }
  
  // Validar formato (solo alfanumérico + guiones bajos)
  if (!/^[a-z0-9_]+$/.test(tenantId)) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Invalid tenant_id format',
      code: 'INVALID_TENANT_ID'
    });
  }
  
  // Agregar tenant_id a request para uso posterior
  req.tenantId = tenantId;
  
  // Log de auditoría
  console.log(`[${new Date().toISOString()}] Request from tenant: ${tenantId} - ${req.method} ${req.path}`);
  
  next();
}

module.exports = validateTenant;

// Uso en rutas
const express = require('express');
const validateTenant = require('./middleware/validate-tenant');

const app = express();

// Aplicar a TODAS las rutas que acceden datos
app.use('/api', validateTenant);

app.get('/api/messages', async (req, res) => {
  const tenantId = req.tenantId;  // Disponible gracias al middleware
  
  const messages = await db.query(
    'SELECT * FROM messages WHERE tenant_id = ?',
    [tenantId]
  );
  
  res.json(messages);
});

// spec_referenced: MT-001, SEG-001
// constraints_applied: C4
```

---

### Ejemplo 4: Test de Aislamiento Multi-Tenant

```javascript
// test/multi-tenant-isolation.test.js
const request = require('supertest');
const app = require('../app');
const db = require('../db');

describe('Multi-Tenant Isolation (C4)', () => {
  let tenantAToken, tenantBToken;
  
  beforeAll(async () => {
    // Crear tokens JWT para 2 tenants diferentes
    tenantAToken = generateJWT({user_id: 'user_a', tenant_id: 'tenant_a'});
    tenantBToken = generateJWT({user_id: 'user_b', tenant_id: 'tenant_b'});
    
    // Insertar datos de prueba
    await db.execute(
      'INSERT INTO messages (tenant_id, chat_id, content) VALUES (?, ?, ?)',
      ['tenant_a', 'chat_1', 'Mensaje privado de A']
    );
    
    await db.execute(
      'INSERT INTO messages (tenant_id, chat_id, content) VALUES (?, ?, ?)',
      ['tenant_b', 'chat_2', 'Mensaje privado de B']
    );
  });
  
  /**
   * Test crítico C4: Tenant A NO debe ver datos de Tenant B.
   */
  test('Tenant A cannot access Tenant B data', async () => {
    const response = await request(app)
      .get('/api/messages')
      .set('Authorization', `Bearer ${tenantAToken}`)
      .expect(200);
    
    // Debe retornar SOLO mensajes de tenant_a
    expect(response.body.length).toBe(1);
    expect(response.body[0].content).toBe('Mensaje privado de A');
    expect(response.body[0].tenant_id).toBe('tenant_a');
    
    // NO debe contener datos de tenant_b
    const tenantBData = response.body.filter(m => m.tenant_id === 'tenant_b');
    expect(tenantBData.length).toBe(0);
  });
  
  /**
   * Test: Buscar por ID de otro tenant debe retornar 404.
   */
  test('Cannot access message from another tenant by ID', async () => {
    // Obtener ID de mensaje de tenant_b
    const [messageB] = await db.execute(
      'SELECT id FROM messages WHERE tenant_id = ? LIMIT 1',
      ['tenant_b']
    );
    
    // Intentar acceder con token de tenant_a
    const response = await request(app)
      .get(`/api/messages/${messageB[0].id}`)
      .set('Authorization', `Bearer ${tenantAToken}`)
      .expect(404);  // Debe dar Not Found, no Forbidden (no revelar existencia)
    
    expect(response.body.error).toBe('Message not found');
  });
  
  /**
   * Test: UPDATE solo debe afectar datos del tenant.
   */
  test('UPDATE only affects own tenant data', async () => {
    await request(app)
      .put('/api/messages/chat_2')  // chat_2 pertenece a tenant_b
      .set('Authorization', `Bearer ${tenantAToken}`)  // token de tenant_a
      .send({content: 'Intento de modificar datos de otro tenant'})
      .expect(404);  // No debe encontrar el mensaje
    
    // Verificar que datos de tenant_b NO fueron modificados
    const [unchanged] = await db.execute(
      'SELECT content FROM messages WHERE tenant_id = ? AND chat_id = ?',
      ['tenant_b', 'chat_2']
    );
    
    expect(unchanged[0].content).toBe('Mensaje privado de B');
  });
  
  /**
   * Test: DELETE solo debe borrar datos del tenant.
   */
  test('DELETE only affects own tenant data', async () => {
    await request(app)
      .delete('/api/messages/chat_2')
      .set('Authorization', `Bearer ${tenantAToken}`)
      .expect(404);
    
    // Verificar que datos de tenant_b siguen existiendo
    const [stillExists] = await db.execute(
      'SELECT id FROM messages WHERE tenant_id = ? AND chat_id = ?',
      ['tenant_b', 'chat_2']
    );
    
    expect(stillExists.length).toBe(1);
  });
  
  afterAll(async () => {
    // Limpiar datos de prueba
    await db.execute('DELETE FROM messages WHERE tenant_id IN (?, ?)', ['tenant_a', 'tenant_b']);
  });
});

// Ejecutar: npm test multi-tenant-isolation.test.js

// spec_referenced: MT-001 a MT-005
// constraints_applied: C4
```

## 🔍 >5 Ejemplos Independientes

### Caso 1: Prevenir SQL Injection en Filtros Multi-Tenant

```javascript
// NUNCA hacer esto (vulnerable a SQL injection)
function BAD_getMessages(tenantId, chatId) {
  const sql = `SELECT * FROM messages WHERE tenant_id = '${tenantId}' AND chat_id = '${chatId}'`;
  return db.execute(sql);  // ❌ PELIGROSO
}

// ✅ CORRECTO: Prepared statements
function GOOD_getMessages(tenantId, chatId) {
  const sql = 'SELECT * FROM messages WHERE tenant_id = ? AND chat_id = ?';
  return db.execute(sql, [tenantId, chatId]);
}

// Test de seguridad
const maliciousTenantId = "' OR '1'='1' --";
const result = await GOOD_getMessages(maliciousTenantId, 'chat_1');
// Con prepared statement: busca literal "' OR '1'='1' --" (no encuentra nada)
// Sin prepared statement: retornaría TODOS los mensajes de TODOS los tenants ❌

// spec_referenced: PAT-002, SEG-006
```

---

### Caso 2: Auditoría de Acceso Cross-Tenant

```javascript
// audit-logger.js
const fs = require('fs').promises;

async function logCrossTenantAttempt(req, attemptedTenantId) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    user_id: req.user.user_id,
    user_tenant_id: req.user.tenant_id,
    attempted_tenant_id: attemptedTenantId,
    endpoint: req.path,
    method: req.method,
    ip: req.ip,
    user_agent: req.headers['user-agent']
  };
  
  await fs.appendFile(
    '/var/log/mantis/cross-tenant-attempts.log',
    JSON.stringify(logEntry) + '\n'
  );
  
  // Enviar alerta si múltiples intentos del mismo usuario
  const recentAttempts = await countRecentAttempts(req.user.user_id);
  if (recentAttempts > 5) {
    await sendSecurityAlert(logEntry);
  }
}

// Middleware de auditoría
function auditTenantAccess(req, res, next) {
  const originalJson = res.json;
  
  res.json = function(data) {
    // Detectar si response contiene datos de otro tenant
    if (Array.isArray(data)) {
      const foreignData = data.filter(item => 
        item.tenant_id && item.tenant_id !== req.user.tenant_id
      );
      
      if (foreignData.length > 0) {
        logCrossTenantAttempt(req, foreignData[0].tenant_id);
        return res.status(500).json({error: 'Security violation detected'});
      }
    }
    
    originalJson.call(this, data);
  };
  
  next();
}

// spec_referenced: SEG-008, MT-002
```

---

### Caso 3: Migración de Datos Entre Tenants (Caso Especial)

```javascript
/**
 * Migrar datos de un tenant a otro (ej: fusión de negocios).
 * REQUIERE autorización de admin + validación estricta.
 * 
 * spec_referenced: MT-003
 * constraints_applied: C4
 */
async function migrateTenantData(sourceTenantId, targetTenantId, adminToken) {
  // Validar que admin tiene permisos
  if (!await isAdmin(adminToken)) {
    throw new Error('Unauthorized: Admin required');
  }
  
  // Validar que ambos tenants existen
  const [source] = await db.execute('SELECT id FROM tenants WHERE id = ?', [sourceTenantId]);
  const [target] = await db.execute('SELECT id FROM tenants WHERE id = ?', [targetTenantId]);
  
  if (!source.length || !target.length) {
    throw new Error('Source or target tenant not found');
  }
  
  // Log de auditoría ANTES de migración
  await db.execute(
    'INSERT INTO tenant_migrations (source, target, initiated_by, started_at) VALUES (?, ?, ?, NOW())',
    [sourceTenantId, targetTenantId, adminToken.user_id]
  );
  
  // Migrar datos (dentro de transaction)
  const connection = await db.getConnection();
  await connection.beginTransaction();
  
  try {
    // Actualizar tenant_id de todos los registros
    const tables = ['messages', 'users', 'documents', 'analytics'];
    
    for (const table of tables) {
      const result = await connection.execute(
        `UPDATE ${table} SET tenant_id = ? WHERE tenant_id = ?`,
        [targetTenantId, sourceTenantId]
      );
      
      console.log(`Migrated ${result.affectedRows} rows from ${table}`);
    }
    
    // Marcar tenant origen como inactivo
    await connection.execute(
      'UPDATE tenants SET is_active = FALSE, migrated_to = ? WHERE id = ?',
      [targetTenantId, sourceTenantId]
    );
    
    await connection.commit();
    
    console.log(`✅ Migration complete: ${sourceTenantId} → ${targetTenantId}`);
    
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

// spec_referenced: MT-003
```

---

### Caso 4: Particionamiento por Tenant (Escala Grande)

```sql
-- Para tenants con MUCHOS datos (>10M filas), particionar tabla por tenant
CREATE TABLE messages_partitioned (
  id BIGINT UNSIGNED AUTO_INCREMENT,
  tenant_id VARCHAR(255) NOT NULL,
  chat_id VARCHAR(255) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id, tenant_id),  -- tenant_id debe estar en PK para particionamiento
  INDEX idx_chat (chat_id)
)
PARTITION BY HASH(tenant_id)
PARTITIONS 10;  -- 10 particiones físicas

-- Beneficio: Queries de un tenant solo escanean 1/10 de los datos
-- SELECT * FROM messages_partitioned WHERE tenant_id = 'restaurant_123';
-- Solo escanea la partición correspondiente

-- spec_referenced: RES-005, ESC-001
```

---

### Caso 5: Cache Multi-Tenant con Redis

```javascript
const Redis = require('ioredis');
const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
});

/**
 * Cache con prefijo de tenant_id para aislamiento (C4).
 */
class TenantCache {
  constructor(tenantId) {
    this.tenantId = tenantId;
    this.prefix = `tenant:${tenantId}:`;
  }
  
  async get(key) {
    return redis.get(this.prefix + key);
  }
  
  async set(key, value, expirationSeconds = 300) {
    return redis.setex(this.prefix + key, expirationSeconds, value);
  }
  
  async delete(key) {
    return redis.del(this.prefix + key);
  }
  
  async deleteAll() {
    // Borrar SOLO keys de este tenant (C4)
    const keys = await redis.keys(this.prefix + '*');
    if (keys.length > 0) {
      return redis.del(...keys);
    }
  }
}

// Uso
const cache = new TenantCache('restaurant_123');
await cache.set('menu', JSON.stringify(menu));
const cachedMenu = await cache.get('menu');

// spec_referenced: RES-006, MT-001
```

---

### Caso 6: Soft Delete Multi-Tenant

```javascript
/**
 * Soft delete respetando multi-tenancy.
 * No borra físicamente, solo marca como deleted_at.
 */
async function softDelete(table, id, tenantId) {
  // C4: Solo puede borrar datos de su tenant
  const result = await db.execute(
    `UPDATE ${table} SET deleted_at = NOW() WHERE id = ? AND tenant_id = ? AND deleted_at IS NULL`,
    [id, tenantId]
  );
  
  if (result.affectedRows === 0) {
    throw new Error('Record not found or already deleted');
  }
  
  return result;
}

/**
 * Recuperar soft-deleted record.
 */
async function restore(table, id, tenantId) {
  const result = await db.execute(
    `UPDATE ${table} SET deleted_at = NULL WHERE id = ? AND tenant_id = ?`,
    [id, tenantId]
  );
  
  return result;
}

/**
 * Queries deben excluir deleted_at IS NOT NULL.
 */
async function getActiveRecords(table, tenantId) {
  return db.execute(
    `SELECT * FROM ${table} WHERE tenant_id = ? AND deleted_at IS NULL`,
    [tenantId]
  );
}

// spec_referenced: MT-001
```

## 🐞 Troubleshooting

| Error Exacto | Causa Raíz | Diagnóstico | Solución |
|--------------|------------|-------------|----------|
| `403 Forbidden: tenant_id required` | Middleware validador bloqueando request | Verificar JWT: `jq -R 'split(".") \| .[1] \| @base64d \| fromjson' <<< "TOKEN"` | **1.** Verificar que JWT tenga `tenant_id` en claims<br>**2.** Regenerar token si falta<br>**3.** Verificar middleware order en Express |
| Query retorna datos de MÚLTIPLES tenants | Falta filtro `WHERE tenant_id = ?` | `grep -rn "SELECT.*FROM" *.js \| grep -v "tenant_id"` | **1.** CRÍTICO: Agregar `WHERE tenant_id = ?` a TODAS las queries<br>**2.** Usar helper `TenantQueryBuilder`<br>**3.** Agregar test de aislamiento |
| `Duplicate entry for key 'PRIMARY'` en multi-tenant | PK no incluye tenant_id | `SHOW CREATE TABLE messages;` | **1.** Recrear tabla con PK compuesto: `PRIMARY KEY (id, tenant_id)`<br>**2.** O usar UUIDs como PK global |
| Performance degradada con muchos tenants | Índices sin tenant_id como primera columna | `EXPLAIN SELECT ... WHERE tenant_id = ? AND ...` | **1.** Recrear índices con tenant_id primero<br>**2.** Considerar particionamiento |
| RLS en Supabase no aplica | `current_setting('app.current_tenant_id')` no seteado | `SELECT current_setting('app.current_tenant_id');` | **1.** Llamar `SELECT set_tenant_id('...')` antes de queries<br>**2.** Verificar políticas RLS con `\d+ messages` |
| Cache retorna datos de otro tenant | Clave de cache sin prefijo de tenant | `redis-cli KEYS "*"` | **1.** Usar prefijo: `tenant:${tenantId}:${key}`<br>**2.** Implementar `TenantCache` class |

## ✅ Validación SDD

```bash
#!/bin/bash
# validate_multi_tenancy.sh

echo "🔍 Validando Multi-Tenancy (C4)..."

# 1. Verificar que todas las tablas tengan tenant_id
missing=$(mysql -u root -p -D mantis_production -e "
  SELECT TABLE_NAME 
  FROM INFORMATION_SCHEMA.COLUMNS 
  WHERE TABLE_SCHEMA = 'mantis_production' 
    AND TABLE_NAME NOT LIKE '%migrations%'
    AND TABLE_NAME NOT IN ('tenants')
  GROUP BY TABLE_NAME 
  HAVING SUM(COLUMN_NAME = 'tenant_id') = 0;
")

if [ -n "$missing" ]; then
  echo "❌ C4: Tablas sin tenant_id:"
  echo "$missing"
  exit 1
fi

# 2. Auditar código para queries sin tenant_id
unsafe=$(grep -rn "SELECT.*FROM\|UPDATE.*SET\|DELETE FROM" *.js *.py | grep -v "tenant_id" | grep -v "tenants")

if [ -n "$unsafe" ]; then
  echo "❌ C4: Queries sin tenant_id detectadas:"
  echo "$unsafe"
  exit 1
fi

# 3. Verificar índices tienen tenant_id
indexes=$(mysql -u root -p -D mantis_production -e "
  SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME 
  FROM INFORMATION_SCHEMA.STATISTICS 
  WHERE TABLE_SCHEMA = 'mantis_production' 
    AND SEQ_IN_INDEX = 1 
    AND COLUMN_NAME != 'tenant_id'
    AND INDEX_NAME != 'PRIMARY';
")

if [ -n "$indexes" ]; then
  echo "⚠️  Índices que NO empiezan con tenant_id (revisar manualmente):"
  echo "$indexes"
fi

echo "✅ Validación Multi-Tenancy completada"
```

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] - MT-001 a MT-011
- [[validation-checklist.md]] - Sección 3 (SQL), 4 (Qdrant), 7 (Supabase)
- [[qdrant-rag-ingestion.md]] - Implementación de C4 en vectores
- [[mysql-optimization-4gb-ram.md]] - Optimización de índices multi-tenant

---

**Validación:** ✅ C4 enforced  
**Estado:** 🟢 Production Ready
