---
artifact_id: "mission-control-operations"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/mission-control-operations.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/mission-control-operations.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:mission-control-ops-v1"
generated_at: "2026-05-27T16:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["standalone-deployment", "data-plane-infra", "observability-stack-deployment"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Mission Control Operations — Consola de Operação para LangSmith Auto-Hospedado

> **Contrato modular**: Artefato filho do Master Agent. Implementa a instalação, configuração e operação do Mission Control, a consola in-cluster para monitoramento e administração de LangSmith em Kubernetes.

## 🎯 Propósito

Fornecer uma biblioteca de automação para instalar, configurar e operar o Mission Control em clusters Kubernetes, permitindo monitoramento de pods, gestão de secrets, alertas e diagnóstico de deployments LangSmith auto-hospedados.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de `values.yaml`, namespace, credenciais de acesso, feature flags
- **Saídas**: Deployment funcional do Mission Control, UI acessível via port-forward
- **Side Effects**: Criação de RBAC (ClusterRole, ClusterRoleBinding), secrets, deployments
- **Constraints Aplicáveis**: C1 (Resiliência), C2 (Validação), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `kubectl`, `helm`, `curl`, `openssl`, Kubernetes cluster

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
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 1. VERIFICAÇÃO DE PRÉ-REQUISITOS
# ═══════════════════════════════════════════════════════════════════════════
import subprocess, os, yaml, json, base64, time
from typing import Optional, Dict, Any, List

class PrerequisitesChecker:
    """Verifica ferramentas e permissões necessárias para instalação do Mission Control."""
    REQUIRED_TOOLS = {
        "kubectl": "1.24",
        "helm": "3.0",
        "curl": "any",
    }

    @staticmethod
    def check_tools() -> Dict[str, bool]:
        results = {}
        for tool, min_version in PrerequisitesChecker.REQUIRED_TOOLS.items():
            try:
                subprocess.run([tool, "version"], capture_output=True, check=True, timeout=10)
                results[tool] = True
                mantis_log("INFO", "prereq_tool_ok", tool)
            except Exception as e:
                results[tool] = False
                mantis_log("ERROR", "prereq_tool_fail", f"{tool}: {str(e)}")
        return results

    @staticmethod
    def check_rbac() -> Dict[str, bool]:
        checks = [
            "kubectl auth can-i create clusterrole",
            "kubectl auth can-i create clusterrolebinding",
            "kubectl auth can-i create serviceaccount -n langsmith",
            "kubectl auth can-i create deployment -n langsmith",
            "kubectl auth can-i create secret -n langsmith",
        ]
        results = {}
        for check in checks:
            try:
                proc = subprocess.run(check.split(), capture_output=True, text=True, timeout=10)
                results[check] = "yes" in proc.stdout.lower()
                mantis_log("INFO", "rbac_check", f"{check}: {results[check]}")
            except Exception:
                results[check] = False
        return results

# ═══════════════════════════════════════════════════════════════════════════
# 2. GERENCIADOR DE INSTALAÇÃO
# ═══════════════════════════════════════════════════════════════════════════
class MissionControlInstaller:
    """Orquestra a instalação do Mission Control via Helm."""
    def __init__(self, namespace: str = "langsmith", release_name: str = "mission-control"):
        self.namespace = namespace
        self.release_name = release_name
        self.chart_repo = "https://langchain-ai.github.io/helm"
        self.chart_name = "langchain/mission-control"

    def add_helm_repo(self):
        subprocess.run(["helm", "repo", "add", "langchain", self.chart_repo], check=True)
        subprocess.run(["helm", "repo", "update", "langchain"], check=True)
        mantis_log("INFO", "helm_repo_added", self.chart_repo)

    def create_namespace(self):
        subprocess.run(["kubectl", "create", "namespace", self.namespace, "--dry-run=client", "-o", "yaml"], capture_output=True, text=True)
        subprocess.run(["kubectl", "apply", "-f", "-"], input=f"apiVersion: v1\nkind: Namespace\nmetadata:\n  name: {self.namespace}\n", text=True, check=True)
        mantis_log("INFO", "namespace_created", self.namespace)

    def create_auth_secret(self, username: str, password: str, jwt_secret: Optional[str] = None):
        cmd = [
            "kubectl", "create", "secret", "generic", "mission-control-auth",
            f"--namespace={self.namespace}",
            f"--from-literal=username={username}",
            f"--from-literal=password={password}",
        ]
        if jwt_secret:
            cmd.append(f"--from-literal=jwtSecret={jwt_secret}")
        cmd += ["--dry-run=client", "-o", "yaml"]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
        subprocess.run(["kubectl", "apply", "-f", "-"], input=proc.stdout, text=True, check=True)
        mantis_log("INFO", "auth_secret_created")

    def install_chart(self, values_file: str = "values.yaml", skip_rbac_check: bool = False):
        if not skip_rbac_check:
            rbac = PrerequisitesChecker.check_rbac()
            if not all(rbac.values()):
                raise RuntimeError(f"RBAC checks failed: {rbac}")

        cmd = [
            "helm", "upgrade", "--install", self.release_name,
            self.chart_name,
            f"--namespace={self.namespace}",
            "--create-namespace",
            f"--values={values_file}",
            "--rollback-on-failure",
        ]
        subprocess.run(cmd, check=True)
        mantis_log("INFO", "mission_control_installed", f"Release={self.release_name}")

    def wait_for_ready(self, timeout: int = 300):
        start = time.time()
        while time.time() - start < timeout:
            try:
                subprocess.run(
                    ["kubectl", "rollout", "status", f"statefulset/{self.release_name}-backend", "-n", self.namespace, "--timeout=30s"],
                    check=True, capture_output=True
                )
                subprocess.run(
                    ["kubectl", "rollout", "status", f"deployment/{self.release_name}-frontend", "-n", self.namespace, "--timeout=30s"],
                    check=True, capture_output=True
                )
                mantis_log("INFO", "mission_control_ready")
                return True
            except subprocess.CalledProcessError:
                time.sleep(10)
        raise TimeoutError(f"Mission Control não ficou pronto em {timeout}s")

# ═══════════════════════════════════════════════════════════════════════════
# 3. GERENCIADOR DE CONFIGURAÇÃO (VALUES.YAML)
# ═══════════════════════════════════════════════════════════════════════════
class ValuesConfigurator:
    """Gera e gerencia o arquivo values.yaml do Mission Control."""
    def __init__(self):
        self.defaults = {
            "namespace": "langsmith",
            "ingress": {"enabled": False},
            "config": {
                "auth": {"enabled": True},
                "features": {
                    "configSave": True,
                    "alerts": True,
                    "fixIssue": True,
                    "adopt": True,
                    "deploy": False,
                },
            },
            "diagnostics": {
                "persistence": {"enabled": False},
            },
        }

    def generate_values(self, overrides: Optional[Dict] = None) -> str:
        config = self.defaults.copy()
        if overrides:
            self._deep_merge(config, overrides)
        return yaml.dump(config, default_flow_style=False)

    def add_non_root_security(self, values: Dict) -> Dict:
        """Adiciona configuração para execução como non-root (UID 1001)."""
        values["backend"] = {
            "podSecurityContext": {
                "runAsNonRoot": True,
                "runAsUser": 1001,
                "runAsGroup": 1001,
                "fsGroup": 1001,
            },
            "securityContext": {
                "allowPrivilegeEscalation": False,
                "capabilities": {"drop": ["ALL"]},
            },
            "extraEnv": [
                {"name": "HOME", "value": "/tmp"},
                {"name": "HELM_CACHE_HOME", "value": "/tmp/.cache/helm"},
                {"name": "HELM_CONFIG_HOME", "value": "/tmp/.config/helm"},
                {"name": "HELM_DATA_HOME", "value": "/tmp/.local/share/helm"},
            ],
        }
        values["frontend"] = {
            "podSecurityContext": {
                "runAsNonRoot": True,
                "runAsUser": 1001,
                "runAsGroup": 1001,
            },
            "securityContext": {
                "allowPrivilegeEscalation": False,
                "capabilities": {"drop": ["ALL"]},
            },
        }
        return values

    def _deep_merge(self, base: Dict, override: Dict):
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._deep_merge(base[key], value)
            else:
                base[key] = value

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE PERMISSÕES RBAC
# ═══════════════════════════════════════════════════════════════════════════
class RBACManager:
    """Audita e gerencia permissões RBAC do Mission Control."""
    PERMISSIONS_REFERENCE = {
        "always_read": {
            "workloads": ["pods", "pods/log", "deployments", "statefulsets", "replicasets", "daemonsets", "jobs", "cronjobs"],
            "networking": ["services", "endpoints", "ingresses", "ingressclasses"],
            "storage": ["persistentvolumeclaims", "storageclasses"],
            "cluster": ["nodes", "namespaces", "events", "serviceaccounts", "resourcequotas"],
            "config": ["configmaps", "secrets"],
            "metrics": ["metrics.k8s.io pods/nodes"],
            "rbac": ["roles", "rolebindings", "clusterroles", "clusterrolebindings"],
            "crds": ["customresourcedefinitions", "leases", "scaledobjects", "httproutes", "virtualservices", "lgps"],
        },
        "feature_gated": {
            "configSave": {"secrets": ["mission-control-draft"]},
            "alerts": {"secrets": ["mission-control-alerts-*"]},
            "fixIssue": {"pods": ["delete"]},
            "adopt": {"secrets": ["patch"], "configmaps": ["patch"], "serviceaccounts": ["patch"], "deployments": ["patch"], "statefulsets": ["patch"]},
            "auth": {"secrets": ["mission-control-auth", "setup-token"], "deployments": ["mission-control-backend"]},
            "deploy": {"workloads": ["create", "update", "patch", "delete"], "networking": ["create", "update", "patch", "delete"], "rbac": ["create", "update", "patch", "delete"], "crds": ["create", "update", "patch", "delete"], "secrets": ["Helm release secrets"]},
        },
    }

    def audit_permissions(self, namespace: str) -> Dict:
        """Audita as permissões atuais do service account."""
        cmd = ["kubectl", "auth", "can-i", "--list", "-n", namespace, "--as", f"system:serviceaccount:{namespace}:mission-control"]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        return {"raw": proc.stdout, "parsed": self._parse_permissions(proc.stdout)}

    def _parse_permissions(self, raw: str) -> List[Dict]:
        permissions = []
        for line in raw.split("\n"):
            if line.strip():
                parts = line.split()
                if len(parts) >= 2:
                    permissions.append({"resource": parts[1], "verbs": parts[0].split(",")})
        return permissions

# ═══════════════════════════════════════════════════════════════════════════
# 5. OPERADOR DE DIAGNÓSTICO
# ═══════════════════════════════════════════════════════════════════════════
class DiagnosticsOperator:
    """Gerencia diagnósticos e troubleshooting do Mission Control."""
    @staticmethod
    def get_pod_status(namespace: str) -> List[Dict]:
        proc = subprocess.run(["kubectl", "get", "pods", "-n", namespace, "-o", "json"], capture_output=True, text=True)
        pods = json.loads(proc.stdout)
        return [{"name": p["metadata"]["name"], "status": p["status"]["phase"], "ready": all(c.get("ready") for c in p["status"].get("containerStatuses", []))} for p in pods.get("items", [])]

    @staticmethod
    def get_logs(namespace: str, pod_name: str, tail: int = 100) -> str:
        proc = subprocess.run(["kubectl", "logs", pod_name, "-n", namespace, f"--tail={tail}"], capture_output=True, text=True)
        return proc.stdout

    @staticmethod
    def port_forward(namespace: str, local_port: int = 3000, remote_port: int = 3000):
        subprocess.Popen(["kubectl", "port-forward", f"svc/mission-control-frontend", f"{local_port}:{remote_port}", "-n", namespace])
        mantis_log("INFO", "port_forward_started", f"localhost:{local_port} -> {namespace}/mission-control-frontend:{remote_port}")

# ═══════════════════════════════════════════════════════════════════════════
# 6. ORQUESTRADOR COMPLETO
# ═══════════════════════════════════════════════════════════════════════════
class MissionControlOrchestrator:
    """Orquestra o ciclo de vida completo do Mission Control."""
    def __init__(self, namespace: str = "langsmith"):
        self.installer = MissionControlInstaller(namespace)
        self.configurator = ValuesConfigurator()
        self.rbac = RBACManager()
        self.diag = DiagnosticsOperator()

    def full_install(self, username: str, password: str, non_root: bool = False, skip_rbac: bool = False):
        PrerequisitesChecker.check_tools()
        self.installer.add_helm_repo()
        self.installer.create_namespace()

        jwt_secret = base64.b64encode(os.urandom(32)).decode()
        self.installer.create_auth_secret(username, password, jwt_secret)

        values = yaml.safe_load(self.configurator.generate_values())
        if non_root:
            values = self.configurator.add_non_root_security(values)

        with open("mission-control-values.yaml", "w") as f:
            yaml.dump(values, f)

        self.installer.install_chart("mission-control-values.yaml", skip_rbac)
        self.installer.wait_for_ready()

        mantis_log("INFO", "mission_control_full_install_done")
        return {"username": username, "jwt_secret": jwt_secret[:16] + "...", "url": "http://localhost:3000"}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from mission_control_operations import (
    PrerequisitesChecker, ValuesConfigurator, RBACManager, DiagnosticsOperator
)

def test_prerequisites_check_tools():
    results = PrerequisitesChecker.check_tools()
    assert "kubectl" in results

def test_values_configurator_defaults():
    configurator = ValuesConfigurator()
    yaml_str = configurator.generate_values()
    data = yaml.safe_load(yaml_str)
    assert data["config"]["auth"]["enabled"] == True
    assert data["config"]["features"]["deploy"] == False

def test_values_configurator_non_root():
    configurator = ValuesConfigurator()
    values = yaml.safe_load(configurator.generate_values())
    values = configurator.add_non_root_security(values)
    assert values["backend"]["podSecurityContext"]["runAsUser"] == 1001
    assert "ALL" in values["backend"]["securityContext"]["capabilities"]["drop"]

def test_rbac_audit():
    rbac = RBACManager()
    perms = rbac._parse_permissions("get pods\nlist,watch deployments")
    assert len(perms) == 2
    assert perms[0]["resource"] == "pods"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/mission-control-operations.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[standalone-deployment.md]]
- [[data-plane-infra.md]]
- [[observability-stack-deployment.md]]
