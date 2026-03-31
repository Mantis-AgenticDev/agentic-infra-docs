---
title: "PROJECT OVERVIEW - Agentic Infra Docs"
category: "Contexto"
priority: "Siempre"
version: "1.0.3"
last_updated: "2026-03-30"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "overview"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
total_sections: 11
estimated_tokens: 4500
tags:
  - overview
  - context
  - business-model
  - architecture
  - multi-tenant
  - scalability
related_files:
  - "00-CONTEXT/00-INDEX.md"
  - "00-CONTEXT/facundo-core-context.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "00-CONTEXT/facundo-business-model.md"
  - "01-RULES/00-INDEX.md"
---
<!-- IA-NAVIGATION
priority_files:
  - "00-CONTEXT/facundo-core-context.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
always_keep_in_context:
  - "PROJECT_OVERVIEW.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
load_strategy: "full"
max_tokens_per_session: 8000
critical_sections:
  - "business-model"
  - "infrastructure-architecture"
  - "multi-tenancy"
  - "scalability-plan"
-->
---

# Project Overview / Visão Geral do Projeto

**Repository / Repositório:** agentic-infra-docs  
**Owner / Proprietário:** Mantis-AgenticDev (Facundo)  
**Location / Localização:** Rio Grande do Sul, Brasil  
**Language / Idioma:** Español / Português BR  
**Version / Versão:** 1.0.0  
**Status / Status:** 🚧 Development / Em desenvolvimento  
**Last Updated / Última atualização:** March 2026 / Março 2026

---

## 📋 TABLE OF CONTENTS / ÍNDICE

1. [Project Purpose             / Propósito del Proyecto](#project-purpose--propósito-del-proyecto)
2. [Business Model              / Modelo de Negócio](#business-model--modelo-de-negócio)
3. [Infrastructure Architecture / Arquitetura de Infraestrutura](#infrastructure-architecture--arquitetura-de-infraestrutura)
4. [VPS Configuration           / Configuração dos VPS](#vps-configuration--configuração-dos-vps)
5. [Security Measures           / Medidas de Segurança](#security-measures--medidas-de-segurança)
6. [Monitoring & Alerts         / Monitoramento e Alertas](#monitoring--alerts--monitoramento-e-alertas)
7. [Backup Strategy             / Estratégia de Backup](#backup-strategy--estratégia-de-backup)
8. [Multi-Tenancy               / Multi-Tenência](#multi-tenancy--multi-tenência)
9. [Client Capacity             / Capacidade de Clientes](#client-capacity--capacidade-de-clientes)
10. [Scalability Plan           / Plano de Escalabilidade](#scalability-plan--plano-de-escalabilidade)

---

## PROJECT PURPOSE / PROPÓSITO DEL PROYECTO

### 🇪🇸 Español

Este proyecto tiene como objetivo construir una **infraestructura agéntica de automatización** basada en WhatsApp con IA + RAG + CRM, destinada a generar ingresos recurrentes que financien un **laboratorio de microbiología y agrobiología**.

**Objetivos principales:**
- Automatizar atención al cliente vía WhatsApp para 6-8 clientes iniciales
- Implementar sistema RAG (Retrieval-Augmented Generation) con datos específicos de cada cliente
- Centralizar datos en EspoCRM con arquitectura multi-tenant
- Generar ingreso neto mensual de R$ 2.500+ para financiar laboratorio
- Mantener costos de infraestructura por debajo de R$ 1.330/mes

**Áreas de aplicación del laboratorio:**
- Microbiología (hongos, bacterias)
- Control entomológico de depredadores para cultivos
- Polinización y biodiversidad
- Edafología y fauna del suelo
- Química agrícola y bioestimulación
- Ingeniería de bioprocesos
- Agroecología tritrófica
- Producción en biorreactores SSF UPPB

### 🇧🇷 Português

Este projeto tem como objetivo construir uma **infraestrutura agêntica de automação** baseada em WhatsApp com IA + RAG + CRM, destinada a gerar receita recorrente que financie um **laboratório de microbiologia e agrobiologia**.

**Objetivos principais:**
- Automatizar atendimento ao cliente via WhatsApp para 6-8 clientes iniciais
- Implementar sistema RAG (Retrieval-Augmented Generation) com dados específicos de cada cliente
- Centralizar dados em EspoCRM com arquitetura multi-tenant
- Gerar receita líquida mensal de R$ 2.500+ para financiar laboratório
- Manter custos de infraestrutura abaixo de R$ 1.330/mês

**Áreas de aplicação do laboratório:**
- Microbiologia (fungos, bactérias)
- Controle entomológico de predadores para cultivos
- Polinização e biodiversidade
- Edafologia e fauna do solo
- Química agrícola e bioestimulação
- Engenharia de bioprocessos
- Agroecologia tritrófica
- Produção em biorreatores SSF UPPB

---

## BUSINESS MODEL / MODELO DE NEGÓCIO

### 🇪🇸 Español

| Plan / Plano | Precio / Preço | Incluye / Inclui                                                                       |
|--------------|----------------|----------------------------------------------------------------------------------------|
| **Full**     | R$ 550/mes     | WhatsApp automation, RAG, Acceso a EspoCRM, Reportes y dashboards, Soporte prioritario |
| **Light**    | R$ 400/mes     | WhatsApp automation, RAG, Sin acceso a CRM, Solo almacenamiento de datos               |

**Términos del contrato:**
- Duración: 12 meses auto-renovable
- SLA: Backup diario 4 AM, restauración < 1 hora
- Respuesta a alertas: < 10 minutos

### 🇧🇷 Português

| Plan / Plano | Preço / Precio | Inclui / Incluye                                                                         |
|--------------|----------------|------------------------------------------------------------------------------------------|
| **Full**     | R$ 550/mês     | Automação WhatsApp, RAG, Acesso ao EspoCRM, Relatórios e dashboards, Suporte prioritário |
| **Light**    | R$ 400/mês     | Automação WhatsApp, RAG, Sem acesso ao CRM, Apenas armazenamento de dados                |

**Termos do contrato:**
- Duração: 12 meses auto-renovável
- SLA: Backup diário 2 AM, restauração < 1 hora
- Resposta a alertas: < 10 minutos

---

## INFRASTRUCTURE ARCHITECTURE / ARQUITETURA DE INFRAESTRUTURA

### 🇪🇸 Español

┌─────────────────────────────────────────────────────────────────────────┐
│                         ARQUITECTURA DE 3 VPS                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │   VPS 1         │     │   VPS 2         │     │   VPS 3         │    │
│  │   n8n + uazapi  │────▶│   CRM + DB      │◀────│   n8n + uazapi  │    │
│  │   (3 clientes)  │ SSH │   (6 clientes)  │ SSH │   (3 clientes)  │    │
│  │   São Paulo     │     │   São Paulo     │     │   São Paulo     │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│          │                       │                       │              │
│          └───────────────────────┼───────────────────────┘              │
│                                  │                                      │
│                          ┌───────────────┐                              │
│                          │   PC Local    │                              │
│                          │   Backups     │                              │
│                          │   (4:00 AM)   │                              │
│                          └───────────────┘                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘


**Flujo de datos:**
1. Mensaje WhatsApp entra → uazapi (VPS 1 o VPS 3)
2. uazapi notifica → n8n (VPS 1 o VPS 3)
3. n8n consulta → Qdrant + MySQL (VPS 2)
4. n8n genera respuesta → OpenRouter (IA)
5. n8n envía respuesta → uazapi → WhatsApp
6. n8n registra interacción → EspoCRM (VPS 2, solo clientes Full)

### 🇧🇷 Português

┌─────────────────────────────────────────────────────────────────────────┐
│                         ARQUITETURA DE 3 VPS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐    │
│  │   VPS 1         │     │   VPS 2         │     │   VPS 3         │    │
│  │   n8n + uazapi  │────▶│   CRM + DB      │◀────│   n8n + uazapi  │    │
│  │   (3 clientes)  │ SSH │   (6 clientes)  │ SSH │   (3 clientes)  │    │
│  │   São Paulo     │     │   São Paulo     │     │   São Paulo     │    │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘    │
│          │                       │                       │              │
│          └───────────────────────┼───────────────────────┘              │
│                                  │                                      │
│                          ┌───────────────┐                              │
│                          │   PC Local    │                              │
│                          │   Backups     │                              │
│                          │   (4:00 AM)   │                              │
│                          └───────────────┘                              │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘


**Fluxo de dados:**
1. Mensagem WhatsApp entra → uazapi (VPS 1 ou VPS 3)
2. uazapi notifica → n8n (VPS 1 ou VPS 3)
3. n8n consulta → Qdrant + MySQL (VPS 2)
4. n8n gera resposta → OpenRouter (IA)
5. n8n envia resposta → uazapi → WhatsApp
6. n8n registra interação → EspoCRM (VPS 2, apenas clientes Full)

---

## VPS CONFIGURATION / CONFIGURAÇÃO DOS VPS

### 🇪🇸 Español

| Especificación          | VPS 1              | VPS 2                  | VPS 3         |
|-------------------------|--------------------|------------------------|---------------|
| **Proveedor**           | Hostinger          | Hostinger              | Hostinger     |
| **Plan**                | KVM1               | KVM1                   | KVM1          |
| **vCPU**                | 1 núcleo           | 1 núcleo               | 1 núcleo      |
| **RAM**                 | 4 GB               | 4 GB                   | 4 GB          |
| **Disco**               | 50 GB NVMe         | 50 GB NVMe             | 50 GB NVMe    |
| **Ancho de banda**      | 4 TB               | 4 TB                   | 4 TB          |
| **Ubicación**           | São Paulo, BR      | São Paulo, BR          | São Paulo, BR |
| **Acceso**              | Root SSH           | Root SSH               | Root SSH      |
| **Servicios**           | n8n, uazapi, Redis | EspoCRM, MySQL, Qdrant | n8n, uazapi   |
| **Capacidad**           | 3 clientes         | 6 clientes (central)   | 3 clientes    |
| **Contenedores Docker** | 3                  | 3                      | 2             |

### 🇧🇷 Português

| Especificação           | VPS 1               | VPS 2                 | VPS 3         |
|-------------------------|---------------------|-----------------------|---------------|
| **Fornecedor**          | Hostinger           | Hostinger             | Hostinger     |
| **Plano**               | KVM1                | KVM1                  | KVM1          |
| **vCPU**                | 1 núcleo            | 1 núcleo              | 1 núcleo      |
| **RAM**                 | 4 GB                | 4 GB                  | 4 GB          |
| **Disco**               | 50 GB NVMe          | 50 GB NVMe            | 50 GB NVMe    |
| **Largura de banda**    | 4 TB                | 4 TB                  | 4 TB          |
| **Localização**         | São Paulo, BR       | São Paulo, BR         | São Paulo, BR |
| **Acesso**              | Root SSH            | Root SSH              | Root SSH      |
| **Serviços**            | n8n, uazapi, Redis  | EspoCRM, MySQL, Qdrant| n8n, uazapi   |
| **Capacidade**          | 3 clientes          | 6 clientes (central)  | 3 clientes    |
| **Contêineres Docker**  | 3                   | 3                     | 2             |

---

## SECURITY MEASURES / MEDIDAS DE SEGURANÇA

### 🇪🇸 Español

**Firewall (UFW):**
- SSH:                     Solo IPs conocidas
- MySQL (3306):            Solo desde IP VPS 1 y VPS 3
- Qdrant (6333):           Solo desde IP VPS 1 y VPS 3
- HTTP (80) / HTTPS (443): Público
- Default:                 Denegar todo lo demás

**SSH:**
- Autenticación: Solo claves SSH (no password)
- Root login:    Deshabilitado si es posible
- Keepalive:     ClientAliveInterval 60, ClientAliveCountMax 3

**Protección adicional:**
- fail2ban instalado en todos los VPS
- Variables de entorno en archivos .env (nunca en código)
- Backups encriptados con contraseña
- tenant_id validado en cada consulta

### 🇧🇷 Português

**Firewall (UFW):**
- SSH:                     Apenas IPs conhecidas
- MySQL (3306):            Apenas desde IP VPS 1 e VPS 3
- Qdrant (6333):           Apenas desde IP VPS 1 e VPS 3
- HTTP (80) / HTTPS (443): Público
- Default:                 Negar todo o demais

**SSH:**
- Autenticação: Apenas chaves SSH (sem senha)
- Root login:   Desabilitado se possível
- Keepalive:    ClientAliveInterval 60, ClientAliveCountMax 3

**Proteção adicional:**
- fail2ban instalado em todos os VPS
- Variáveis de ambiente em arquivos .env (nunca em código)
- Backups criptografados com senha
- tenant_id validado em cada consulta

---

## MONITORING & ALERTS / MONITORAMENTO E ALERTAS

### 🇪🇸 Español

**Agentes de monitoreo:**
- **health-monitor-agent:** Polling cada 5 minutos a todos los VPS
- **backup-manager-agent:** Ejecuta backup diario 4:00 AM
- **alert-dispatcher-agent:** Envía alertas a múltiples canales

**Canales de alerta:**
| Canal           | Propósito            | Tiempo de entrega |
|-----------------|----------------------|-------------------|
| Telegram Bot    | Alertas críticas     | < 10 segundos     |
| Gmail SMTP      | Registro formal      | < 1 minuto        |
| Google Calendar | Agenda de incidentes | < 1 minuto        |
| Log local       | Auditoría            | Inmediato         |

**Umbrales de alerta:**
| Recurso | Advertencia     | Crítico         |
|---------|-----------------|-----------------|
| RAM     | > 85% por 5 min | > 90% por 5 min |
| CPU     | > 80% sostenido | > 90% sostenido |
| Disco   | > 80%           | > 90%           |

### 🇧🇷 Português

**Agentes de monitoramento:**
- **health-monitor-agent:** Polling a cada 5 minutos em todos os VPS
- **backup-manager-agent:** Executa backup diário 4:00 AM
- **alert-dispatcher-agent:** Envia alertas para múltiplos canais

**Canais de alerta:**
| Canal           | Propósito            | Tempo de entrega |
|-----------------|----------------------|------------------|
| Telegram Bot    | Alertas críticas     | < 10 segundos    |
| Gmail SMTP      | Registro formal      | < 1 minuto       |
| Google Calendar | Agenda de incidentes | < 1 minuto       |
| Log local       | Auditoria            | Imediato         |

**Limiares de alerta:**
| Recurso | Advertência      | Crítico          |
|---------|------------------|------------------|
| RAM     | > 85% por 5 min  | > 90% por 5 min  |
| CPU     | > 80% sustentado | > 90% sustentado |
| Disco   | > 80%            | > 90%            |

---

## BACKUP STRATEGY / ESTRATÉGIA DE BACKUP

### 🇪🇸 Español

**Frecuencia:** Diario a las 4:00 AM (America/Sao_Paulo)

**Procedimiento:**
1. mysqldump de EspoCRM (VPS 2)
2. Snapshots de Qdrant para cada colección
3. Compresión en archivo .tar.gz
4. Pull desde PC local vía rsync (4:30 AM)
5. Retención: 7 días

**RPO (Recovery Point Objective):** Máximo 15 horas de pérdida de datos

**RTO (Recovery Time Objective):** < 1 hora para restauración completa

**Verificación:**
- Test de restauración mensual (primer sábado de cada mes)
- Checksum SHA256 de cada backup
- Notificación Telegram éxito/fallo

### 🇧🇷 Português

**Frequência:** Diário às 4:00 AM (America/Sao_Paulo)

**Procedimento:**
1. mysqldump do EspoCRM (VPS 2)
2. Snapshots do Qdrant para cada coleção
3. Compressão em arquivo .tar.gz
4. Pull desde PC local via rsync (4:30 AM)
5. Retenção: 7 dias

**RPO (Recovery Point Objective):** Máximo 15 horas de perda de dados

**RTO (Recovery Time Objective):** < 1 hora para restauração completa

**Verificação:**
- Teste de restauração mensal (primeiro sábado de cada mês)
- Checksum SHA256 de cada backup
- Notificação Telegram sucesso/falha

---

## MULTI-TENANCY / MULTI-TENÊNCIA

### 🇪🇸 Español

**Método de separación:**
- Campo `tenant_id` en todas las tablas de MySQL
- Colecciones separadas en Qdrant: `rag_cliente_{tenant_id}`
- Filtros obligatorios en todas las consultas

**Ejemplo de filtro Qdrant:**
```json
{
  "filter": {
    "must": [
      { "key": "tenant_id", "match": { "value": "cliente_001" } }
    ]
  }
}
```

**Índices de base de datos:**

```sql
CREATE INDEX idx_mensajes_tenant_fecha ON mensajes(tenant_id, fecha);
CREATE INDEX idx_clientes_telefono ON clientes(telefono);
```

**Validación:**

    Cada consulta debe incluir WHERE tenant_id = ?
    Log de acceso por tenant para auditoría
    Nunca exponer datos de un cliente a otro

### 🇧🇷 Português
**Método de separação:**

    Campo tenant_id em todas as tabelas do MySQL
    Coleções separadas no Qdrant: rag_cliente_{tenant_id}
    Filtros obrigatórios em todas as consultas

**Exemplo de filtro Qdrant:**

```json

{
  "filter": {
    "must": [
      { "key": "tenant_id", "match": { "value": "cliente_001" } }
    ]
  }
}
```

**Índices de banco de dados:**

```sql

CREATE INDEX idx_mensajes_tenant_fecha ON mensajes(tenant_id, fecha);
CREATE INDEX idx_clientes_telefono ON clientes(telefone);
```

**Validação:**

    Cada consulta deve incluir WHERE tenant_id = ?
    Log de acesso por tenant para auditoria
    Nunca expor dados de um cliente a outro

---

## CLIENT CAPACITY / CAPACIDADE DE CLIENTES

### 🇪🇸 Español

**Configuración inicial (conservadora):**

    VPS 1: 3 clientes (n8n + uazapi)
    VPS 2: 6 clientes (EspoCRM + MySQL + Qdrant)
    VPS 3: 3 clientes (n8n + uazapi)
    Total inicial: 6 clientes (3 Full + 3 Light, o 6 Full)

**Configuración máxima (si todo funciona perfectamente):**

    VPS 1: 4 clientes
    VPS 2: 8 clientes
    VPS 3: 4 clientes
    Total máximo: 8 clientes

**Criterios para escalar de 3 a 4 clientes por VPS:**

    RAM promedio < 70% sostenido (30 días)
    CPU pico < 80% en horas pico (30 días)
    Respuesta WhatsApp < 5 segundos promedio
    0 incidentes críticos en 30 días
    100% backup exitoso en 30 días
    0 quejas de clientes

### 🇧🇷 Português

**Configuração inicial (conservadora):**

    VPS 1: 3 clientes (n8n + uazapi)
    VPS 2: 6 clientes (EspoCRM + MySQL + Qdrant)
    VPS 3: 3 clientes (n8n + uazapi)
    Total inicial: 6 clientes (3 Full + 3 Light, ou 6 Full)

**Configuração máxima (se tudo funcionar perfeitamente):**

    VPS 1: 4 clientes
    VPS 2: 8 clientes
    VPS 3: 4 clientes
    Total máximo: 8 clientes

**Critérios para escalar de 3 para 4 clientes por VPS:**

    RAM média < 70% sustentado (30 dias)
    CPU pico < 80% em horas de pico (30 dias)
    Resposta WhatsApp < 5 segundos média
    0 incidentes críticos em 30 dias
    100% backup exitoso em 30 dias
    0 reclamações de clientes

---

## SCALABILITY PLAN / PLANO DE ESCALABILIDADE

### 🇪🇸 Español

**Fase 1 (Mes 1-4): 6 clientes estables**

    Validar infraestructura base
    Pasar TEST DE INCENDIO (todos los escenarios de fallo)
    Establecer reputación en la ciudad

**Fase 2 (Mes 5-8): 8 clientes (máximo con KVM1)**

    Escalar solo si todos los criterios se cumplen
    Ingreso neto objetivo: R$ 2.860/mes

**Fase 3 (Mes 9+): Upgrade a KVM2 o más VPS**

    Solo si hay lista de espera de clientes
    Ingreso neto confirmado > R$ 3.000/mes por 60 días
    RAM consistentemente > 75% en KVM1

**Principio fundamental:**

    "Mejor 6 meses completado que 4 meses abandonado por burnout.
    La estabilidad vende más que la velocidad.
    Tu laboratorio merece cimientos sólidos, tanto en el campo como en la nube."

### 🇧🇷 Português

**Fase 1 (Mês 1-4): 6 clientes estáveis**

    Validar infraestrutura base
    Passar TESTE DE INCÊNDIO (todos os cenários de falha)
    Estabelecer reputação na cidade

**Fase 2 (Mês 5-8): 8 clientes (máximo com KVM1)**

    Escalar apenas se todos os critérios forem cumpridos
    Receita líquida objetivo: R$ 2.860/mês

**Fase 3 (Mês 9+): Upgrade para KVM2 ou mais VPS**

    Apenas se houver lista de espera de clientes
    Receita líquida confirmada > R$ 3.000/mês por 60 dias
    RAM consistentemente > 75% em KVM1

**Princípio fundamental:**

    "Melhor 6 meses completado que 4 meses abandonado por burnout.
    A estabilidade vende mais que a velocidade.
    Seu laboratório merece fundamentos sólidos, tanto no campo quanto na nuvem."

---

## CONTACT & HANDOVER / CONTATO E TRANSFERÊNCIA

### 🇪🇸 Español

**Para ingenieros que continúen este proyecto:**

    Leer primero: 00-CONTEXT/README.md (reglas de Cursor)
    Revisar:      01-RULES/ (todas las reglas de desarrollo)
    Estudiar:     02-SKILLS/ (patrones reutilizables)
    Entender:     03-AGENTS/ (agentes de infraestructura y clientes)
    Ejecutar:     04-WORKFLOWS/ (workflows de n8n)
    Configurar:   05-CONFIGURATIONS/ (docker-compose, scripts, .env)
    Programar:    06-PROGRAMMING/ (patrones de código)
    Seguir:       07-PROCEDURES/ (procedimientos operativos)

**Contacto:** Mantis-AgenticDev (Facundo) - Rio Grande do Sul, Brasil

### 🇧🇷 Português

**Para engenheiros que continuarem este projeto:**

    Ler primeiro: 00-CONTEXT/README.md (regras do Cursor)
    Revisar:      01-RULES/ (todas as regras de desenvolvimento)
    Estudar:      02-SKILLS/ (padrões reutilizáveis)
    Entender:     03-AGENTS/ (agentes de infraestrutura e clientes)
    Executar:     04-WORKFLOWS/ (workflows de n8n)
    Configurar:   05-CONFIGURATIONS/ (docker-compose, scripts, .env)
    Programar:    06-PROGRAMMING/ (padrões de código)
    Seguir:       07-PROCEDURES/ (procedimentos operacionais)

**Contato:** Mantis-AgenticDev (Facundo) - Rio Grande do Sul, Brasil

Versão 1.0.3
Fecha   / Data 30 marzo 2026
Cambios / Mudanças Documneto Inicial
Autor   / Autor Facundo

Este documento está bajo licencia Creative Commons para uso interno del proyecto. / Este documento está sob licença Creative Commons para uso interno do projeto.
