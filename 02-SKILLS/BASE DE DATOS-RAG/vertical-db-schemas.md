---
ai_optimized: true
title: "vertical-db-schemas"
version: "1.0.0"
canonical_path: "02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md"
category: "Skill"
domain: ["database", "schema", "vertical", "multi-tenant", "sql"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
gate_status: "PASSED (7/7)"
tags:
  - sdd/skill/schema
  - sdd/skill/vertical
  - sdd/skill/multi-tenant
  - sdd/skill/sql
  - sdd/skill/restaurante
  - sdd/skill/hotel
  - sdd/skill/dental
  - sdd/skill/marketing
  - sdd/skill/corp-kb
  - lang/es
related_files:
  - "[[02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]"
---

# 🏗️ Schemas de BD por Vertical — MANTIS AGENTIC

> **Para el ZIP generator:** Este archivo es la "fuente de verdad" de tablas por negocio.
> Leer `db-selection-decision-tree.md` primero para saber qué stack usar.
> Luego copiar el schema de la sección correspondiente al vertical del cliente.
>
> **Convención absoluta (C4):**
> - `tenant_id` es siempre el **segundo campo** (después del `id`)
> - Todos los índices compuestos empiezan con `tenant_id`
> - FK a tabla `tenants` en todos los schemas

---

## 📐 Schema Base — Obligatorio en TODOS los Verticales

```sql
-- ═══════════════════════════════════════════════════════════════════
-- TABLA MAESTRA DE TENANTS (una sola, compartida entre todos)
-- C4: Registro de todos los clientes del sistema
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE tenants (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL UNIQUE,    -- C4: identificador único
    nombre_negocio  VARCHAR(200)  NOT NULL,
    vertical        ENUM(
                      'restaurante','churrascaria','fondue','pizzaria',
                      'delivery_alimentos','sushi_bar','bar_nocturno',
                      'cafeteria','cafeteria_corporativa','confiteria',
                      'parrilla_gaucha','restaurante_tematico','italiano',
                      'hotel','pousada','camping','hostel',
                      'dental_general','dental_ortodoncia','dental_implante',
                      'dental_estetica','dental_infantil','dental_clinica',
                      'marketing','turismo','agencia_ia',
                      'abogados','corp_kb'
                    )             NOT NULL,
    db_stack        ENUM('A','B','C','D','E','F') NOT NULL,
    telefone_wa     VARCHAR(20),                      -- Número WhatsApp del negocio
    email           VARCHAR(200),
    pais            VARCHAR(3)    DEFAULT 'BRA',
    cidade          VARCHAR(100),
    plano           ENUM('basico','full','enterprise') DEFAULT 'basico',
    ativo           BOOLEAN       DEFAULT TRUE,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_vertical    (vertical),
    INDEX idx_ativo       (ativo)
) ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

---

## 🍕 VERTICAL 1: Gastronomía

> Cubre: restaurante tradicional, churrascaria, fondue, pizzaria, sushi bar,
> bar nocturno, cafetería, cafetería corporativa, confitería, parrilla gaucha,
> restaurante temático, italiano, delivery de alimentos.

### Schema Principal

```sql
-- ═══════════════════════════════════════════════════════════════════
-- GASTRONOMÍA — Schema completo para todos los sub-verticales
-- C4: tenant_id en todas las tablas
-- ═══════════════════════════════════════════════════════════════════

-- ── Mesas / Espacios ────────────────────────────────────────────────────────
CREATE TABLE mesas (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    numero          VARCHAR(20)  NOT NULL,                 -- "Mesa 7", "Salón A", "Mesa Vip"
    capacidad       TINYINT      NOT NULL DEFAULT 4,
    tipo            ENUM('interna','externa','privativa','barra','delivery','evento')
                                 DEFAULT 'interna',
    disponible      BOOLEAN      DEFAULT TRUE,
    piso            TINYINT      DEFAULT 1,
    descripcion     VARCHAR(200),
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_disponible   (tenant_id, disponible),        -- C4
    INDEX idx_tenant_tipo         (tenant_id, tipo),
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Categorías del Menú ─────────────────────────────────────────────────────
CREATE TABLE categorias_menu (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nombre          VARCHAR(100) NOT NULL,
    descripcion     VARCHAR(300),
    icono_emoji     VARCHAR(10),
    orden_display   SMALLINT     DEFAULT 0,
    ativa           BOOLEAN      DEFAULT TRUE,

    INDEX idx_tenant_ativa    (tenant_id, ativa),                 -- C4
    INDEX idx_tenant_orden    (tenant_id, orden_display),
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Items del Menú ──────────────────────────────────────────────────────────
-- Aplica a: restaurante, churrascaria, sushi, pizzaria, fondue, bar, cafetería
CREATE TABLE menu_items (
    id              VARCHAR(36)    NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)    NOT NULL,              -- C4
    categoria_id    VARCHAR(36)    NOT NULL,
    codigo          VARCHAR(50),                          -- Código interno (ej: "PIZZA-001")
    nombre          VARCHAR(200)   NOT NULL,
    descripcion     TEXT,
    ingredientes    TEXT,                                  -- Para RAG sobre alérgenos
    precio          DECIMAL(10,2)  NOT NULL,
    precio_delivery DECIMAL(10,2),                        -- Precio diferenciado delivery
    -- Campos específicos por sub-vertical:
    peso_gramos     SMALLINT,                             -- Churrascaria: peso del corte
    tipo_corte      VARCHAR(100),                         -- Churrascaria: picanha, costela, etc.
    tipo_pizza      ENUM('classica','especial','premium','borda_recheada'), -- Pizzaria
    tamanho         ENUM('P','M','G','GG','familia'),     -- Pizzaria/delivery
    tipo_sushi      ENUM('niguiri','uramaki','temaki','sashimi','combinado'), -- Sushi
    tipo_fondue     ENUM('queijo','chocolate','carne','fruta'), -- Fondue
    grau_alcohol    SMALLINT,                             -- Bar: graduación alcohólica
    origem_cafe     VARCHAR(100),                         -- Cafetería: origem do grão
    tipo_chocolate  VARCHAR(100),                         -- Chocolateria: tipo de chocolate
    tiempo_preparo_min TINYINT     DEFAULT 15,
    disponible      BOOLEAN        DEFAULT TRUE,
    disponible_delivery BOOLEAN    DEFAULT TRUE,
    alergenos       SET('gluten','lactose','frutos_mar','amendoim','ovo','soja'),
    imagem_url      VARCHAR(500),
    content_hash    VARCHAR(64),                           -- Para RAG updates (C5)
    orden_display   SMALLINT       DEFAULT 0,
    created_at      DATETIME       DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_cat      (tenant_id, categoria_id),          -- C4
    INDEX idx_tenant_disp     (tenant_id, disponible),
    INDEX idx_tenant_hash     (tenant_id, content_hash),           -- Para RAG sync
    FOREIGN KEY (tenant_id)    REFERENCES tenants(tenant_id),
    FOREIGN KEY (categoria_id) REFERENCES categorias_menu(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Reservas ─────────────────────────────────────────────────────────────────
-- Aplica a: restaurante, churrascaria, sushi, bar (eventos), fondue
CREATE TABLE reservas (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    mesa_id         VARCHAR(36),
    -- Datos del cliente:
    nome_cliente    VARCHAR(200) NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(200),
    -- Fecha y tiempo:
    data_reserva    DATE         NOT NULL,
    hora_reserva    TIME         NOT NULL,
    duracao_min     SMALLINT     DEFAULT 90,
    -- Detalles:
    num_adultos     TINYINT      NOT NULL DEFAULT 2,
    num_criancas    TINYINT      DEFAULT 0,
    ocasiao         ENUM('normal','aniversario','casamento','corporativo','evento','outro'),
    observacoes     TEXT,
    -- Campos específicos por sub-vertical:
    tipo_rodizio    ENUM('carne','frango','misto','vegetariano'), -- Churrascaria
    preferencia_lugar ENUM('interna','externa','janela','privativa'), -- General
    show_ao_vivo    BOOLEAN      DEFAULT FALSE,            -- Bar nocturno
    -- Estado:
    status          ENUM('pendente','confirmada','cancelada','no_show','concluida')
                                 DEFAULT 'pendente',
    canal           ENUM('whatsapp','telefone','web','presencial','instagram')
                                 DEFAULT 'whatsapp',
    -- Notificaciones:
    lembrete_24h_enviado BOOLEAN DEFAULT FALSE,
    lembrete_2h_enviado  BOOLEAN DEFAULT FALSE,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_data     (tenant_id, data_reserva),          -- C4
    INDEX idx_tenant_tel      (tenant_id, telefone),
    INDEX idx_tenant_status   (tenant_id, status),
    INDEX idx_tenant_canal    (tenant_id, canal),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id),
    FOREIGN KEY (mesa_id)     REFERENCES mesas(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Pedidos (especialmente para delivery y bar) ─────────────────────────────
CREATE TABLE pedidos (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    reserva_id      VARCHAR(36),
    mesa_id         VARCHAR(36),
    -- Datos del cliente (para delivery sin reserva):
    nome_cliente    VARCHAR(200),
    telefone        VARCHAR(20),
    -- Tipos:
    tipo            ENUM('mesa','delivery','balcao','app')  NOT NULL,
    -- Para delivery:
    endereco_entrega TEXT,
    complemento     VARCHAR(200),
    bairro          VARCHAR(100),
    ponto_referencia VARCHAR(200),
    taxa_entrega    DECIMAL(8,2)  DEFAULT 0,
    tempo_entrega_min SMALLINT,
    -- Totales:
    subtotal        DECIMAL(10,2) NOT NULL DEFAULT 0,
    desconto        DECIMAL(10,2) DEFAULT 0,
    total           DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Estado:
    status          ENUM('recebido','confirmado','preparo','pronto','entregue',
                         'cancelado','estornado')
                                  DEFAULT 'recebido',
    -- Pagamento:
    forma_pagamento ENUM('dinheiro','pix','cartao_debito','cartao_credito',
                         'vale_refeicao','ifood','rappi','outros'),
    pago            BOOLEAN       DEFAULT FALSE,
    -- Notas:
    obs_cozinha     TEXT,
    obs_entrega     TEXT,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_status  (tenant_id, status),                 -- C4
    INDEX idx_tenant_tipo    (tenant_id, tipo),
    INDEX idx_tenant_data    (tenant_id, created_at DESC),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Ítems de Pedidos ────────────────────────────────────────────────────────
CREATE TABLE pedido_items (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    pedido_id       VARCHAR(36)   NOT NULL,
    menu_item_id    VARCHAR(36)   NOT NULL,
    nome_item       VARCHAR(200)  NOT NULL,               -- Desnormalizado (precio puede cambiar)
    quantidade      TINYINT       NOT NULL DEFAULT 1,
    preco_unitario  DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    personalizacoes TEXT,                                  -- "sem cebola, molho separado"
    status_preparo  ENUM('aguardando','preparo','pronto') DEFAULT 'aguardando',

    INDEX idx_tenant_pedido  (tenant_id, pedido_id),              -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (pedido_id)  REFERENCES pedidos(id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Clientes (CRM básico sin EspoCRM) ──────────────────────────────────────
CREATE TABLE clientes_gastro (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    telefone        VARCHAR(20)  NOT NULL,
    nome            VARCHAR(200),
    email           VARCHAR(200),
    data_nascimento DATE,
    -- Histórico:
    total_visitas   SMALLINT     DEFAULT 0,
    total_pedidos   SMALLINT     DEFAULT 0,
    total_gasto     DECIMAL(12,2) DEFAULT 0,
    ultima_visita   DATETIME,
    -- Preferencias:
    restricoes_alimentares TEXT,
    mesa_preferida  VARCHAR(50),
    preferencias    TEXT,
    -- Fidelidade:
    pontos_fidelidade INT        DEFAULT 0,
    nivel_vip       ENUM('normal','vip','premium') DEFAULT 'normal',
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_tenant_tel  (tenant_id, telefone),              -- C4: UK por tenant
    INDEX idx_tenant_vip      (tenant_id, nivel_vip),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Configuración del Negocio ────────────────────────────────────────────────
CREATE TABLE config_negocio (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    chave           VARCHAR(100) NOT NULL,
    valor           TEXT         NOT NULL,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_tenant_chave (tenant_id, chave),                -- C4
    FOREIGN KEY (tenant_id)    REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
-- Claves predefinidas por sub-vertical en tabla de seeds (ver sección seeds)

-- ── Eventos / Shows (Bar nocturno + Restaurante temático) ───────────────────
CREATE TABLE eventos (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    titulo          VARCHAR(200)  NOT NULL,
    descricao       TEXT,
    artista         VARCHAR(200),                          -- Bar: nombre del artista/banda
    genero_musical  VARCHAR(100),
    data_evento     DATE          NOT NULL,
    hora_inicio     TIME          NOT NULL,
    hora_fim        TIME,
    capacidade      SMALLINT,
    preco_entrada   DECIMAL(8,2)  DEFAULT 0,
    consumacao_min  DECIMAL(8,2)  DEFAULT 0,
    status          ENUM('agendado','cancelado','realizado') DEFAULT 'agendado',
    imagem_url      VARCHAR(500),
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_data     (tenant_id, data_evento),           -- C4
    INDEX idx_tenant_status   (tenant_id, status),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Rodízio Control (específico Churrascaria) ───────────────────────────────
CREATE TABLE rodizio_sessoes (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    reserva_id      VARCHAR(36)  NOT NULL,
    mesa_id         VARCHAR(36)  NOT NULL,
    tipo_rodizio    ENUM('carne','frango','misto','premium','vegetariano'),
    hora_inicio     DATETIME     NOT NULL,
    hora_fim        DATETIME,
    num_pessoas     TINYINT      NOT NULL,
    total_rodizio   DECIMAL(10,2),
    carnes_servidas JSON,                                  -- Array de cortes servidos
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_reserva  (tenant_id, reserva_id),            -- C4
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id),
    FOREIGN KEY (reserva_id)  REFERENCES reservas(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
```

### Seeds de Configuración por Sub-vertical

```sql
-- ── Seeds: config_negocio por sub-vertical ──────────────────────────────────
-- Insertar después de crear el tenant

-- Restaurante tradicional
INSERT INTO config_negocio (id, tenant_id, chave, valor) VALUES
(UUID(), ?, 'horario_abertura',     '12:00'),
(UUID(), ?, 'horario_fechamento',   '23:00'),
(UUID(), ?, 'dias_funcionamento',   'Seg-Dom'),
(UUID(), ?, 'capacidade_total',     '60'),
(UUID(), ?, 'tempo_reserva_padrao', '90'),
(UUID(), ?, 'msg_boas_vindas',      'Bem-vindo! 🍽️ Como posso ajudar?'),
(UUID(), ?, 'aceita_delivery',      'false'),
(UUID(), ?, 'politica_cancelamento','Cancelar até 2h antes sem custo');

-- Churrascaria (adicional)
INSERT INTO config_negocio (id, tenant_id, chave, valor) VALUES
(UUID(), ?, 'preco_rodizio_adulto',  '89.90'),
(UUID(), ?, 'preco_rodizio_crianca', '44.90'),
(UUID(), ?, 'tipos_rodizio',         'carne,frango,misto,premium'),
(UUID(), ?, 'cortes_principais',     'picanha,costela,fraldinha,maminha,alcatra');

-- Pizzaria (adicional)
INSERT INTO config_negocio (id, tenant_id, chave, valor) VALUES
(UUID(), ?, 'tamanhos_pizza',       'P,M,G,GG,Família'),
(UUID(), ?, 'tempo_entrega_padrao', '45'),
(UUID(), ?, 'raio_delivery_km',     '5'),
(UUID(), ?, 'aceita_delivery',      'true'),
(UUID(), ?, 'pedido_minimo',        '25.00');

-- Bar nocturno (adicional)
INSERT INTO config_negocio (id, tenant_id, chave, valor) VALUES
(UUID(), ?, 'tem_shows',           'true'),
(UUID(), ?, 'consumacao_minima',   '30.00'),
(UUID(), ?, 'horario_abertura',    '20:00'),
(UUID(), ?, 'horario_fechamento',  '04:00'),
(UUID(), ?, 'idade_minima',        '18');
```

### 10+ Queries de Ejemplo para Gastronomía

```sql
-- GASTR-Q1: Disponibilidade de mesas para uma data/hora (C4)
SELECT m.numero, m.capacidade, m.tipo
FROM mesas m
WHERE m.tenant_id = ?                                              -- C4
  AND m.disponivel = TRUE
  AND m.id NOT IN (
    SELECT r.mesa_id FROM reservas r
    WHERE r.tenant_id = ?                                          -- C4
      AND r.data_reserva = ?
      AND r.hora_reserva BETWEEN ? AND ADDTIME(?, '01:30:00')
      AND r.status NOT IN ('cancelada','no_show')
  )
ORDER BY m.tipo, m.capacidade;

-- GASTR-Q2: Pedidos ativos na cozinha agora (C4)
SELECT p.id, p.mesa_id, p.tipo,
       GROUP_CONCAT(pi.nome_item SEPARATOR ', ') AS items,
       p.obs_cozinha,
       TIMESTAMPDIFF(MINUTE, p.created_at, NOW()) AS minutos_aguardando
FROM pedidos p
JOIN pedido_items pi ON p.id = pi.pedido_id AND pi.tenant_id = ?  -- C4
WHERE p.tenant_id = ?                                              -- C4
  AND p.status IN ('recebido','preparo')
GROUP BY p.id
ORDER BY p.created_at ASC;

-- GASTR-Q3: Cardápio completo disponível para o bot (C4)
SELECT c.nome AS categoria, c.icono_emoji,
       m.nome, m.descricao, m.preco,
       m.preco_delivery, m.tempo_preparo_min,
       m.alergenos, m.tipo_pizza, m.tipo_sushi, m.tipo_corte
FROM menu_items m
JOIN categorias_menu c ON m.categoria_id = c.id AND c.tenant_id = ?  -- C4
WHERE m.tenant_id = ?                                                  -- C4
  AND m.disponivel = TRUE
ORDER BY c.ordem_display, m.ordem_display;

-- GASTR-Q4: Faturamento por período (billing para relatório ao cliente) (C4)
SELECT DATE(created_at) AS data,
       COUNT(*)          AS total_pedidos,
       SUM(total)        AS faturamento,
       AVG(total)        AS ticket_medio,
       SUM(CASE WHEN tipo='delivery' THEN 1 ELSE 0 END) AS pedidos_delivery
FROM pedidos
WHERE tenant_id = ?                                                    -- C4
  AND status    = 'entregue'
  AND created_at BETWEEN ? AND ?
GROUP BY DATE(created_at)
ORDER BY data DESC;

-- GASTR-Q5: Top 10 items mais pedidos (para RAG atualizar cardápio) (C4)
SELECT mi.nome, mi.categoria_id, COUNT(pi.id) AS vezes_pedido,
       SUM(pi.quantidade) AS unidades_vendidas,
       AVG(pi.preco_unitario) AS preco_medio
FROM pedido_items pi
JOIN menu_items mi ON pi.menu_item_id = mi.id AND mi.tenant_id = ?    -- C4
WHERE pi.tenant_id = ?                                                 -- C4
  AND pi.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY mi.id, mi.nome, mi.categoria_id
ORDER BY vezes_pedido DESC
LIMIT 10;

-- GASTR-Q6: Clientes VIP para promoção personalizada (C4)
SELECT nome, telefone, total_visitas, total_gasto,
       ultima_visita, preferencias, restricoes_alimentares
FROM clientes_gastro
WHERE tenant_id = ?                                                    -- C4
  AND nivel_vip  IN ('vip','premium')
  AND ultima_visita > DATE_SUB(NOW(), INTERVAL 60 DAY)
ORDER BY total_gasto DESC;

-- GASTR-Q7: Reservas do dia com lembrete pendente (para agente enviar WA) (C4)
SELECT r.id, r.nome_cliente, r.telefone, r.hora_reserva,
       r.num_adultos, r.mesa_id, r.ocasiao,
       r.tipo_rodizio, r.observacoes
FROM reservas r
WHERE r.tenant_id = ?                                                  -- C4
  AND r.data_reserva = CURDATE()
  AND r.status = 'confirmada'
  AND r.lembrete_2h_enviado = FALSE
  AND r.hora_reserva <= ADDTIME(NOW(), '02:00:00')
ORDER BY r.hora_reserva ASC;

-- GASTR-Q8: Relatório de shows do mês (bar nocturno) (C4)
SELECT e.titulo, e.artista, e.genero_musical, e.data_evento,
       e.hora_inicio, e.preco_entrada, e.capacidade,
       COUNT(r.id) AS reservas_confirmadas
FROM eventos e
LEFT JOIN reservas r ON r.tenant_id = e.tenant_id
    AND r.data_reserva = e.data_evento
    AND r.show_ao_vivo = TRUE
    AND r.status = 'confirmada'
WHERE e.tenant_id = ?                                                  -- C4
  AND MONTH(e.data_evento) = MONTH(NOW())
GROUP BY e.id
ORDER BY e.data_evento;

-- GASTR-Q9: Análise de vendas por forma de pagamento (C4)
SELECT forma_pagamento,
       COUNT(*)    AS total_pedidos,
       SUM(total)  AS valor_total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentual
FROM pedidos
WHERE tenant_id  = ?                                                   -- C4
  AND status     = 'entregue'
  AND pago       = TRUE
  AND created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY forma_pagamento
ORDER BY valor_total DESC;

-- GASTR-Q10: Ocupação por turno (para gestão de pessoal) (C4)
SELECT
  HOUR(hora_reserva) AS hora,
  DAYOFWEEK(data_reserva) AS dia_semana,
  COUNT(*) AS total_reservas,
  SUM(num_adultos + num_criancas) AS total_pessoas
FROM reservas
WHERE tenant_id   = ?                                                  -- C4
  AND status      NOT IN ('cancelada')
  AND data_reserva BETWEEN DATE_SUB(NOW(), INTERVAL 30 DAY) AND NOW()
GROUP BY HOUR(hora_reserva), DAYOFWEEK(data_reserva)
ORDER BY dia_semana, hora;

-- GASTR-Q11: Itens com alergênio para resposta rápida no bot (C4 + RAG)
SELECT nome, descricao, alergenos, preco
FROM menu_items
WHERE tenant_id = ?                                                    -- C4
  AND disponivel = TRUE
  AND FIND_IN_SET(?, alergenos) > 0;
-- Uso: ?, alergenos = 'lactose' para filtrar itens com lactose
```

---

## 🏨 VERTICAL 2: Hospedagem

> Cobre: hotel, pousada, camping, hostel, glamping.

### Schema Principal

```sql
-- ═══════════════════════════════════════════════════════════════════
-- HOSPEDAGEM — Schema completo
-- Especializações: hotel (quartos numerados), pousada (chalés), camping (parcelas)
-- ═══════════════════════════════════════════════════════════════════

-- ── Unidades de Hospedagem ──────────────────────────────────────────────────
-- Quarto (hotel), Chalé (pousada), Parcela (camping), Bangalô (glamping)
CREATE TABLE unidades_hospedagem (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,                -- C4
    numero          VARCHAR(20)   NOT NULL,                 -- "101", "Chalé Araucária"
    tipo            ENUM('standard','superior','luxo','suite','suite_master',
                         'chale','bangalo','parcela_camping','parcela_glamping',
                         'dormitorio_hostel','quarto_hostel')  NOT NULL,
    capacidade_adultos  TINYINT   NOT NULL DEFAULT 2,
    capacidade_criancas TINYINT   DEFAULT 0,
    preco_diaria    DECIMAL(10,2) NOT NULL,
    preco_diaria_fds DECIMAL(10,2),                        -- Preço fim de semana
    preco_feriado   DECIMAL(10,2),
    piso            TINYINT       DEFAULT 1,
    vista           ENUM('jardim','piscina','mar','montanha','cidade','sem_vista')
                                  DEFAULT 'jardim',
    -- Amenidades (campos booleanos para busca rápida):
    tem_ar           BOOLEAN  DEFAULT FALSE,
    tem_frigobar     BOOLEAN  DEFAULT FALSE,
    tem_banheira     BOOLEAN  DEFAULT FALSE,
    tem_varanda      BOOLEAN  DEFAULT FALSE,
    tem_lareira      BOOLEAN  DEFAULT FALSE,               -- Pousada / Chalé
    tem_cozinha      BOOLEAN  DEFAULT FALSE,               -- Chalé self-service
    tem_wifi         BOOLEAN  DEFAULT TRUE,
    aceita_pets      BOOLEAN  DEFAULT FALSE,
    acessivel        BOOLEAN  DEFAULT FALSE,               -- PCD
    -- Camping específico:
    sombra           BOOLEAN  DEFAULT FALSE,               -- Camping: tem sombra?
    ponto_eletrico   BOOLEAN  DEFAULT FALSE,               -- Camping: tomada disponível?
    area_m2          SMALLINT,                             -- Camping: área da parcela
    -- Status:
    disponivel       BOOLEAN  DEFAULT TRUE,
    em_manutencao    BOOLEAN  DEFAULT FALSE,
    descricao        TEXT,
    imagens_urls     JSON,                                 -- Array de URLs de fotos
    content_hash     VARCHAR(64),                          -- Para RAG sync
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_tipo      (tenant_id, tipo),                  -- C4
    INDEX idx_tenant_disp      (tenant_id, disponivel),
    INDEX idx_tenant_preco     (tenant_id, preco_diaria),
    FOREIGN KEY (tenant_id)    REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Reservas de Hospedagem ──────────────────────────────────────────────────
CREATE TABLE reservas_hospedagem (
    id                  VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id           VARCHAR(50)   NOT NULL,            -- C4
    unidade_id          VARCHAR(36)   NOT NULL,
    -- Hóspede principal:
    nome_hospede        VARCHAR(200)  NOT NULL,
    telefone            VARCHAR(20)   NOT NULL,
    email               VARCHAR(200),
    cpf_passaporte      VARCHAR(30),
    nacionalidade       VARCHAR(5)    DEFAULT 'BR',
    -- Datas:
    checkin_data        DATE          NOT NULL,
    checkout_data       DATE          NOT NULL,
    checkin_realizado   DATETIME,
    checkout_realizado  DATETIME,
    -- Composição:
    adultos             TINYINT       NOT NULL DEFAULT 1,
    criancas            TINYINT       DEFAULT 0,
    bebes               TINYINT       DEFAULT 0,
    -- Financeiro:
    preco_diaria_cobrado DECIMAL(10,2) NOT NULL,
    num_noites          TINYINT       NOT NULL,
    subtotal            DECIMAL(10,2) NOT NULL,
    desconto            DECIMAL(10,2) DEFAULT 0,
    total               DECIMAL(10,2) NOT NULL,
    taxa_cidade         DECIMAL(10,2) DEFAULT 0,           -- Imposto turismo
    sinal_pago          DECIMAL(10,2) DEFAULT 0,
    saldo_devedor       DECIMAL(10,2),
    -- Preferencias:
    preferencias        TEXT,
    alergias_alimentares TEXT,
    hora_chegada_prevista TIME,
    motivo_viagem       ENUM('lazer','negocios','lua_de_mel','familia','outro'),
    como_conheceu       ENUM('instagram','google','indicacao','booking','airbnb',
                             'whatsapp','outro'),
    -- Estado:
    status              ENUM('pendente','confirmada','cancelada',
                              'no_show','hospedado','concluida')
                                      DEFAULT 'pendente',
    canal               ENUM('whatsapp','email','booking','airbnb',
                              'presencial','telefone','site'),
    -- Notificaciones programadas:
    msg_boas_vindas_enviada BOOLEAN   DEFAULT FALSE,
    msg_pre_chegada_enviada BOOLEAN   DEFAULT FALSE,
    msg_checkout_enviada    BOOLEAN   DEFAULT FALSE,
    created_at          DATETIME      DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_checkin  (tenant_id, checkin_data),           -- C4
    INDEX idx_tenant_status   (tenant_id, status),
    INDEX idx_tenant_telefone (tenant_id, telefone),
    INDEX idx_tenant_unidade  (tenant_id, unidade_id),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id),
    FOREIGN KEY (unidade_id)  REFERENCES unidades_hospedagem(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Hóspedes Adicionais ─────────────────────────────────────────────────────
CREATE TABLE hospedes_adicionais (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                 -- C4
    reserva_id      VARCHAR(36)  NOT NULL,
    nome            VARCHAR(200) NOT NULL,
    documento       VARCHAR(50),
    data_nascimento DATE,
    eh_crianca      BOOLEAN      DEFAULT FALSE,

    INDEX idx_tenant_reserva (tenant_id, reserva_id),              -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (reserva_id) REFERENCES reservas_hospedagem(id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Serviços / Consumos durante a hospedagem ─────────────────────────────────
CREATE TABLE servicos_hospedagem (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,                -- C4
    reserva_id      VARCHAR(36)   NOT NULL,
    descricao       VARCHAR(300)  NOT NULL,
    tipo            ENUM('cafe_da_manha','almoco','jantar','frigobar',
                         'lavanderia','passeio','transfer','spa',
                         'aluguel_equipamento','outro'),
    valor           DECIMAL(10,2) NOT NULL,
    data_servico    DATE          DEFAULT (CURDATE()),
    pago            BOOLEAN       DEFAULT FALSE,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_reserva (tenant_id, reserva_id),              -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (reserva_id) REFERENCES reservas_hospedagem(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Mensagens Programadas para Hóspedes ─────────────────────────────────────
CREATE TABLE mensagens_hospedes (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                 -- C4
    reserva_id      VARCHAR(36)  NOT NULL,
    tipo            ENUM('confirmacao','pre_chegada_72h','pre_chegada_24h',
                          'boas_vindas','mid_stay','pre_checkout','feedback',
                          'promocao_retorno'),
    canal           ENUM('whatsapp','email','sms') DEFAULT 'whatsapp',
    enviado         BOOLEAN      DEFAULT FALSE,
    enviado_at      DATETIME,
    conteudo_custom TEXT,                                  -- Personalização pelo agente
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_tipo    (tenant_id, tipo),                    -- C4
    INDEX idx_tenant_enviado (tenant_id, enviado),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (reserva_id) REFERENCES reservas_hospedagem(id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Avaliações / Reviews ─────────────────────────────────────────────────────
CREATE TABLE avaliacoes_hospedagem (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                 -- C4
    reserva_id      VARCHAR(36),
    nome_hospede    VARCHAR(200),
    nota_geral      TINYINT      CHECK (nota_geral BETWEEN 1 AND 5),
    nota_limpeza    TINYINT      CHECK (nota_limpeza BETWEEN 1 AND 5),
    nota_atendimento TINYINT     CHECK (nota_atendimento BETWEEN 1 AND 5),
    nota_localizacao TINYINT     CHECK (nota_localizacao BETWEEN 1 AND 5),
    comentario      TEXT,
    plataforma      ENUM('whatsapp','google','booking','airbnb','tripadvisor','site'),
    respondido      BOOLEAN      DEFAULT FALSE,
    resposta        TEXT,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_nota    (tenant_id, nota_geral),              -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
```

### 10 Queries de Exemplo para Hospedagem

```sql
-- HOSP-Q1: Disponibilidade para datas solicitadas (C4)
SELECT u.numero, u.tipo, u.capacidade_adultos, u.vista,
       u.tem_ar, u.tem_varanda, u.aceita_pets,
       CASE WHEN DAYOFWEEK(?) IN (1,7) THEN u.preco_diaria_fds
            ELSE u.preco_diaria END AS preco_aplicavel
FROM unidades_hospedagem u
WHERE u.tenant_id = ?                                              -- C4
  AND u.disponivel = TRUE
  AND u.em_manutencao = FALSE
  AND u.capacidade_adultos >= ?
  AND u.id NOT IN (
    SELECT unidade_id FROM reservas_hospedagem
    WHERE tenant_id = ?                                            -- C4
      AND status NOT IN ('cancelada','no_show')
      AND checkin_data < ? AND checkout_data > ?
  )
ORDER BY u.preco_diaria ASC;

-- HOSP-Q2: Ocupação da semana atual (C4)
SELECT u.numero, u.tipo,
       r.nome_hospede, r.telefone, r.adultos,
       r.checkin_data, r.checkout_data,
       DATEDIFF(r.checkout_data, r.checkin_data) AS noites,
       r.status
FROM reservas_hospedagem r
JOIN unidades_hospedagem u ON r.unidade_id = u.id AND u.tenant_id = ?  -- C4
WHERE r.tenant_id  = ?                                             -- C4
  AND r.status     IN ('confirmada','hospedado')
  AND r.checkin_data <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)
  AND r.checkout_data >= CURDATE()
ORDER BY r.checkin_data, u.numero;

-- HOSP-Q3: Check-ins de hoje (C4)
SELECT r.id, r.nome_hospede, r.telefone, u.numero,
       r.hora_chegada_prevista, r.adultos, r.criancas,
       r.motivo_viagem, r.preferencias,
       r.msg_boas_vindas_enviada
FROM reservas_hospedagem r
JOIN unidades_hospedagem u ON r.unidade_id = u.id
WHERE r.tenant_id    = ?                                           -- C4
  AND r.checkin_data = CURDATE()
  AND r.status       = 'confirmada'
ORDER BY r.hora_chegada_prevista;

-- HOSP-Q4: Taxa de ocupação mensal (C4)
SELECT MONTH(r.checkin_data) AS mes,
       COUNT(DISTINCT r.unidade_id) AS unidades_ocupadas,
       (SELECT COUNT(*) FROM unidades_hospedagem
        WHERE tenant_id = ? AND disponivel = TRUE) AS total_unidades,
       ROUND(COUNT(DISTINCT r.unidade_id) * 100.0 /
         (SELECT COUNT(*) FROM unidades_hospedagem
          WHERE tenant_id = ? AND disponivel = TRUE), 1) AS taxa_ocupacao_pct,
       SUM(r.total) AS receita_total
FROM reservas_hospedagem r
WHERE r.tenant_id = ?                                              -- C4
  AND r.status IN ('concluida','hospedado')
  AND YEAR(r.checkin_data) = YEAR(NOW())
GROUP BY MONTH(r.checkin_data)
ORDER BY mes;

-- HOSP-Q5: Hóspedes para envio de mensagem pré-chegada 24h (C4)
SELECT r.id, r.nome_hospede, r.telefone, r.email,
       r.checkin_data, r.hora_chegada_prevista,
       u.numero, u.tipo, r.adultos, r.preferencias
FROM reservas_hospedagem r
JOIN unidades_hospedagem u ON r.unidade_id = u.id
WHERE r.tenant_id = ?                                              -- C4
  AND r.status    = 'confirmada'
  AND r.checkin_data = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
  AND r.msg_pre_chegada_enviada = FALSE
ORDER BY r.checkin_data;

-- HOSP-Q6: Consumos pendentes de pagamento (C4)
SELECT r.nome_hospede, u.numero, r.checkin_data, r.checkout_data,
       SUM(s.valor) AS consumos_pendentes,
       r.saldo_devedor + SUM(s.valor) AS total_a_pagar
FROM servicos_hospedagem s
JOIN reservas_hospedagem r ON s.reserva_id = r.id AND r.tenant_id = ?  -- C4
JOIN unidades_hospedagem u ON r.unidade_id = u.id
WHERE s.tenant_id = ?                                              -- C4
  AND s.pago = FALSE
  AND r.status = 'hospedado'
GROUP BY r.id, r.nome_hospede, u.numero
ORDER BY r.checkout_data;

-- HOSP-Q7: Média de avaliações (para responder no WhatsApp) (C4)
SELECT ROUND(AVG(nota_geral), 1) AS media_geral,
       ROUND(AVG(nota_limpeza), 1) AS media_limpeza,
       ROUND(AVG(nota_atendimento), 1) AS media_atendimento,
       COUNT(*) AS total_avaliacoes
FROM avaliacoes_hospedagem
WHERE tenant_id = ?                                                -- C4
  AND created_at > DATE_SUB(NOW(), INTERVAL 90 DAY);

-- HOSP-Q8: Revenue por tipo de unidade (C4)
SELECT u.tipo,
       COUNT(r.id) AS total_reservas,
       SUM(r.total) AS receita_total,
       AVG(r.num_noites) AS media_noites,
       AVG(r.preco_diaria_cobrado) AS diaria_media
FROM reservas_hospedagem r
JOIN unidades_hospedagem u ON r.unidade_id = u.id
WHERE r.tenant_id = ?                                              -- C4
  AND r.status IN ('concluida')
  AND r.checkin_data > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY u.tipo
ORDER BY receita_total DESC;

-- HOSP-Q9: Camping — parcelas disponíveis com sombra e elétrica (C4)
SELECT numero, area_m2, sombra, ponto_eletrico, preco_diaria, aceita_pets
FROM unidades_hospedagem
WHERE tenant_id    = ?                                             -- C4
  AND tipo         IN ('parcela_camping','parcela_glamping')
  AND disponivel   = TRUE
  AND sombra       = ?    -- TRUE/FALSE filtro
  AND ponto_eletrico = ?  -- TRUE/FALSE filtro
ORDER BY preco_diaria;

-- HOSP-Q10: Ranking canal de captação (para investimento em marketing) (C4)
SELECT canal,
       COUNT(*) AS total_reservas,
       SUM(total) AS receita_total,
       ROUND(AVG(total), 2) AS ticket_medio
FROM reservas_hospedagem
WHERE tenant_id  = ?                                               -- C4
  AND status     IN ('confirmada','hospedado','concluida')
  AND created_at > DATE_SUB(NOW(), INTERVAL 6 MONTH)
GROUP BY canal
ORDER BY total_reservas DESC;
```

---

## 🦷 VERTICAL 3: Odontologia

> Cobre: clínica geral, ortodoncia, implante, estética dental, infantil, universitária.

### Schema Principal

```sql
-- ═══════════════════════════════════════════════════════════════════
-- ODONTOLOGIA — Schema completo
-- ATENÇÃO LGPD: Dados de saúde são dados sensíveis.
-- Recomendado: VPS próprio do cliente (STACK B ou C) — dados nunca saem do servidor.
-- ═══════════════════════════════════════════════════════════════════

-- ── Dentistas / Profissionais ───────────────────────────────────────────────
CREATE TABLE dentistas (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nome            VARCHAR(200) NOT NULL,
    cro             VARCHAR(20)  NOT NULL,                 -- Conselho Regional de Odontologia
    especialidades  SET(
                     'clinica_geral','ortodontia','implantodontia','endodontia',
                     'periodontia','odontopediatria','protese','cirurgia',
                     'estetica','dtm','radiologia','patologia','saude_coletiva'
                    ),
    cor_agenda      VARCHAR(7)   DEFAULT '#4CAF50',       -- Cor para exibir na agenda
    ativo           BOOLEAN      DEFAULT TRUE,
    duracao_consulta_padrao_min TINYINT DEFAULT 30,
    telefone        VARCHAR(20),
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_ativo   (tenant_id, ativo),                   -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Pacientes ───────────────────────────────────────────────────────────────
CREATE TABLE pacientes (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nome            VARCHAR(200) NOT NULL,
    cpf             VARCHAR(14)  UNIQUE,
    data_nascimento DATE,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(200),
    genero          ENUM('M','F','N'),
    -- Endereço (opcional para lembretes):
    cep             VARCHAR(10),
    cidade          VARCHAR(100),
    -- Plano de saúde:
    convenio        VARCHAR(100),
    numero_convenio VARCHAR(50),
    -- Dados clínicos relevantes para triagem:
    alergias        TEXT,                                 -- Alergias a medicamentos/materiais
    medicamentos    TEXT,                                 -- Medicamentos em uso
    historico_medico TEXT,                                -- Condições relevantes
    pressao_arterial ENUM('normal','alta','baixa'),
    diabetico       BOOLEAN      DEFAULT FALSE,
    fumante         BOOLEAN      DEFAULT FALSE,
    gestante        BOOLEAN      DEFAULT FALSE,
    -- Comunicação:
    preferencia_contato ENUM('whatsapp','telefone','email') DEFAULT 'whatsapp',
    aceita_lembretes BOOLEAN     DEFAULT TRUE,
    -- Estado:
    ativo           BOOLEAN      DEFAULT TRUE,
    primeira_consulta DATE,
    ultima_consulta DATE,
    total_consultas SMALLINT     DEFAULT 0,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_cpf     (tenant_id, cpf),                     -- C4
    INDEX idx_tenant_tel     (tenant_id, telefone),
    INDEX idx_tenant_ativo   (tenant_id, ativo),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Consultas / Citas ────────────────────────────────────────────────────────
CREATE TABLE consultas (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    paciente_id     VARCHAR(36)  NOT NULL,
    dentista_id     VARCHAR(36)  NOT NULL,
    -- Agendamento:
    data_consulta   DATE         NOT NULL,
    hora_inicio     TIME         NOT NULL,
    hora_fim        TIME         NOT NULL,
    duracao_min     TINYINT      NOT NULL DEFAULT 30,
    sala            VARCHAR(20),                          -- "Sala 1", "Sala Cirurgia"
    -- Tipo:
    tipo            ENUM(
                     'avaliacao','retorno','limpeza','extracao',
                     'restauracao','canal','clareamento','aparelho',
                     'implante','protese','cirurgia','radiografia',
                     'emergencia','consulta_infantil','triagem','outro'
                    ) NOT NULL,
    especialidade   VARCHAR(50),
    -- Motivo:
    queixa_principal TEXT,
    -- Estado:
    status          ENUM('agendada','confirmada','cancelada',
                          'no_show','realizada','em_atendimento')
                                 DEFAULT 'agendada',
    cancelamento_motivo TEXT,
    -- Notificações:
    lembrete_24h_enviado BOOLEAN DEFAULT FALSE,
    lembrete_2h_enviado  BOOLEAN DEFAULT FALSE,
    canal_agendamento ENUM('whatsapp','telefone','presencial','app','site')
                                 DEFAULT 'whatsapp',
    -- Financeiro:
    convenio_utilizado VARCHAR(100),
    valor_cobrado   DECIMAL(10,2),
    pago            BOOLEAN      DEFAULT FALSE,
    -- Notas clínicas (acesso restrito):
    obs_pre_consulta TEXT,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_data    (tenant_id, data_consulta),           -- C4
    INDEX idx_tenant_pac     (tenant_id, paciente_id),
    INDEX idx_tenant_dent    (tenant_id, dentista_id),
    INDEX idx_tenant_status  (tenant_id, status),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
    FOREIGN KEY (dentista_id) REFERENCES dentistas(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Prontuário Clínico ──────────────────────────────────────────────────────
-- Dados sensíveis LGPD — acesso restrito ao dentista
CREATE TABLE prontuarios (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    paciente_id     VARCHAR(36)  NOT NULL,
    consulta_id     VARCHAR(36),
    dentista_id     VARCHAR(36)  NOT NULL,
    data_registro   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    -- Conteúdo clínico:
    anamnese        TEXT,
    exame_clinico   TEXT,
    diagnostico     TEXT,
    plano_tratamento TEXT,
    procedimento_realizado TEXT,
    evolucao        TEXT,
    prescricao      TEXT,
    observacoes     TEXT,
    -- Referências de imagens (Rx, fotos):
    imagens_urls    JSON,

    INDEX idx_tenant_pac     (tenant_id, paciente_id),             -- C4
    INDEX idx_tenant_data    (tenant_id, data_registro DESC),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
    FOREIGN KEY (dentista_id) REFERENCES dentistas(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Orçamentos / Planos de Tratamento ──────────────────────────────────────
CREATE TABLE orcamentos (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    paciente_id     VARCHAR(36)   NOT NULL,
    dentista_id     VARCHAR(36)   NOT NULL,
    data_orcamento  DATE          NOT NULL,
    validade_dias   TINYINT       DEFAULT 30,
    total           DECIMAL(12,2) NOT NULL DEFAULT 0,
    desconto_pct    DECIMAL(5,2)  DEFAULT 0,
    total_com_desconto DECIMAL(12,2),
    forma_pagamento VARCHAR(200),                          -- Pode ser parcelado
    status          ENUM('pendente','aprovado','recusado','em_tratamento','concluido')
                                  DEFAULT 'pendente',
    observacoes     TEXT,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_pac     (tenant_id, paciente_id),             -- C4
    INDEX idx_tenant_status  (tenant_id, status),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Itens do Orçamento ──────────────────────────────────────────────────────
CREATE TABLE orcamento_items (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    orcamento_id    VARCHAR(36)   NOT NULL,
    procedimento    VARCHAR(300)  NOT NULL,
    dente           VARCHAR(20),                          -- "18", "34-44", "superior"
    face            VARCHAR(50),                          -- "M", "D", "V", "L", "O"
    quantidade      TINYINT       DEFAULT 1,
    valor_unitario  DECIMAL(10,2) NOT NULL,
    subtotal        DECIMAL(10,2) NOT NULL,
    realizado       BOOLEAN       DEFAULT FALSE,

    INDEX idx_tenant_orc     (tenant_id, orcamento_id),            -- C4
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (orcamento_id) REFERENCES orcamentos(id) ON DELETE CASCADE
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Estoque de Materiais ─────────────────────────────────────────────────────
CREATE TABLE materiais_estoque (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    nome            VARCHAR(200)  NOT NULL,
    categoria       ENUM('anestesico','resina','cimento','fio_dental',
                         'luva','mascara','agulha','rx','implante',
                         'braquete','fio_ortodontico','outro'),
    unidade         VARCHAR(20)   DEFAULT 'un',
    quantidade      INT           DEFAULT 0,
    quantidade_minima INT         DEFAULT 5,
    fornecedor      VARCHAR(200),
    updated_at      DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_cat     (tenant_id, categoria),               -- C4
    INDEX idx_tenant_estoque (tenant_id, quantidade),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
```

### 10 Queries para Odontologia

```sql
-- ODONT-Q1: Agenda do dentista hoje (C4)
SELECT c.hora_inicio, c.hora_fim, c.tipo, c.status,
       p.nome AS paciente, p.telefone,
       c.queixa_principal, c.convenio_utilizado
FROM consultas c
JOIN pacientes p ON c.paciente_id = p.id AND p.tenant_id = ?           -- C4
WHERE c.tenant_id  = ?                                                  -- C4
  AND c.dentista_id = ?
  AND c.data_consulta = CURDATE()
ORDER BY c.hora_inicio;

-- ODONT-Q2: Pacientes com consulta em 24h para lembrete WA (C4)
SELECT c.id, p.nome, p.telefone, p.preferencia_contato,
       c.hora_inicio, c.tipo, d.nome AS dentista,
       c.lembrete_24h_enviado
FROM consultas c
JOIN pacientes p ON c.paciente_id = p.id
JOIN dentistas d ON c.dentista_id = d.id
WHERE c.tenant_id   = ?                                                 -- C4
  AND c.data_consulta = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
  AND c.status        = 'agendada'
  AND c.lembrete_24h_enviado = FALSE
  AND p.aceita_lembretes = TRUE;

-- ODONT-Q3: Histórico do paciente para contexto RAG (C4)
SELECT c.data_consulta, c.tipo, c.status,
       d.nome AS dentista,
       pr.diagnostico, pr.procedimento_realizado,
       pr.plano_tratamento
FROM consultas c
LEFT JOIN prontuarios pr ON c.id = pr.consulta_id AND pr.tenant_id = ? -- C4
JOIN dentistas d ON c.dentista_id = d.id
WHERE c.tenant_id  = ?                                                  -- C4
  AND c.paciente_id = ?
ORDER BY c.data_consulta DESC
LIMIT 10;

-- ODONT-Q4: Orçamentos pendentes de aprovação (C4)
SELECT o.id, p.nome AS paciente, p.telefone,
       o.data_orcamento, o.total_com_desconto,
       DATEDIFF(DATE_ADD(o.data_orcamento, INTERVAL o.validade_dias DAY), CURDATE())
         AS dias_para_vencer,
       d.nome AS dentista
FROM orcamentos o
JOIN pacientes p  ON o.paciente_id = p.id
JOIN dentistas d  ON o.dentista_id = d.id
WHERE o.tenant_id = ?                                                   -- C4
  AND o.status    = 'pendente'
  AND DATE_ADD(o.data_orcamento, INTERVAL o.validade_dias DAY) >= CURDATE()
ORDER BY dias_para_vencer;

-- ODONT-Q5: No-shows do mês para análise (C4)
SELECT MONTH(data_consulta) AS mes,
       COUNT(*) AS total_no_show,
       COUNT(*) * 100.0 / (
         SELECT COUNT(*) FROM consultas
         WHERE tenant_id = ? AND MONTH(data_consulta) = MONTH(NOW())
       ) AS pct_no_show
FROM consultas
WHERE tenant_id = ?                                                     -- C4
  AND status    = 'no_show'
  AND MONTH(data_consulta) = MONTH(NOW())
GROUP BY mes;

-- ODONT-Q6: Verificar conflito de horário ao agendar (C4)
SELECT COUNT(*) AS conflitos
FROM consultas
WHERE tenant_id   = ?                                                   -- C4
  AND dentista_id = ?
  AND data_consulta = ?
  AND status NOT IN ('cancelada','no_show')
  AND (
    (hora_inicio < ? AND hora_fim > ?)    -- Nova consulta começa durante existente
    OR (hora_inicio < ? AND hora_fim > ?) -- Nova consulta termina durante existente
    OR (hora_inicio >= ? AND hora_fim <= ?) -- Nova consulta engloba existente
  );

-- ODONT-Q7: Receita por especialidade/dentista (C4)
SELECT d.nome AS dentista, c.tipo,
       COUNT(*) AS total_consultas,
       SUM(c.valor_cobrado) AS receita_total,
       AVG(c.valor_cobrado) AS valor_medio
FROM consultas c
JOIN dentistas d ON c.dentista_id = d.id
WHERE c.tenant_id = ?                                                   -- C4
  AND c.status    = 'realizada'
  AND c.pago      = TRUE
  AND c.data_consulta BETWEEN ? AND ?
GROUP BY d.id, c.tipo
ORDER BY receita_total DESC;

-- ODONT-Q8: Materiais abaixo do estoque mínimo (alerta) (C4)
SELECT nome, categoria, quantidade, quantidade_minima,
       (quantidade_minima - quantidade) AS quantidade_repor,
       fornecedor
FROM materiais_estoque
WHERE tenant_id   = ?                                                   -- C4
  AND quantidade  < quantidade_minima
ORDER BY (quantidade_minima - quantidade) DESC;

-- ODONT-Q9: Pacientes sem retorno há mais de 6 meses (reativação WA) (C4)
SELECT p.nome, p.telefone, p.ultima_consulta,
       DATEDIFF(CURDATE(), p.ultima_consulta) AS dias_sem_retorno
FROM pacientes p
WHERE p.tenant_id      = ?                                             -- C4
  AND p.ativo          = TRUE
  AND p.aceita_lembretes = TRUE
  AND p.ultima_consulta < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY p.ultima_consulta ASC
LIMIT 50;

-- ODONT-Q10: Ortodoncia — tempo médio de tratamento (C4)
SELECT p.nome, p.telefone,
       MIN(c.data_consulta) AS inicio_tratamento,
       MAX(c.data_consulta) AS ultima_sessao,
       DATEDIFF(MAX(c.data_consulta), MIN(c.data_consulta)) AS dias_tratamento,
       COUNT(*) AS total_sessoes
FROM consultas c
JOIN pacientes p ON c.paciente_id = p.id
WHERE c.tenant_id = ?                                                  -- C4
  AND c.tipo      IN ('aparelho')
  AND c.status    = 'realizada'
GROUP BY c.paciente_id, p.nome, p.telefone
HAVING total_sessoes > 3
ORDER BY dias_tratamento DESC;
```

---

## 📱 VERTICAL 4: Marketing, Turismo e Agências

> Cobre: agência de marketing, promoção turística em redes sociais,
> empresa de turismo, agência geradora de agentes IA.

### Schema Principal

```sql
-- ═══════════════════════════════════════════════════════════════════
-- MARKETING & TURISMO — Schema para gestão de clientes, campanhas e leads
-- ═══════════════════════════════════════════════════════════════════

-- ── Clientes da Agência (cada cliente da agência é um sub-tenant) ───────────
CREATE TABLE clientes_agencia (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4: agência
    nome_empresa    VARCHAR(200) NOT NULL,
    segmento        VARCHAR(100),
    contato_nome    VARCHAR(200),
    contato_email   VARCHAR(200),
    contato_telefone VARCHAR(20),
    contato_whatsapp VARCHAR(20),
    plano_contratado ENUM('basico','intermediario','premium','enterprise'),
    valor_mensal    DECIMAL(10,2),
    redes_gerenciadas SET('instagram','facebook','tiktok','youtube',
                           'linkedin','twitter','pinterest','kwai'),
    ativo           BOOLEAN      DEFAULT TRUE,
    data_inicio     DATE,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_ativo    (tenant_id, ativo),                  -- C4
    INDEX idx_tenant_segmento (tenant_id, segmento),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Leads / Prospectos ──────────────────────────────────────────────────────
CREATE TABLE leads (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nome_empresa    VARCHAR(200),
    contato_nome    VARCHAR(200),
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(200),
    cidade          VARCHAR(100),
    segmento        VARCHAR(100),
    rede_social     VARCHAR(200),                         -- perfil da empresa
    -- Pipeline:
    status          ENUM('novo','contato_feito','interessado','proposta_enviada',
                          'negociacao','fechado_ganho','fechado_perdido','descartado')
                                 DEFAULT 'novo',
    origem          ENUM('google_maps','instagram','indicacao','apify',
                          'whatsapp_inbound','site','linkedin','evento','outro')
                                 DEFAULT 'whatsapp_inbound',
    -- Qualificação:
    tem_whatsapp    BOOLEAN      DEFAULT TRUE,
    rating_google   DECIMAL(3,1),
    num_avaliacoes  INT,
    seguidores_ig   INT,
    -- Acompanhamento:
    proxima_acao    TEXT,
    data_proxima_acao DATE,
    responsavel     VARCHAR(100),
    observacoes     TEXT,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_status   (tenant_id, status),                 -- C4
    INDEX idx_tenant_origem   (tenant_id, origem),
    INDEX idx_tenant_created  (tenant_id, created_at DESC),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Campanhas ────────────────────────────────────────────────────────────────
CREATE TABLE campanhas (
    id                  VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id           VARCHAR(50)   NOT NULL,           -- C4
    cliente_agencia_id  VARCHAR(36),
    titulo              VARCHAR(300)  NOT NULL,
    tipo                ENUM('feed','stories','reels','tiktok','anuncio_pago',
                             'email_mkt','whatsapp_broadcast','influencer',
                             'google_ads','seo','video_youtube'),
    objetivo            ENUM('awareness','leads','vendas','engajamento',
                              'trafego','retencao'),
    plataforma          SET('instagram','facebook','tiktok','youtube',
                            'google','whatsapp','email','linkedin'),
    data_inicio         DATE,
    data_fim            DATE,
    orcamento           DECIMAL(12,2) DEFAULT 0,
    gasto_real          DECIMAL(12,2) DEFAULT 0,
    -- Métricas (atualizar periodicamente):
    impressoes          BIGINT        DEFAULT 0,
    alcance             BIGINT        DEFAULT 0,
    cliques             INT           DEFAULT 0,
    engajamentos        INT           DEFAULT 0,
    leads_gerados       INT           DEFAULT 0,
    conversoes          INT           DEFAULT 0,
    cpc                 DECIMAL(8,4),                     -- Custo por clique
    cpl                 DECIMAL(8,4),                     -- Custo por lead
    status              ENUM('planejada','ativa','pausada','concluida','cancelada')
                                      DEFAULT 'planejada',
    created_at          DATETIME      DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_status   (tenant_id, status),                 -- C4
    INDEX idx_tenant_cliente  (tenant_id, cliente_agencia_id),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Conteúdo / Posts Agendados ───────────────────────────────────────────────
CREATE TABLE conteudo_social (
    id                  VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id           VARCHAR(50)  NOT NULL,            -- C4
    cliente_agencia_id  VARCHAR(36),
    campanha_id         VARCHAR(36),
    plataforma          ENUM('instagram','facebook','tiktok','youtube',
                              'linkedin','twitter','pinterest','kwai'),
    tipo_conteudo       ENUM('foto','video','reels','stories','carrossel',
                              'texto','link','ao_vivo'),
    titulo              VARCHAR(300),
    legenda             TEXT,
    hashtags            TEXT,
    -- IA generated:
    gerado_por_ia       BOOLEAN      DEFAULT FALSE,
    prompt_usado        TEXT,
    modelo_ia           VARCHAR(100),                     -- C6: modelo cloud usado
    -- Assets:
    midia_urls          JSON,                             -- Array de URLs
    -- Agendamento:
    data_publicacao     DATETIME,
    publicado           BOOLEAN      DEFAULT FALSE,
    publicado_at        DATETIME,
    -- Performance pós-publicação:
    curtidas            INT          DEFAULT 0,
    comentarios         INT          DEFAULT 0,
    compartilhamentos   INT          DEFAULT 0,
    alcance             INT          DEFAULT 0,
    visualizacoes       INT          DEFAULT 0,
    status              ENUM('rascunho','revisao','aprovado',
                              'agendado','publicado','rejeitado')
                                     DEFAULT 'rascunho',
    created_at          DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_status   (tenant_id, status),                 -- C4
    INDEX idx_tenant_data     (tenant_id, data_publicacao),
    INDEX idx_tenant_cliente  (tenant_id, cliente_agencia_id),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Pacotes Turísticos ──────────────────────────────────────────────────────
-- Para agências de turismo e promoção turística
CREATE TABLE pacotes_turisticos (
    id              VARCHAR(36)   NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)   NOT NULL,               -- C4
    nome            VARCHAR(300)  NOT NULL,
    destino         VARCHAR(200)  NOT NULL,
    descricao       TEXT,
    duracao_dias    TINYINT       NOT NULL,
    -- Preços:
    preco_por_pessoa DECIMAL(12,2) NOT NULL,
    preco_duplo     DECIMAL(12,2),
    preco_grupo     DECIMAL(12,2),
    num_min_pessoas TINYINT       DEFAULT 1,
    num_max_pessoas TINYINT,
    -- Inclui / Não inclui (para RAG):
    inclui          TEXT,
    nao_inclui      TEXT,
    roteiro         TEXT,                                 -- Texto do roteiro completo → RAG
    -- Disponibilidade:
    datas_disponiveis JSON,                               -- Array de datas
    disponivel      BOOLEAN       DEFAULT TRUE,
    imagens_urls    JSON,
    content_hash    VARCHAR(64),                          -- Para RAG sync
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_destino  (tenant_id, destino),                -- C4
    INDEX idx_tenant_disp     (tenant_id, disponivel),
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
```

### 10 Queries para Marketing e Turismo

```sql
-- MKT-Q1: Pipeline de leads por etapa (funil de vendas) (C4)
SELECT status,
       COUNT(*) AS total_leads,
       COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS percentual
FROM leads
WHERE tenant_id = ?                                                    -- C4
  AND created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY status
ORDER BY FIELD(status,'novo','contato_feito','interessado',
               'proposta_enviada','negociacao','fechado_ganho','fechado_perdido');

-- MKT-Q2: Leads para follow-up de hoje (C4)
SELECT l.id, l.contato_nome, l.nome_empresa, l.telefone,
       l.status, l.proxima_acao, l.responsavel, l.origem
FROM leads
WHERE tenant_id        = ?                                             -- C4
  AND status           NOT IN ('fechado_ganho','fechado_perdido','descartado')
  AND data_proxima_acao <= CURDATE()
ORDER BY data_proxima_acao, status;

-- MKT-Q3: Performance de campanhas ativas (C4)
SELECT c.titulo, c.tipo, c.plataforma,
       c.orcamento, c.gasto_real,
       ROUND(c.gasto_real / NULLIF(c.orcamento,0) * 100, 1) AS pct_gasto,
       c.impressoes, c.alcance, c.leads_gerados, c.conversoes,
       c.cpl, c.cpc
FROM campanhas c
WHERE c.tenant_id = ?                                                  -- C4
  AND c.status    = 'ativa'
ORDER BY c.leads_gerados DESC;

-- MKT-Q4: Conteúdo agendado para os próximos 7 dias (C4)
SELECT cs.data_publicacao, cs.plataforma, cs.tipo_conteudo,
       cs.titulo, cs.status,
       ca.nome_empresa AS cliente
FROM conteudo_social cs
LEFT JOIN clientes_agencia ca ON cs.cliente_agencia_id = ca.id
WHERE cs.tenant_id     = ?                                             -- C4
  AND cs.data_publicacao BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 7 DAY)
  AND cs.status        IN ('aprovado','agendado')
ORDER BY cs.data_publicacao;

-- MKT-Q5: Clientes por segmento (para proposta de novos serviços) (C4)
SELECT segmento, COUNT(*) AS total_clientes,
       SUM(valor_mensal) AS mrr_segmento,
       GROUP_CONCAT(redes_gerenciadas SEPARATOR '; ') AS redes
FROM clientes_agencia
WHERE tenant_id = ?                                                    -- C4
  AND ativo = TRUE
GROUP BY segmento
ORDER BY mrr_segmento DESC;

-- MKT-Q6: Pacotes turísticos para resposta do bot (C4)
SELECT nome, destino, duracao_dias,
       preco_por_pessoa, preco_duplo,
       inclui, roteiro
FROM pacotes_turisticos
WHERE tenant_id  = ?                                                   -- C4
  AND disponivel = TRUE
ORDER BY preco_por_pessoa;

-- MKT-Q7: ROI por campanha (C4)
SELECT c.titulo, c.tipo,
       c.orcamento AS investimento,
       c.conversoes * (SELECT AVG(valor_mensal) FROM clientes_agencia
                       WHERE tenant_id = ?) AS receita_estimada,      -- C4
       ROUND(
         (c.conversoes * (SELECT AVG(valor_mensal) FROM clientes_agencia
                          WHERE tenant_id = ?) - c.gasto_real)        -- C4
         / NULLIF(c.gasto_real, 0) * 100, 1
       ) AS roi_pct
FROM campanhas c
WHERE c.tenant_id = ?                                                  -- C4
  AND c.status    = 'concluida'
ORDER BY roi_pct DESC NULLS LAST;

-- MKT-Q8: Conteúdo gerado por IA (rastrear uso - C6 billing) (C4)
SELECT DATE(created_at) AS data, modelo_ia,
       COUNT(*) AS posts_gerados,
       plataforma, tipo_conteudo
FROM conteudo_social
WHERE tenant_id      = ?                                               -- C4
  AND gerado_por_ia  = TRUE
  AND created_at     > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at), modelo_ia, plataforma, tipo_conteudo
ORDER BY data DESC;

-- MKT-Q9: Leads de Google Maps para abordagem WhatsApp (C4)
SELECT l.nome_empresa, l.contato_nome, l.telefone,
       l.cidade, l.segmento, l.rating_google,
       l.num_avaliacoes, l.seguidores_ig, l.tem_whatsapp
FROM leads
WHERE tenant_id = ?                                                    -- C4
  AND origem    = 'google_maps'
  AND status    = 'novo'
  AND tem_whatsapp = TRUE
ORDER BY l.rating_google DESC, l.num_avaliacoes DESC
LIMIT 50;

-- MKT-Q10: Engajamento médio por plataforma (para recomendação ao cliente) (C4)
SELECT plataforma,
       COUNT(*) AS posts,
       ROUND(AVG(curtidas), 0) AS media_curtidas,
       ROUND(AVG(comentarios), 0) AS media_comentarios,
       ROUND(AVG(visualizacoes), 0) AS media_views,
       ROUND(AVG(alcance), 0) AS media_alcance
FROM conteudo_social
WHERE tenant_id    = ?                                                 -- C4
  AND publicado    = TRUE
  AND publicado_at > DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY plataforma
ORDER BY media_curtidas DESC;
```

---

## 📚 VERTICAL 5: Base de Conhecimento Corporativa (Corp-KB)

> Cobre: abogados, empresas de IA, turismo, gastronomia, hotéis, odontologia —
> qualquer empresa que queira que seus funcionários encontrem respostas
> por WhatsApp/Telegram sem precisar perguntar ao chefe.

### Schema Principal

```sql
-- ═══════════════════════════════════════════════════════════════════
-- CORP-KB — Base de Conhecimento Corporativa Multi-Tenant
-- Caso de uso: Novo funcionário pergunta pelo WhatsApp:
-- "Qual é a política de reembolso?" → RAG responde com base nos documentos.
-- ═══════════════════════════════════════════════════════════════════

-- ── Bases de Conhecimento (uma por tenant ou por departamento) ──────────────
CREATE TABLE knowledge_bases (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nome            VARCHAR(200) NOT NULL,                 -- "KB Jurídico", "KB Atendimento"
    descricao       TEXT,
    setor           ENUM('juridico','rh','financeiro','operacional','comercial',
                          'tecnico','atendimento','marketing','clinico',
                          'gastronomico','hoteleiro','geral'),
    idioma          VARCHAR(5)   DEFAULT 'pt-BR',
    ativo           BOOLEAN      DEFAULT TRUE,
    total_documentos SMALLINT    DEFAULT 0,
    total_chunks    INT          DEFAULT 0,
    embedding_model VARCHAR(100) DEFAULT 'text-embedding-3-small', -- C6
    qdrant_collection VARCHAR(100),                       -- Nome da coleção no Qdrant
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_setor   (tenant_id, setor),                   -- C4
    INDEX idx_tenant_ativo   (tenant_id, ativo),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Documentos da Base ──────────────────────────────────────────────────────
CREATE TABLE kb_documentos (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    kb_id           VARCHAR(36)  NOT NULL,
    titulo          VARCHAR(300) NOT NULL,
    tipo            ENUM('pdf','word','texto','url','planilha','apresentacao',
                          'imagem','video_transcricao'),
    origem          ENUM('upload_manual','google_drive','url','notion',
                          'confluence','sharepoint','api'),
    source_id       VARCHAR(500),                         -- ID no Drive, URL, etc.
    source_url      VARCHAR(1000),
    -- Classificação:
    categoria       VARCHAR(100),                         -- "Políticas RH", "Contratos"
    subcategoria    VARCHAR(100),
    tags            JSON,                                 -- Array de tags
    -- Controle de versão:
    versao          VARCHAR(20)  DEFAULT '1.0',
    content_hash    VARCHAR(64)  NOT NULL,                -- SHA256 conteúdo
    -- Status de processamento:
    status          ENUM('pendente','processando','indexado','erro','arquivado')
                                 DEFAULT 'pendente',
    erro_msg        TEXT,
    total_chunks    SMALLINT     DEFAULT 0,
    -- Metadados:
    autor           VARCHAR(200),
    data_documento  DATE,
    validade        DATE,                                 -- Política pode expirar
    publico         BOOLEAN      DEFAULT TRUE,            -- Visível para todos os users do tenant?
    confidencial    BOOLEAN      DEFAULT FALSE,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_kb      (tenant_id, kb_id),                   -- C4
    INDEX idx_tenant_status  (tenant_id, status),
    INDEX idx_tenant_hash    (tenant_id, content_hash),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (kb_id)      REFERENCES knowledge_bases(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Usuários da Base de Conhecimento ────────────────────────────────────────
CREATE TABLE kb_usuarios (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    nome            VARCHAR(200) NOT NULL,
    telefone        VARCHAR(20)  NOT NULL,
    email           VARCHAR(200),
    cargo           VARCHAR(100),
    setor           VARCHAR(100),
    nivel_acesso    ENUM('funcionario','supervisor','admin') DEFAULT 'funcionario',
    kbs_permitidas  JSON,                                 -- Array de kb_id que pode consultar
    ativo           BOOLEAN      DEFAULT TRUE,
    data_admissao   DATE,
    total_consultas INT          DEFAULT 0,
    ultima_consulta DATETIME,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_tenant_tel (tenant_id, telefone),                  -- C4
    INDEX idx_tenant_cargo   (tenant_id, cargo),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Consultas à Base de Conhecimento ────────────────────────────────────────
CREATE TABLE kb_consultas (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    kb_id           VARCHAR(36)  NOT NULL,
    usuario_id      VARCHAR(36),
    telefone        VARCHAR(20),                          -- Para consultas sem cadastro
    -- Pergunta e resposta:
    pergunta        TEXT         NOT NULL,
    resposta_ia     TEXT,
    -- RAG metadata:
    qdrant_score_max DECIMAL(5,4),                        -- Relevância do melhor chunk
    chunks_utilizados JSON,                               -- Array de {chunk_id, doc_titulo, score}
    respondido_com_kb BOOLEAN    DEFAULT TRUE,            -- FALSE = resposta sem base documental
    -- Modelo:
    modelo_ia       VARCHAR(100),                         -- C6: modelo OpenRouter usado
    tokens_input    SMALLINT     DEFAULT 0,
    tokens_output   SMALLINT     DEFAULT 0,
    latency_ms      SMALLINT,
    -- Feedback:
    util            BOOLEAN,                              -- O usuário achou útil?
    feedback_texto  TEXT,
    canal           ENUM('whatsapp','telegram','web','api') DEFAULT 'whatsapp',
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_kb      (tenant_id, kb_id),                   -- C4
    INDEX idx_tenant_user    (tenant_id, usuario_id),
    INDEX idx_tenant_util    (tenant_id, util),
    INDEX idx_tenant_created (tenant_id, created_at DESC),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (kb_id)      REFERENCES knowledge_bases(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;

-- ── Gaps de Conhecimento (perguntas sem resposta boa) ────────────────────────
CREATE TABLE kb_gaps (
    id              VARCHAR(36)  NOT NULL PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                -- C4
    kb_id           VARCHAR(36)  NOT NULL,
    pergunta        TEXT         NOT NULL,
    vezes_perguntada SMALLINT    DEFAULT 1,
    qdrant_score_max DECIMAL(5,4),                        -- Score baixo = gap identificado
    status          ENUM('identificado','em_revisao','documentado','ignorado')
                                 DEFAULT 'identificado',
    doc_criado_id   VARCHAR(36),                          -- Se foi documentado depois
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_kb      (tenant_id, kb_id),                   -- C4
    INDEX idx_tenant_status  (tenant_id, status),
    FOREIGN KEY (tenant_id)  REFERENCES tenants(tenant_id),
    FOREIGN KEY (kb_id)      REFERENCES knowledge_bases(id)
) ENGINE=InnoDB CHARACTER SET utf8mb4;
```

### 10 Queries para Corp-KB

```sql
-- KB-Q1: Documentos por indexar (fila para o worker RAG) (C4)
SELECT d.id, d.titulo, d.tipo, d.origem, d.source_id,
       kb.nome AS base, kb.qdrant_collection,
       kb.embedding_model
FROM kb_documentos d
JOIN knowledge_bases kb ON d.kb_id = kb.id AND kb.tenant_id = ?      -- C4
WHERE d.tenant_id = ?                                                  -- C4
  AND d.status    = 'pendente'
ORDER BY d.created_at ASC
LIMIT 10
FOR UPDATE SKIP LOCKED;

-- KB-Q2: Perguntas mais frequentes por base (para criar FAQ) (C4)
SELECT kc.pergunta,
       COUNT(*) AS vezes_perguntada,
       ROUND(AVG(kc.qdrant_score_max), 3) AS score_medio,
       SUM(CASE WHEN kc.util = TRUE  THEN 1 ELSE 0 END) AS respostas_uteis,
       SUM(CASE WHEN kc.util = FALSE THEN 1 ELSE 0 END) AS respostas_ruins
FROM kb_consultas kc
WHERE kc.tenant_id = ?                                                 -- C4
  AND kc.kb_id     = ?
  AND kc.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY kc.pergunta
ORDER BY vezes_perguntada DESC
LIMIT 20;

-- KB-Q3: Gaps críticos de conhecimento (score baixo = doc não existe) (C4)
SELECT kg.pergunta, kg.vezes_perguntada, kg.qdrant_score_max,
       kb.nome AS base, kg.status
FROM kb_gaps kg
JOIN knowledge_bases kb ON kg.kb_id = kb.id
WHERE kg.tenant_id     = ?                                             -- C4
  AND kg.status        = 'identificado'
  AND kg.qdrant_score_max < 0.7
ORDER BY kg.vezes_perguntada DESC, kg.qdrant_score_max ASC
LIMIT 20;

-- KB-Q4: Usuários mais ativos (engajamento com a KB) (C4)
SELECT u.nome, u.cargo, u.setor,
       u.total_consultas,
       u.ultima_consulta,
       COUNT(kc.id) AS consultas_30dias
FROM kb_usuarios u
LEFT JOIN kb_consultas kc ON kc.usuario_id = u.id
    AND kc.tenant_id = ?                                               -- C4
    AND kc.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
WHERE u.tenant_id = ?                                                  -- C4
  AND u.ativo     = TRUE
GROUP BY u.id, u.nome, u.cargo, u.setor
ORDER BY consultas_30dias DESC
LIMIT 20;

-- KB-Q5: Taxa de satisfação por base (C4)
SELECT kb.nome,
       COUNT(kc.id) AS total_consultas,
       SUM(CASE WHEN kc.util = TRUE  THEN 1 ELSE 0 END) AS uteis,
       SUM(CASE WHEN kc.util = FALSE THEN 1 ELSE 0 END) AS nao_uteis,
       ROUND(SUM(CASE WHEN kc.util = TRUE THEN 1 ELSE 0 END)
             * 100.0 / NULLIF(COUNT(CASE WHEN kc.util IS NOT NULL THEN 1 END), 0)
             , 1) AS satisfacao_pct
FROM kb_consultas kc
JOIN knowledge_bases kb ON kc.kb_id = kb.id
WHERE kc.tenant_id = ?                                                 -- C4
  AND kc.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY kb.id, kb.nome
ORDER BY satisfacao_pct DESC;

-- KB-Q6: Documentos com validade próxima (atualização necessária) (C4)
SELECT d.titulo, d.categoria, d.versao,
       d.data_documento, d.validade,
       DATEDIFF(d.validade, CURDATE()) AS dias_restantes,
       kb.nome AS base
FROM kb_documentos d
JOIN knowledge_bases kb ON d.kb_id = kb.id
WHERE d.tenant_id  = ?                                                 -- C4
  AND d.status     = 'indexado'
  AND d.validade   IS NOT NULL
  AND d.validade   <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY d.validade;

-- KB-Q7: Consumo de tokens por modelo (billing C6) (C4)
SELECT modelo_ia,
       COUNT(*) AS consultas,
       SUM(tokens_input) AS tokens_entrada,
       SUM(tokens_output) AS tokens_saida,
       SUM(tokens_input + tokens_output) AS tokens_total,
       ROUND(AVG(latency_ms), 0) AS latencia_media_ms
FROM kb_consultas
WHERE tenant_id = ?                                                    -- C4
  AND created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY modelo_ia
ORDER BY tokens_total DESC;

-- KB-Q8: Funcionários sem acesso à KB (para convite de onboarding) (C4)
SELECT u.nome, u.cargo, u.setor, u.telefone, u.data_admissao,
       DATEDIFF(CURDATE(), u.data_admissao) AS dias_empresa
FROM kb_usuarios u
WHERE u.tenant_id    = ?                                               -- C4
  AND u.ativo        = TRUE
  AND u.total_consultas = 0
  AND u.data_admissao < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY u.data_admissao DESC;

-- KB-Q9: Documentos mais consultados via RAG (C4)
SELECT kd.titulo, kd.categoria, kd.tipo,
       COUNT(*) AS vezes_referenciada
FROM kb_consultas kc
JOIN JSON_TABLE(
    kc.chunks_utilizados,
    '$[*]' COLUMNS (doc_titulo VARCHAR(300) PATH '$.doc_titulo')
) jt ON TRUE
JOIN kb_documentos kd ON kd.titulo = jt.doc_titulo
    AND kd.tenant_id = ?                                               -- C4
WHERE kc.tenant_id = ?                                                 -- C4
  AND kc.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY kd.id, kd.titulo, kd.categoria, kd.tipo
ORDER BY vezes_referenciada DESC
LIMIT 15;

-- KB-Q10: Relatório de onboarding - novos funcionários ativos na KB (C4)
SELECT u.nome, u.cargo, u.setor,
       u.data_admissao,
       u.total_consultas,
       u.ultima_consulta,
       COUNT(DISTINCT kc.kb_id) AS bases_consultadas
FROM kb_usuarios u
LEFT JOIN kb_consultas kc ON kc.usuario_id = u.id AND kc.tenant_id = ?  -- C4
WHERE u.tenant_id   = ?                                                -- C4
  AND u.data_admissao >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY u.id, u.nome, u.cargo, u.setor, u.data_admissao
ORDER BY u.data_admissao DESC;
```

---

## 🔧 Utilitários — Scripts de Setup por Vertical

### Script de Criação de Schema (Bootstrap)

```bash
#!/bin/bash
# scripts/create-vertical-schema.sh
# C4: tenant_id obrigatório
# Uso: ./create-vertical-schema.sh <tenant_id> <vertical>

set -euo pipefail

TENANT_ID="${1:?C4: tenant_id required}"
VERTICAL="${2:?Vertical required (gastro|hospedagem|dental|marketing|corp-kb)}"

MYSQL="mysql -h ${MYSQL_HOST:-127.0.0.1} -u root -p${MYSQL_ROOT_PASSWORD}"

echo "🏗️ Criando schema para: $TENANT_ID | vertical: $VERTICAL"

# 1. Criar tenant na tabela mestra
$MYSQL mantis_rag_meta << EOF
INSERT IGNORE INTO tenants (id, tenant_id, nome_negocio, vertical, db_stack)
VALUES (UUID(), '$TENANT_ID', '${NOME_NEGOCIO:-Negócio}', '$VERTICAL', '${DB_STACK:-B}');
EOF

# 2. Criar BD específica do tenant (isolamento C4)
$MYSQL -e "CREATE DATABASE IF NOT EXISTS tenant_${TENANT_ID} CHARACTER SET utf8mb4;"

# 3. Aplicar schema do vertical
case "$VERTICAL" in
  gastro)      SCHEMA_FILE="gastro-schema.sql" ;;
  hospedagem)  SCHEMA_FILE="hospedagem-schema.sql" ;;
  dental)      SCHEMA_FILE="dental-schema.sql" ;;
  marketing)   SCHEMA_FILE="marketing-schema.sql" ;;
  corp-kb)     SCHEMA_FILE="corp-kb-schema.sql" ;;
  *)           echo "❌ Vertical desconhecido: $VERTICAL"; exit 1 ;;
esac

$MYSQL "tenant_${TENANT_ID}" < "05-CONFIGURATIONS/schemas/${SCHEMA_FILE}"

# 4. Seeds de configuração
$MYSQL "tenant_${TENANT_ID}" << EOF
-- Seeds básicos para config_negocio (se vertical for gastro)
INSERT INTO config_negocio (id, tenant_id, chave, valor) VALUES
(UUID(), '$TENANT_ID', 'setup_complete', 'false'),
(UUID(), '$TENANT_ID', 'vertical', '$VERTICAL');
EOF

echo "✅ Schema criado: tenant_${TENANT_ID} | vertical: $VERTICAL"
echo "   Próximo passo: configurar .env e iniciar agente WhatsApp"
```

---

## ✅ Tabela de Validação — Schemas por Vertical

| # | Check | Comando | ✅ Correcto | ❌ Incorrecto |
|---|---|---|---|---|
| 1 | tenant_id em todas as tabelas | `SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE COLUMN_NAME='tenant_id' AND TABLE_SCHEMA='tenant_X'` | Todas as tabelas listadas | Tabela faltando |
| 2 | Índice composto começa com tenant_id | `SHOW INDEX FROM reservas WHERE Key_name='idx_tenant_data'` | `Column_name: tenant_id, Seq_in_index: 1` | tenant_id não é o primeiro campo |
| 3 | FK referencia tabela tenants | `SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE TABLE_NAME='reservas'` | FK para `tenants.tenant_id` | FK ausente |
| 4 | content_hash em tabelas com RAG | `DESCRIBE menu_items` | Coluna `content_hash VARCHAR(64)` | Coluna ausente |
| 5 | Seeds de config_negocio inseridos | `SELECT COUNT(*) FROM config_negocio WHERE tenant_id='X'` | `>= 5` | `0` |

---

## 🔗 Referências Cruzadas

- [[02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md]] — Qual stack usar para cada cliente
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]] — Padrões de ingesta RAG em MySQL
- [[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]] — Atualização de chunks RAG
- [[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]] — Isolamento multi-tenant
- [[01-RULES/06-MULTITENANCY-RULES.md]] — Regras C4 obrigatórias
- [[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]] — MySQL em produção

---

# 🟢 VALIDATION: 
# 1. ./05-CONFIGURATIONS/validation/check-wikilinks.sh 02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md
# 2. ./05-CONFIGURATIONS/validation/validate-skill-integrity.sh --type md --strict 02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md
# 3. mysql -e "SOURCE 02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md" --dry-run  # validación sintáctica

<!-- ai:file-end marker — do not remove -->
Versão 1.0.0 — 2026-04-13 — Mantis-AgenticDev
Verticais: Gastronomia (12 sub-verticais) | Hospedagem (5 sub-verticais) | Odontologia (6 sub-verticais) | Marketing/Turismo (5 sub-verticais) | Corp-KB (6 sub-verticais)
