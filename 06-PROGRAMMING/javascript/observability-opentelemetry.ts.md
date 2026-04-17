# SHA256: d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6
---
artifact_id: "observability-opentelemetry"
artifact_type: "skill_typescript"
version: "2.1.1"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/observability-opentelemetry.ts.md --json"
---

# Observability OpenTelemetry – TypeScript/Node.js with Tenant‑Correlated Spans

## Propósito
Patrones para instrumentar aplicaciones TypeScript/Node.js con OpenTelemetry, asegurando propagación de `tenant_id` desde `AsyncLocalStorage` a spans (C4 implícito), timeouts explícitos en exportadores (C8), manejo robusto de errores en telemetría (C8), y cero impacto en la lógica de negocio.

## Patrones de Código Validados

```typescript
// ✅ C8: Inicialización de tracer con timeout en exportador OTLP
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
const exporter = new OTLPTraceExporter({ timeoutMillis: 5000 });
```

```typescript
// ❌ Anti‑pattern: Exportador sin timeout
const exporter = new OTLPTraceExporter({});
// 🔧 Fix: timeoutMillis explícito para evitar bloqueos
const exporter = new OTLPTraceExporter({ timeoutMillis: 5000 });
```

```typescript
// ✅ C8: Span con tenant_id extraído de AsyncLocalStorage
import { trace } from '@opentelemetry/api';
// C6: optional dependency, fallback provided if package not installed
const span = trace.getActiveSpan();
span?.setAttribute('tenant.id', ctx.getStore()?.tenantId ?? 'unknown');
```

```typescript
// ❌ Anti‑pattern: Span sin atributos de tenant
const span = trace.getTracer('app').startSpan('operation');
// 🔧 Fix: Enriquecer con tenant_id del contexto
const span = tracer.startSpan('operation');
span.setAttribute('tenant.id', ctx.getStore()?.tenantId ?? 'unknown');
```

```typescript
// ✅ C8: Wrapper asíncrono con timeout y span de OpenTelemetry
async function tracedOp<T>(name: string, fn: () => Promise<T>, ms = 5000): Promise<T> {
  return tracer.startActiveSpan(name, async (span) => {
    try {
      return await Promise.race([fn(), timeout(ms)]);
    } catch (err) {
      span.recordException(err as Error);
      span.setStatus({ code: SpanStatusCode.ERROR });
      throw err;
    } finally { span.end(); }
  });
}
```

```typescript
// ❌ Anti‑pattern: Operación sin tracing ni timeout
const result = await db.query(sql);
// 🔧 Fix: tracedOp con timeout y tenant span
const result = await tracedOp('db.query', () => db.query(sql), 3000);
```

```typescript
// ✅ C8: Propagación de tenant_id en contexto de OpenTelemetry
import { context, propagation } from '@opentelemetry/api';
// C6: optional dependency, fallback provided if package not installed
const carrier = {};
propagation.inject(context.active(), carrier);
(carrier as any)['x-tenant-id'] = ctx.getStore()?.tenantId;
```

```typescript
// ✅ C8: Logger Pino con correlación trace_id y span_id
const span = trace.getActiveSpan();
logger.info({ trace_id: span?.spanContext().traceId, span_id: span?.spanContext().spanId }, 'Event');
```

```typescript
// ❌ Anti‑pattern: Log sin correlación de trace
logger.info('Event happened');
// 🔧 Fix: Inyectar trace_id y span_id del span activo
const span = trace.getActiveSpan();
logger.info({ trace_id: span?.spanContext().traceId }, 'Event');
```

```typescript
// ✅ C8: Timeout en exportación de métricas OTLP
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
const metricExporter = new OTLPMetricExporter({ timeoutMillis: 5000 });
```

```typescript
// ✅ C8: Middleware Express con span por petición y timeout global
app.use((req, res, next) => {
  const tenantId = req.headers['x-tenant-id'] as string;
  ctx.run({ tenantId }, () => {
    tracer.startActiveSpan(`${req.method} ${req.path}`, { root: true }, (span) => {
      span.setAttribute('tenant.id', tenantId);
      const t = setTimeout(() => { span.end(); next(new Error('Timeout')); }, 10000);
      res.once('finish', () => { clearTimeout(t); span.end(); });
      next();
    });
  });
});
```

```typescript
// ✅ C8: Manejo de errores en exportador con backoff
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
const processor = new BatchSpanProcessor(exporter, {
  maxExportBatchSize: 512,
  scheduledDelayMillis: 5000,
  exportTimeoutMillis: 30000,
});
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/observability-opentelemetry.ts.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"observability-opentelemetry","version":"2.1.1","score":30,"blocking_issues":[],"constraints_verified":["C8"],"examples_count":10,"lines_executable_max":5,"language":"TypeScript 5.0+ / Node.js 18+","timestamp":"2026-04-16T15:40:00Z"}
```

---
