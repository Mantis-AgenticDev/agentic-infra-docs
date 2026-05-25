---
artifact_id: "deploy-with-control-plane"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deploy-with-control-plane.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deploy-with-control-plane.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deploy-control-plane-v1"
generated_at: "2026-05-26T12:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["control-plane-management", "cicd-pipeline-agents"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Deploy with Control Plane (Hybrid/Self-Hosted)

> **Contrato modular**: Artefato filho do Master Agent. Implementa o fluxo completo de build, push e deploy de imagens Docker para o Control Plane, com suporte a registries privados.

## 🎯 Propósito

Automatizar o deploy de aplicações LangGraph em ambientes híbridos e self-hosted utilizando a UI do Control Plane, construindo imagens Docker, publicando em registry e criando deployments/revisões.

## 📋 Especificação (SDD)
- **Entradas**: Caminho do projeto, tag da imagem, registry URL, credenciais, listener ID, namespace
- **Saídas**: Deployment criado e respondendo no Agent Server
- **Side Effects**: Push de imagem, criação de pull secrets, atualização de revisões
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph-cli`, `docker`, `kubectl`, `helm`

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

# ─── LÓGICA DO MÓDULO ────────────────────────────────────────────────────
import subprocess, yaml, os, json, tempfile
from typing import Dict, Optional, List
from dataclasses import dataclass
import httpx
from tenacity import retry, stop_after_attempt, wait_fixed

# ═══════════════════════════════════════════════════════════════════════════
# 1. BUILD E PUSH DE IMAGEM
# ═══════════════════════════════════════════════════════════════════════════
class DockerImagePipeline:
    def __init__(self, project_dir: str):
        self.project_dir = project_dir

    def build(self, tag: str, platform: str = "linux/amd64") -> bool:
        cmd = ["langgraph", "build", "-t", tag, "--platform", platform]
        mantis_log("INFO", "build_start", tag)
        proc = subprocess.run(cmd, cwd=self.project_dir, capture_output=True, text=True)
        if proc.returncode == 0:
            mantis_log("INFO", "build_success", tag)
            return True
        mantis_log("ERROR", "build_fail", proc.stderr)
        return False

    def push(self, tag: str, registry: str, creds: Optional[Dict[str, str]] = None):
        if creds:
            self._docker_login(registry, creds)
        full_tag = f"{registry}/{tag}"
        subprocess.run(["docker", "tag", tag, full_tag], check=True)
        subprocess.run(["docker", "push", full_tag], check=True)
        mantis_log("INFO", "push_success", full_tag)

    def _docker_login(self, registry: str, creds: Dict[str, str]):
        subprocess.run(
            ["docker", "login", registry, "-u", creds["username"], "--password-stdin"],
            input=creds["password"], text=True, check=True
        )

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAÇÃO DE IMAGE PULL SECRETS
# ═══════════════════════════════════════════════════════════════════════════
class ImagePullSecretManager:
    @staticmethod
    def create_k8s_secret(namespace: str, secret_name: str, registry: str, username: str, password: str, email: str = "ops@company.com"):
        cmd = [
            "kubectl", "create", "secret", "docker-registry", secret_name,
            f"--namespace={namespace}",
            f"--docker-server={registry}",
            f"--docker-username={username}",
            f"--docker-password={password}",
            f"--docker-email={email}"
        ]
        subprocess.run(cmd, check=True)
        mantis_log("INFO", "pull_secret_created", secret_name)

    @staticmethod
    def patch_service_account(namespace: str, sa_name: str, secret_name: str):
        patch = json.dumps({"imagePullSecrets": [{"name": secret_name}]})
        subprocess.run(
            ["kubectl", "patch", "serviceaccount", sa_name, "-n", namespace, "-p", patch],
            check=True
        )
        mantis_log("INFO", "sa_patched", f"{sa_name} in {namespace}")

# ═══════════════════════════════════════════════════════════════════════════
# 3. CLIENTE PARA O CONTROL PLANE UI (SIMULAÇÃO DE API)
# ═══════════════════════════════════════════════════════════════════════════
class ControlPlaneDeployClient:
    """
    Cliente que interage com a API do Control Plane para criar deployments a partir de imagens.
    Assume endpoints semelhantes aos do Control Plane real.
    """
    def __init__(self, base_url: str, api_key: str):
        self.client = httpx.AsyncClient(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}"}
        )

    async def create_deployment(self, payload: dict) -> dict:
        resp = await self.client.post("/api/v1/deployments", json=payload)
        resp.raise_for_status()
        return resp.json()

    async def create_revision(self, deployment_id: str, image_url: str, env_vars: dict = None):
        payload = {"image_url": image_url, "env_vars": env_vars or {}}
        resp = await self.client.post(f"/api/v1/deployments/{deployment_id}/revisions", json=payload)
        return resp.json()

    async def close(self):
        await self.client.aclose()

# ═══════════════════════════════════════════════════════════════════════════
# 4. ORQUESTRADOR DE DEPLOY (FLUXO COMPLETO)
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class DeployConfig:
    project_dir: str
    image_tag: str
    registry: str
    deployment_name: str
    namespace: str
    listener_id: Optional[str] = None
    env_vars: Dict[str, str] = None
    platform: str = "linux/amd64"

class ControlPlaneDeployOrchestrator:
    def __init__(self, config: DeployConfig, cp_client: ControlPlaneDeployClient):
        self.config = config
        self.pipeline = DockerImagePipeline(config.project_dir)
        self.cp_client = cp_client

    async def deploy(self, creds: Optional[Dict[str, str]] = None, prod: bool = False) -> str:
        # Build
        if not self.pipeline.build(self.config.image_tag, self.config.platform):
            raise RuntimeError("Build da imagem falhou")
        # Push
        self.pipeline.push(self.config.image_tag, self.config.registry, creds)
        full_image = f"{self.config.registry}/{self.config.image_tag}"
        # Criar deployment via Control Plane
        payload = {
            "name": self.config.deployment_name,
            "image_url": full_image,
            "namespace": self.config.namespace,
            "listener_id": self.config.listener_id,
            "deployment_type": "Production" if prod else "Development",
            "env_vars": self.config.env_vars or {}
        }
        result = await self.cp_client.create_deployment(payload)
        mantis_log("INFO", "deployment_created", result.get("deployment_id"))
        return result.get("deployment_id")

    async def update(self, deployment_id: str, creds: Optional[Dict[str, str]] = None):
        # Nova revisão
        if not self.pipeline.build(self.config.image_tag, self.config.platform):
            raise RuntimeError("Build da imagem falhou")
        self.pipeline.push(self.config.image_tag, self.config.registry, creds)
        full_image = f"{self.config.registry}/{self.config.image_tag}"
        await self.cp_client.create_revision(deployment_id, full_image, self.config.env_vars)
        mantis_log("INFO", "revision_created", f"Deployment {deployment_id}")
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from deploy_with_control_plane import DockerImagePipeline, DeployConfig, ControlPlaneDeployOrchestrator
from unittest.mock import AsyncMock, patch

def test_build_success():
    pipeline = DockerImagePipeline("/fake")
    with patch('subprocess.run') as mock_run:
        mock_run.return_value = MagicMock(returncode=0)
        assert pipeline.build("test:v1")

def test_deploy_config():
    cfg = DeployConfig("/proj", "img:v1", "registry.io", "my-deploy", "ns")
    assert cfg.platform == "linux/amd64"

@pytest.mark.asyncio
async def test_orchestrator_deploy():
    cfg = DeployConfig("/proj", "img:v1", "reg.io", "agent", "ns")
    client = AsyncMock()
    client.create_deployment.return_value = {"deployment_id": "dep-123"}
    orch = ControlPlaneDeployOrchestrator(cfg, client)
    with patch.object(DockerImagePipeline, 'build', return_value=True), \
         patch.object(DockerImagePipeline, 'push'):
        dep_id = await orch.deploy()
        assert dep_id == "dep-123"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deploy-with-control-plane.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[control-plane-management.md]]
- [[cicd-pipeline-agents.md]]
