---
artifact_id: "observability-stack-deployment"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/observability-stack-deployment.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/observability-stack-deployment.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:obs-stack-deploy-v1"
generated_at: "2026-05-26T14:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["telemetry-export-collector", "data-plane-infra"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Observability Stack Deployment (LGTM + OpenTelemetry)

> **Contrato modular**: Artefato filho do Master Agent. Automatiza a implantação do stack de observabilidade baseado em Loki, Mimir, Tempo e Grafana via Helm, incluindo coletores OpenTelemetry e exportadores Prometheus.

## 🎯 Propósito

Fornecer um pipeline completo para provisionar um stack de observabilidade dedicado ao LangSmith, com dashboards pré-configurados, coleta de logs, métricas e traces, e integração automática com o Agent Server.

## 📋 Especificação (SDD)
- **Entradas**: Namespace, configurações de recursos, endpoints de exportação
- **Saídas**: Stack rodando, Grafana acessível, coletores injetados nos pods do LangSmith
- **Side Effects**: Criação de deployments, serviços, volumes persistentes, configuração de sidecars
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: Helm, Kubernetes, `cert-manager`, `opentelemetry-operator`

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
import subprocess, yaml, os, time, json
from typing import Dict, Optional, List

# ═══════════════════════════════════════════════════════════════════════════
# 1. PRÉ-REQUISITOS: CERT-MANAGER E OPENTELEMETRY OPERATOR
# ═══════════════════════════════════════════════════════════════════════════
class PrerequisitesInstaller:
    @staticmethod
    def install_cert_manager():
        subprocess.run(["helm", "repo", "add", "jetstack", "https://charts.jetstack.io"], check=True)
        subprocess.run(["helm", "repo", "update"], check=True)
        subprocess.run([
            "helm", "install", "cert-manager", "jetstack/cert-manager",
            "-n", "cert-manager", "--create-namespace"
        ], check=True)
        mantis_log("INFO", "cert_manager_installed")

    @staticmethod
    def install_otel_operator(namespace: str):
        subprocess.run(["helm", "repo", "add", "open-telemetry", "https://open-telemetry.github.io/opentelemetry-helm-charts"], check=True)
        subprocess.run(["helm", "repo", "update"], check=True)
        subprocess.run([
            "helm", "install", "opentelemetry-operator",
            "open-telemetry/opentelemetry-operator",
            "-n", namespace
        ], check=True)
        mantis_log("INFO", "otel_operator_installed", namespace)

# ═══════════════════════════════════════════════════════════════════════════
# 2. GERADOR DE CONFIGURAÇÃO DO HELM CHART (LANGGRAPH-OBSERVABILITY)
# ═══════════════════════════════════════════════════════════════════════════
class ObservabilityChartConfig:
    def __init__(self, langsmith_namespace: str, obs_namespace: str):
        self.langsmith_ns = langsmith_namespace
        self.obs_ns = obs_namespace

    def generate_full_stack_values(self,
                                   logs_enabled: bool = True,
                                   metrics_enabled: bool = True,
                                   traces_enabled: bool = True,
                                   loki_resources: dict = None,
                                   mimir_resources: dict = None,
                                   tempo_resources: dict = None) -> dict:
        values = {
            "otelCollector": {
                "logs": {"enabled": logs_enabled},
                "metrics": {"enabled": metrics_enabled},
                "traces": {"enabled": traces_enabled}
            },
            "loki": {"enabled": logs_enabled, "resources": loki_resources or {"requests": {"cpu": "2", "memory": "2Gi"}, "limits": {"cpu": "3", "memory": "4Gi"}}},
            "mimir": {"enabled": metrics_enabled, "resources": mimir_resources or {"requests": {"cpu": "1", "memory": "2Gi"}, "limits": {"cpu": "2", "memory": "4Gi"}}},
            "tempo": {"enabled": traces_enabled, "resources": tempo_resources or {"requests": {"cpu": "1", "memory": "4Gi"}, "limits": {"cpu": "2", "memory": "6Gi"}}},
            "grafana": {"enabled": True},
            "prometheusExporters": {
                "postgres": {"enabled": True},
                "redis": {"enabled": True},
                "nginx": {"enabled": True},
                "kubeStateMetrics": {"enabled": True}
            }
        }
        return values

    def save_values(self, values: dict, path: str = "langsmith_obs_config.yaml"):
        with open(path, "w") as f:
            yaml.dump(values, f, default_flow_style=False)
        mantis_log("INFO", "obs_values_saved", path)

# ═══════════════════════════════════════════════════════════════════════════
# 3. DEPLOYER DO STACK DE OBSERVABILIDADE
# ═══════════════════════════════════════════════════════════════════════════
class ObservabilityStackDeployer:
    def __init__(self, release_name: str, namespace: str, chart_version: str = ""):
        self.release = release_name
        self.namespace = namespace
        self.chart_version = chart_version

    def install(self, values_file: str):
        cmd = ["helm", "install", self.release, "langchain/langsmith-observability",
               "-n", self.namespace, "--values", values_file, "--wait", "--debug"]
        if self.chart_version:
            cmd += ["--version", self.chart_version]
        mantis_log("INFO", "obs_stack_install_start")
        subprocess.run(cmd, check=True)
        mantis_log("INFO", "obs_stack_installed")

    def upgrade(self, values_file: str):
        subprocess.run([
            "helm", "upgrade", self.release, "langchain/langsmith-observability",
            "-n", self.namespace, "-f", values_file, "--wait", "--debug"
        ], check=True)

    def get_grafana_password(self) -> str:
        cmd = ["kubectl", "get", "secret", f"{self.release}-grafana", "-n", self.namespace,
               "-o", "jsonpath={.data.admin-password}"]
        encoded = subprocess.check_output(cmd, text=True)
        import base64
        return base64.b64decode(encoded).decode()

# ═══════════════════════════════════════════════════════════════════════════
# 4. INJEÇÃO DE SIDECAR NOS PODS DO LANGSMITH
# ═══════════════════════════════════════════════════════════════════════════
class SidecarInjector:
    def __init__(self, langsmith_namespace: str, obs_namespace: str, sidecar_crd_name: str):
        self.langsmith_ns = langsmith_namespace
        self.obs_ns = obs_namespace
        self.sidecar_crd = sidecar_crd_name

    def enable_injection(self):
        annotation = f"sidecar.opentelemetry.io/inject: {self.obs_ns}/{self.sidecar_crd}"
        cmd = ["kubectl", "annotate", "namespace", self.langsmith_ns, annotation, "--overwrite"]
        subprocess.run(cmd, check=True)
        mantis_log("INFO", "sidecar_injection_enabled", f"ns={self.langsmith_ns}")

    def patch_langsmith_config(self, values_file: str, gateway_service: str):
        # Adiciona configuração de tracing ao values do LangSmith
        with open(values_file, "r") as f:
            langsmith_values = yaml.safe_load(f) or {}
        langsmith_values.setdefault("commonPodAnnotations", {})
        langsmith_values["commonPodAnnotations"]["sidecar.opentelemetry.io/inject"] = f"{self.obs_ns}/{self.sidecar_crd}"
        langsmith_values.setdefault("observability", {})
        langsmith_values["observability"]["tracing"] = {
            "enabled": True,
            "endpoint": f"http://{gateway_service}.{self.obs_ns}.svc.cluster.local:4318/v1/traces"
        }
        with open(values_file, "w") as f:
            yaml.dump(langsmith_values, f, default_flow_style=False)
        mantis_log("INFO", "langsmith_config_patched", values_file)

# ═══════════════════════════════════════════════════════════════════════════
# 5. ORQUESTRADOR COMPLETO
# ═══════════════════════════════════════════════════════════════════════════
class ObservabilityOrchestrator:
    def __init__(self, langsmith_ns: str, obs_ns: str):
        self.langsmith_ns = langsmith_ns
        self.obs_ns = obs_ns
        self.chart_config = ObservabilityChartConfig(langsmith_ns, obs_ns)

    def deploy_full_stack(self, logs: bool = True, metrics: bool = True, traces: bool = True):
        # Pré-requisitos
        PrerequisitesInstaller.install_cert_manager()
        PrerequisitesInstaller.install_otel_operator(self.obs_ns)

        # Gerar valores
        values = self.chart_config.generate_full_stack_values(logs, metrics, traces)
        self.chart_config.save_values(values)

        # Deploy do stack
        deployer = ObservabilityStackDeployer("langsmith-observability", self.obs_ns)
        deployer.install("langsmith_obs_config.yaml")

        # Aguardar pods
        time.sleep(30)
        self._wait_for_pods(["loki-0", "mimir-0", "tempo-0", "grafana"])

        # Configurar sidecar injection
        sidecar_crd = self._get_sidecar_crd()
        injector = SidecarInjector(self.langsmith_ns, self.obs_ns, sidecar_crd)
        gateway_svc = f"{self.obs_ns}-gateway-collector"  # simplificado
        injector.patch_langsmith_config("langsmith_config.yaml", gateway_svc)
        injector.enable_injection()

        mantis_log("INFO", "full_stack_deployed", f"Grafana password: {deployer.get_grafana_password()}")

    def _wait_for_pods(self, pod_prefixes: List[str]):
        for prefix in pod_prefixes:
            mantis_log("DEBUG", "waiting_pod", prefix)
            while True:
                out = subprocess.check_output(["kubectl", "get", "pods", "-n", self.obs_ns, "-o", "name"], text=True)
                if any(p.startswith(f"pod/{prefix}") for p in out.splitlines()):
                    break
                time.sleep(5)

    def _get_sidecar_crd(self) -> str:
        out = subprocess.check_output(["kubectl", "get", "opentelemetrycollectors", "-n", self.obs_ns, "-o", "json"], text=True)
        collectors = json.loads(out)
        for item in collectors.get("items", []):
            if item.get("spec", {}).get("mode") == "sidecar":
                return item["metadata"]["name"]
        raise RuntimeError("Sidecar CRD não encontrado")
```

## 🧪 Testes Unitários (TDD)
```python
import yaml
from observability_stack_deployment import ObservabilityChartConfig, SidecarInjector, ObservabilityOrchestrator

def test_generate_values():
    cfg = ObservabilityChartConfig("ls-ns", "obs-ns")
    values = cfg.generate_full_stack_values()
    assert values["loki"]["enabled"] == True
    assert values["tempo"]["enabled"] == True
    assert "grafana" in values

def test_save_values(tmp_path):
    cfg = ObservabilityChartConfig("ls-ns", "obs-ns")
    values = cfg.generate_full_stack_values()
    p = tmp_path / "values.yaml"
    cfg.save_values(values, str(p))
    with open(p) as f:
        loaded = yaml.safe_load(f)
    assert loaded["loki"]["enabled"]

def test_sidecar_injector_annotation():
    injector = SidecarInjector("ls-ns", "obs-ns", "sidecar-collector")
    with patch('subprocess.run') as mock_run:
        injector.enable_injection()
        mock_run.assert_called_once()
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/observability-stack-deployment.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[telemetry-export-collector.md]]
- [[data-plane-infra.md]]
