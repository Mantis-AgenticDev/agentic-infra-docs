---
file_id: FAC-BIZ-003
file_name: facundo-business-model.md
version: 2.0.0
created: 2026-04-01
last_updated: 2026-04-01
author: Facundo (Mantis-AgenticDev)
category: BUSINESS
priority: HIGH
tokens_estimate: 1800
related_files:
  - PROJECT_OVERVIEW.md
  - facundo-core-context.md
  - ../07-PROCEDURES/onboarding-client.md
  - ../04-WORKFLOWS/BILLING-001-Generate-Invoice.json
ai_navigation:
  read_after: facundo-core-context.md
  required_for: [pricing, client-management, scaling-decisions, partner-split]
  update_frequency: quarterly
  validation_rules:
    - revenue_target must be >= 2500 BRL/month
    - partner_split must be 45% each after reserve
    - emergency_fund must be 10% of net profit
---

# FACUNDO BUSINESS MODEL - MANTIS AGENTIC

## 💰 ESTRUCTURA DE COSTOS FIJOS (Mensuales)

| Concepto                 | Costo Mensual | Detalle                                   |
|--------------------------|---------------|-------------------------------------------|
| **VPS Hostinger**        | R$ 200        | 3 VPS x R$ 800/12 meses (contrato 2 años) |
| **uazapi**               | R$ 150        | 100 celulares                             |
| **Deepgram**             | R$ 200        | Transcripción de audio                    |
| **OpenRouter**           | R$ 200        | LLMs (Claude, Gemini, GPT)                |
| **WhatsApp (2 cuentas)** | R$ 120        | Cuentas propias para pruebas/demo         |
| **MEI**                  | R$ 60         | Impuesto mensual MEI                      |
| **TOTAL COSTOS FIJOS**   | **R$ 930**    |                                           |

> ⚠️ **Nota:** Este es el costo base. Los costos variables (APIs por cliente adicional) se calculan aparte.

---

## 💼 PLANES DE SERVICIO

| Característica | Plan Básico | Plan Full           | Plan Enterprise* |
|----------------|-------------|---------------------|------------------|
| **Precio/mes** | **R$ 399**  | **R$ 499**          | **R$ 1.199**     |
| Clientes máx.  | 6           | 8                   | 12+              |
| WhatsApp       | 1 número    | 2 números           | Ilimitado        |
| RAG queries    | 500/mes     | 2.000/mes           | Ilimitado        |
| CRM (Espo)     | Solo logs   | Gestión completa    | Personalizado    |
| Soporte        | Email 48h   | Telegram 10min      | Dedicado 24/7    |
| Backup         | Semanal     | Diario + validación | Multi-región     |

*Enterprise requiere infraestructura dedicada (fuera de los 3 VPS base)

---

## 📊 PROYECCIÓN FINANCIERA - ESCENARIO BASE

### Escenario 1: 6 clientes (3 Básico + 3 Full)

| Concepto                   | Cálculo                     | Valor        |
|----------------------------|-----------------------------|--------------|
| Ingreso Bruto              | (3 x R$ 399) + (3 x R$ 499) | **R$ 2.694** |
| (-) Costos Fijos           |                             | **- R$ 930** |
| (-) Costos Variables*      | Estimado 6 clientes         | **- R$ 300** |
| **= EBITDA**               |                             | **R$ 1.464** |
| (-) Fondo Emergencia (10%) |                             | **- R$ 146** |
| **= Distribución**         |                             | **R$ 1.318** |
| Socio 1 (Facundo)          | 50% de distribución         | **R$ 659**   |
| Socio 2                    | 50% de distribución         | **R$ 659**   |

*EBITDA Earnings Before Interest, Taxes, Depreciation, and Amortization

### Escenario 2: 8 clientes (4 Básico + 4 Full) - OBJETIVO

| Concepto                   | Cálculo                     | Valor        |
|----------------------------|-----------------------------|--------------|
| Ingreso Bruto              | (4 x R$ 399) + (4 x R$ 499) | **R$ 3.592** |
| (-) Costos Fijos           |                             | **- R$ 930** |
| (-) Costos Variables*      | Estimado 8 clientes         | **- R$ 400** |
| **= EBITDA**               |                             | **R$ 2.262** |
| (-) Fondo Emergencia (10%) |                             | **- R$ 226** |
| **= Distribución**         |                             | **R$ 2.036** |
| Socio 1 (Facundo)          | 50% de distribución         | **R$ 1.018** |
| Socio 2                    | 50% de distribución         | **R$ 1.018** |

### Escenario 3: 10 clientes (5 Básico + 5 Full) - MÁXIMO

| Concepto                   | Cálculo                     | Valor        |
|----------------------------|-----------------------------|--------------|
| Ingreso Bruto              | (5 x R$ 399) + (5 x R$ 499) | **R$ 4.490** |
| (-) Costos Fijos           |                             | **- R$ 930** |
| (-) Costos Variables*      | Estimado 10 clientes        | **- R$ 500** |
| **= EBITDA**               |                             | **R$ 3.060** |
| (-) Fondo Emergencia (10%) |                             | **- R$ 306** |
| **= Distribución**         |                             | **R$ 2.754** |
| Socio 1 (Facundo)          | 50% de distribución         | **R$ 1.377** |
| Socio 2                    | 50% de distribución         | **R$ 1.377** |

*Costos variables incluyen: APIs OpenRouter (consumo por cliente), Deepgram, y otros servicios bajo demanda.

---

## 🎯 OBJETIVOS FINANCIEROS

| Objetivo                          | Valor        | Plazo    |
|-----------------------------------|--------------|----------|
| **EBITDA mensual objetivo**       | R$ 2.500+    | Mes 6-8  |
| **Distribución por socio**        | R$ 1.000+    | Mes 6-8  |
| **Fondo de emergencia acumulado** | R$ 5.000     | 12 meses |
| **Punto de equilibrio**           | 4-5 clientes | Mes 3-4  |

---

## 🤝 ACUERDOS DE NIVEL DE SERVICIO (SLA)

| Métrica                | Compromiso | Penalización               |
|------------------------|------------|----------------------------|
| Uptime mensual         | 99.5%      | Crédito 10% del mes        |
| Respuesta alertas      | < 10 min   | Revisión inmediata         |
| Restauración backup    | < 60 min   | Compensación + post-mortem |
| Soporte crítico (Full) | < 10 min   | Escalamiento automático    |

---

## 📈 ESTRATEGIA DE CRECIMIENTO

| Fase | Clientes | Trigger                    | Acción                  |
|------|----------|----------------------------|-------------------------|
| 0    | 0-3      | Primeros contratos         | Operar 3 VPS base       |
| 1    | 4-6      | EBITDA > R$ 1.500          | Optimizar + caching     |
| 2    | 7-8      | Waitlist + 3 meses estable | Evaluar VPS-4           |
| 3    | 9+       | Demanda Enterprise         | Qdrant cloud gestionado |

---

## 📊 KPIs DE NEGOCIO
Key Performance Indicators

| KPI                 | Objetivo   | Fuente                 |
|---------------------|------------|------------------------|
| MRR                 | ≥ R$ 3.500 | EspoCRM + Stripe       |
| Churn mensual       | < 5%       | Registro cancelaciones |
| NPS                 | ≥ 40       | Encuesta trimestral    |
| Costo infra/cliente | ≤ R$ 116   | Hostinger + monitoreo  |
| Tiempo resolución   | < 10 min   | Logs Telegram          |

---

## ⚠️ NOTAS IMPORTANTES

1. **Fondo de Emergencia (10%):** Destinado a:
   - Fallas de hardware no cubiertas
   - Aumento imprevisto de costos de APIs
   - Meses de vacancia entre clientes

2. **Distribución:** 50% para cada socio DESPUÉS del fondo de emergencia

3. **Costos Variables:** Aumentan con:
   - Más clientes = más queries RAG
   - Mayor uso de transcripción (Deepgram)
   - Más números de WhatsApp

4. **Precios vs Mercado:**
   - Básico R$ 399       → Competitivo para pequeños negocios
   - Full R$ 499         → Principal fuente de ingresos
   - Enterprise R$ 1.199 → Para clientes con demanda alta

---

FIN DEL ARCHIVO - facundo-business-model.md
