---
artifact_id: "telemetry-export-collector"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/telemetry-export-collector.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/telemetry-export-collector.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:telemetry-export-v1"
generated_at: "2026-05-26T13:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["data-plane-infra", "observability-stack-deployment"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Telemetry Export & Collector Configuration

> **Contrato modular**: Artefato filho do Master Agent. Gera configurações de coletores OpenTelemetry (sidecar, gateway) para exportar logs, métricas e traces dos serviços LangSmith para backends de observabilidade.

## 🎯 Propósito

Permitir que a telemetria dos serviços LangSmith (backend, platform, playground, queue, etc.) seja coletada e exportada para sistemas como Datadog, Grafana, Prometheus ou Elastic, usando o OpenTelemetry Collector.

## 📋 Especificação (SDD)
- **Entradas**: Namespace do Kubernetes, endpoints dos backends, tipo de exportador
- **Saídas**: YAML de configuração do OTel Collector (sidecar e gateway)
- **Side Effects**: Scraping de métricas Prometheus, coleta de logs de arquivos, recepção OTLP
- **Constraints Aplicáveis**: C1, C5, C8
- **Dependências**: OpenTelemetry Collector, Kubernetes, PyYAML

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")

# ─── IMPLEMENTAÇÃO ──────────────────────────────────────────────────────
import yaml
from typing import List, Dict, Optional

# ═══════════════════════════════════════════════════════════════════════════
# 1. CONFIGURADOR DE COLETOR SIDECAR PARA LOGS
# ═══════════════════════════════════════════════════════════════════════════
class SidecarLogCollector:
    def __init__(self, namespace: str, logs_endpoint: str):
        self.namespace = namespace
        self.logs_endpoint = logs_endpoint

    def generate_config(self) -> str:
        config = {
            "mode": "sidecar",
            "image": "otel/opentelemetry-collector-contrib",
            "config": {
                "receivers": {
                    "filelog": {
                        "exclude": ["**/otc-container/*.log"],
                        "include": [f"/var/log/pods/${{POD_NAMESPACE}}_${{POD_NAME}}_${{POD_UID}}/*/*.log"],
                        "include_file_name": False,
                        "include_file_path": True,
                        "operators": [{"id": "container-parser", "type": "container"}],
                        "retry_on_failure": {"enabled": True},
                        "start_at": "end"
                    }
                },
                "processors": {
                    "batch": {"send_batch_size": 8192, "timeout": "10s"},
                    "memory_limiter": {"check_interval": "1m", "limit_percentage": 90, "spike_limit_percentage": 80}
                },
                "exporters": {
                    "otlphttp/logs": {"endpoint": self.logs_endpoint}
                },
                "service": {
                    "pipelines": {
                        "logs/langsmith": {
                            "receivers": ["filelog"],
                            "processors": ["batch", "memory_limiter"],
                            "exporters": ["otlphttp/logs"]
                        }
                    }
                }
            },
            "env": [
                {"name": "POD_NAME", "valueFrom": {"fieldRef": {"fieldPath": "metadata.name"}}},
                {"name": "POD_NAMESPACE", "valueFrom": {"fieldRef": {"fieldPath": "metadata.namespace"}}},
                {"name": "POD_UID", "valueFrom": {"fieldRef": {"fieldPath": "metadata.uid"}}}
            ],
            "volumes": [{"name": "varlogpods", "hostPath": {"path": "/var/log/pods"}}],
            "volumeMounts": [{"name": "varlogpods", "mountPath": "/var/log/pods", "readOnly": True}]
        }
        return yaml.dump(config, sort_keys=False)

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURADOR DE COLETOR GATEWAY (MÉTRICAS + TRACES)
# ═══════════════════════════════════════════════════════════════════════════
class GatewayCollector:
    def __init__(self, namespace: str, metrics_endpoint: str, traces_endpoint: str, langsmith_services: List[str] = None):
        self.namespace = namespace
        self.metrics_endpoint = metrics_endpoint
        self.traces_endpoint = traces_endpoint
        self.services = langsmith_services or ["backend", "platform", "playground", "redis", "postgres"]

    def generate_prometheus_scrape_config(self) -> dict:
        return {
            "job_name": "langsmith-services",
            "metrics_path": "/metrics",
            "scrape_interval": "15s",
            "kubernetes_sd_configs": [{"role": "endpoints", "namespaces": {"names": [self.namespace]}}],
            "relabel_configs": [
                {"source_labels": ["__meta_kubernetes_service_name"], "regex": "langsmith-.*", "action": "keep"},
                {"source_labels": ["__meta_kubernetes_endpoint_port_name"], "regex": "(backend|platform|playground|redis-metrics|postgres-metrics|metrics)", "action": "keep"},
                {"source_labels": ["__meta_kubernetes_service_name"], "target_label": "k8s_service"},
                {"source_labels": ["__meta_kubernetes_pod_name"], "target_label": "k8s_pod"},
                {"source_labels": ["__address__"], "target_label": "instance"}
            ]
        }

    def generate_config(self) -> str:
        config = {
            "mode": "deployment",
            "image": "otel/opentelemetry-collector-contrib",
            "config": {
                "receivers": {
                    "prometheus": {
                        "config": {
                            "scrape_configs": [self.generate_prometheus_scrape_config()]
                        }
                    },
                    "otlp": {
                        "protocols": {
                            "grpc": {"endpoint": "0.0.0.0:4317"},
                            "http": {"endpoint": "0.0.0.0:4318"}
                        }
                    }
                },
                "processors": {
                    "batch": {"send_batch_size": 8192, "timeout": "10s"},
                    "memory_limiter": {"check_interval": "1m", "limit_percentage": 90, "spike_limit_percentage": 80}
                },
                "exporters": {
                    "otlphttp/metrics": {"endpoint": self.metrics_endpoint},
                    "otlphttp/traces": {"endpoint": self.traces_endpoint}
                },
                "service": {
                    "pipelines": {
                        "metrics/langsmith": {
                            "receivers": ["prometheus"],
                            "processors": ["batch", "memory_limiter"],
                            "exporters": ["otlphttp/metrics"]
                        },
                        "traces/langsmith": {
                            "receivers": ["otlp"],
                            "processors": ["batch", "memory_limiter"],
                            "exporters": ["otlphttp/traces"]
                        }
                    }
                }
            }
        }
        return yaml.dump(config, sort_keys=False)

# ═══════════════════════════════════════════════════════════════════════════
# 3. GERADOR DE CONFIGURAÇÃO DE TRACING PARA LANGGRAPH
# ═══════════════════════════════════════════════════════════════════════════
class TracingEnabler:
    @staticmethod
    def generate_helm_values(tracing_endpoint: str) -> dict:
        return {
            "observability": {
                "tracing": {
                    "enabled": True,
                    "endpoint": tracing_endpoint,
                    "useTls": True,
                    "env": "ls_self_hosted",
                    "exporter": "http"
                }
            }
        }
```

## 🧪 Testes Unitários (TDD)
```python
import yaml
from telemetry_export_collector import SidecarLogCollector, GatewayCollector, TracingEnabler

def test_sidecar_yaml():
    coll = SidecarLogCollector("langsmith", "https://logs.example.com")
    y = coll.generate_config()
    data = yaml.safe_load(y)
    assert data["mode"] == "sidecar"
    assert "filelog" in data["config"]["receivers"]

def test_gateway_prometheus_config():
    gw = GatewayCollector("ls-ns", "metrics:4317", "traces:4318")
    scrape = gw.generate_prometheus_scrape_config()
    assert scrape["job_name"] == "langsmith-services"
    relabel = scrape["relabel_configs"]
    assert any(r["action"] == "keep" for r in relabel)

def test_gateway_yaml():
    gw = GatewayCollector("ls-ns", "http://metrics:4317", "http://traces:4318")
    y = gw.generate_config()
    data = yaml.safe_load(y)
    assert "prometheus" in data["config"]["receivers"]

def test_tracing_enabler():
    values = TracingEnabler.generate_helm_values("http://otlp:4318/v1/traces")
    assert values["observability"]["tracing"]["enabled"] is True
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/telemetry-export-collector.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[data-plane-infra.md]]
- [[observability-stack-deployment.md]]
