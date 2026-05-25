---
artifact_id: "control-plane-management"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/control-plane-management.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/control-plane-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:control-plane-v1"
generated_at: "2026-05-26T11:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-with-control-plane", "cicd-pipeline-agents"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Control Plane Management

> **Contrato modular**: Artefato filho do Master Agent. Implementa interações com a API do Control Plane do LangSmith para gerenciar deployments, revisões, integrações e listeners.

## 🎯 Propósito

Fornecer um cliente robusto para a API do Control Plane, permitindo criar, atualizar, listar e deletar deployments e revisões, gerenciar integrações de Git e configurar listeners para ambientes híbridos e self-hosted.

## 📋 Especificação (SDD)
- **Entradas**: `deployment_id`, `repo_url`, `image_url`, `namespace`, variáveis de ambiente
- **Saídas**: Status de deployment, detalhes de revisões, métricas
- **Side Effects**: Criação/atualização de recursos no Control Plane, trigger de builds assíncronos
- **Constraints Aplicáveis**: C1 (Resiliência), C2 (Validação), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade)
- **Dependências**: `httpx`, `pydantic`, `PyYAML`, `tenacity`

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

# ─── IMPORTAÇÕES ─────────────────────────────────────────────────────────
import asyncio
from typing import Optional, Dict, Any, List, Union
from pydantic import BaseModel, Field, validator
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

# ═══════════════════════════════════════════════════════════════════════════
# 1. MODELOS DE DADOS DO CONTROL PLANE
# ═══════════════════════════════════════════════════════════════════════════
class DeploymentConfig(BaseModel):
    name: str
    repo_url: Optional[str] = None          # para Cloud
    image_url: Optional[str] = None         # para Hybrid/Self-Hosted
    namespace: Optional[str] = None
    env_vars: Dict[str, str] = Field(default_factory=dict)
    deployment_type: str = "Development"    # ou "Production"
    listener_id: Optional[str] = None       # para Hybrid/Self-Hosted

    @validator("deployment_type")
    def valid_type(cls, v):
        if v not in ("Development", "Production"):
            raise ValueError("Deployment type must be Development or Production")
        return v

class RevisionConfig(BaseModel):
    deployment_id: str
    image_url: Optional[str] = None
    env_vars: Optional[Dict[str, str]] = None

class DeploymentStatus(BaseModel):
    deployment_id: str
    name: str
    status: str  # pending, deploying, ready, error, deleting, deleted
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    metrics: Optional[Dict[str, Any]] = None

class IntegrationConfig(BaseModel):
    provider: str = "github"
    name: str
    access_token: str

# ═══════════════════════════════════════════════════════════════════════════
# 2. CLIENTE ASSÍNCRONO DA API DO CONTROL PLANE
# ═══════════════════════════════════════════════════════════════════════════
class ControlPlaneClient:
    """
    Cliente para a API do Control Plane do LangSmith.
    Gerencia deployments, revisões, integrações e listeners.
    """
    def __init__(self, base_url: str, api_key: str):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self._client = httpx.AsyncClient(
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            },
            timeout=30.0
        )

    async def close(self):
        await self._client.aclose()

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    async def _request(self, method: str, path: str, json_data: dict = None, params: dict = None) -> dict:
        url = f"{self.base_url}/api/v1{path}"
        mantis_log("DEBUG", "control_plane_request", f"{method} {path}")
        try:
            response = await self._client.request(method, url, json=json_data, params=params)
            response.raise_for_status()
            return response.json() if response.text else {}
        except httpx.HTTPStatusError as e:
            mantis_log("ERROR", "control_plane_error", f"{method} {path}: {e.response.status_code} {e.response.text}")
            raise

    # ═══════════════════════════════════════════════════════════════════════
    # DEPLOYMENTS
    # ═══════════════════════════════════════════════════════════════════════
    async def list_deployments(self) -> List[DeploymentStatus]:
        data = await self._request("GET", "/deployments")
        return [DeploymentStatus(**d) for d in data.get("deployments", [])]

    async def get_deployment(self, deployment_id: str) -> DeploymentStatus:
        data = await self._request("GET", f"/deployments/{deployment_id}")
        return DeploymentStatus(**data)

    async def create_deployment(self, config: DeploymentConfig) -> DeploymentStatus:
        payload = config.dict(exclude_none=True)
        mantis_log("INFO", "create_deployment", f"Name: {config.name}")
        result = await self._request("POST", "/deployments", json_data=payload)
        return DeploymentStatus(**result)

    async def delete_deployment(self, deployment_id: str) -> dict:
        mantis_log("INFO", "delete_deployment", f"ID: {deployment_id}")
        return await self._request("DELETE", f"/deployments/{deployment_id}")

    async def update_deployment(self, deployment_id: str, updates: dict) -> DeploymentStatus:
        mantis_log("INFO", "update_deployment", f"ID: {deployment_id}")
        result = await self._request("PATCH", f"/deployments/{deployment_id}", json_data=updates)
        return DeploymentStatus(**result)

    # ═══════════════════════════════════════════════════════════════════════
    # REVISIONS
    # ═══════════════════════════════════════════════════════════════════════
    async def list_revisions(self, deployment_id: str) -> List[dict]:
        data = await self._request("GET", f"/deployments/{deployment_id}/revisions")
        return data.get("revisions", [])

    async def create_revision(self, config: RevisionConfig) -> dict:
        payload = config.dict(exclude_none=True)
        mantis_log("INFO", "create_revision", f"Deployment: {config.deployment_id}")
        return await self._request("POST", f"/deployments/{config.deployment_id}/revisions", json_data=payload)

    # ═══════════════════════════════════════════════════════════════════════
    # INTEGRATIONS (Git repos)
    # ═══════════════════════════════════════════════════════════════════════
    async def list_integrations(self) -> List[dict]:
        data = await self._request("GET", "/integrations")
        return data.get("integrations", [])

    async def create_integration(self, config: IntegrationConfig) -> dict:
        payload = config.dict()
        mantis_log("INFO", "create_integration", f"Provider: {config.provider}")
        return await self._request("POST", "/integrations", json_data=payload)

    async def delete_integration(self, integration_id: str) -> dict:
        mantis_log("INFO", "delete_integration", f"ID: {integration_id}")
        return await self._request("DELETE", f"/integrations/{integration_id}")

    # ═══════════════════════════════════════════════════════════════════════
    # LISTENERS (Hybrid/Self-Hosted)
    # ═══════════════════════════════════════════════════════════════════════
    async def list_listeners(self) -> List[dict]:
        data = await self._request("GET", "/listeners")
        return data.get("listeners", [])

    async def register_listener(self, namespace: str, version: str) -> dict:
        payload = {"namespace": namespace, "version": version}
        return await self._request("POST", "/listeners", json_data=payload)

# ═══════════════════════════════════════════════════════════════════════════
# 3. ORQUESTRADOR DE DEPLOYMENTS (FLUXOS DE ALTO NÍVEL)
# ═══════════════════════════════════════════════════════════════════════════
class DeploymentOrchestrator:
    """
    Orquestra fluxos completos: deploy, rollback, promoção de ambiente.
    """
    def __init__(self, client: ControlPlaneClient):
        self.client = client

    async def deploy_from_github(self, name: str, repo_url: str, env_vars: dict = None, prod: bool = False) -> DeploymentStatus:
        config = DeploymentConfig(
            name=name,
            repo_url=repo_url,
            deployment_type="Production" if prod else "Development",
            env_vars=env_vars or {}
        )
        return await self.client.create_deployment(config)

    async def deploy_from_image(self, name: str, image_url: str, namespace: str, listener_id: str, env_vars: dict = None, prod: bool = False) -> DeploymentStatus:
        config = DeploymentConfig(
            name=name,
            image_url=image_url,
            namespace=namespace,
            listener_id=listener_id,
            deployment_type="Production" if prod else "Development",
            env_vars=env_vars or {}
        )
        return await self.client.create_deployment(config)

    async def promote_to_production(self, deployment_id: str) -> DeploymentStatus:
        mantis_log("INFO", "promote_to_production", f"Deployment: {deployment_id}")
        return await self.client.update_deployment(deployment_id, {"deployment_type": "Production"})

    async def rollback(self, deployment_id: str, target_revision: str) -> dict:
        mantis_log("INFO", "rollback", f"Deployment: {deployment_id} -> Revision: {target_revision}")
        config = RevisionConfig(deployment_id=deployment_id, image_url=target_revision)
        return await self.client.create_revision(config)

    async def wait_for_ready(self, deployment_id: str, timeout: int = 600) -> DeploymentStatus:
        start = asyncio.get_event_loop().time()
        while True:
            status = await self.client.get_deployment(deployment_id)
            if status.status == "ready":
                mantis_log("INFO", "deployment_ready", deployment_id)
                return status
            if status.status in ("error", "deleted"):
                raise RuntimeError(f"Deployment {deployment_id} em estado {status.status}")
            if asyncio.get_event_loop().time() - start > timeout:
                raise TimeoutError(f"Deployment {deployment_id} não ficou pronto em {timeout}s")
            await asyncio.sleep(10)

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE AMBIENTE (SIMULAÇÃO LOCAL)
# ═══════════════════════════════════════════════════════════════════════════
class LocalDeploymentSimulator:
    """Simula criação de deployment local para testes."""
    def __init__(self):
        self.deployments = {}

    async def create(self, config: DeploymentConfig) -> DeploymentStatus:
        import uuid
        dep_id = str(uuid.uuid4())
        self.deployments[dep_id] = {
            "config": config,
            "status": "ready",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        return DeploymentStatus(deployment_id=dep_id, name=config.name, status="ready")

    async def get(self, dep_id: str) -> DeploymentStatus:
        d = self.deployments.get(dep_id)
        if not d:
            raise ValueError("Deployment not found")
        return DeploymentStatus(deployment_id=dep_id, name=d["config"].name, status=d["status"])
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from control_plane_management import ControlPlaneClient, DeploymentOrchestrator, DeploymentConfig, LocalDeploymentSimulator

@pytest.mark.asyncio
async def test_create_deployment_simulator():
    sim = LocalDeploymentSimulator()
    config = DeploymentConfig(name="test-deploy", repo_url="https://github.com/test/repo")
    status = await sim.create(config)
    assert status.status == "ready"
    assert status.name == "test-deploy"

@pytest.mark.asyncio
async def test_orchestrator_deploy_from_github():
    # usar mock do client
    client = AsyncMock(spec=ControlPlaneClient)
    client.create_deployment.return_value = DeploymentStatus(deployment_id="d1", name="prod-agent", status="ready")
    orch = DeploymentOrchestrator(client)
    result = await orch.deploy_from_github("prod-agent", "https://github.com/user/repo")
    assert result.deployment_id == "d1"
    client.create_deployment.assert_called_once()

@pytest.mark.asyncio
async def test_wait_for_ready_timeout():
    client = AsyncMock(spec=ControlPlaneClient)
    client.get_deployment.return_value = DeploymentStatus(deployment_id="d1", name="test", status="pending")
    orch = DeploymentOrchestrator(client)
    with pytest.raises(TimeoutError):
        await orch.wait_for_ready("d1", timeout=1)
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/control-plane-management.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[deploy-with-control-plane.md]]
- [[cicd-pipeline-agents.md]]
