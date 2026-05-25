---
artifact_id: "langsmith-quick-deploy"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langsmith-quick-deploy.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langsmith-quick-deploy.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:quick-deploy-v1"
generated_at: "2026-05-26T14:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["langgraph-create-agent", "deploy-with-control-plane"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 LangSmith Quick Deploy & Testing

> **Contrato modular**: Artefato filho do Master Agent. Encapsula o fluxo de deploy rápido de um agente LangGraph para o LangSmith Cloud, com testes via Studio, SDK e REST API.

## 🎯 Propósito

Oferecer um pipeline simplificado para colocar um agente em produção no LangSmith em minutos, desde a conexão do repositório GitHub até a invocação da API, incluindo validações de saúde e troubleshooting.

## 📋 Especificação (SDD)
- **Entradas**: Repositório GitHub, `langgraph.json`, API key do LangSmith
- **Saídas**: Deployment ativo, URL da API, logs de teste
- **Side Effects**: Criação de deployment no Control Plane, criação de thread de teste
- **Constraints Aplicáveis**: C1, C2, C3, C5, C8
- **Dependências**: `langgraph-sdk`, `langgraph-cli`, `requests`, `PyYAML`

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
import subprocess, time, requests, yaml, json, sys
from typing import Optional, Dict, Any
from langgraph_sdk import get_client, get_sync_client

# ═══════════════════════════════════════════════════════════════════════════
# 1. VERIFICAÇÃO DE PRÉ-REQUISITOS LOCAIS
# ═══════════════════════════════════════════════════════════════════════════
class LocalPrerequisites:
    @staticmethod
    def check_langgraph_cli():
        try:
            subprocess.run(["langgraph", "--version"], capture_output=True, check=True, text=True)
            mantis_log("INFO", "prereq_langgraph_cli", "OK")
        except:
            raise RuntimeError("langgraph CLI não instalado. Execute: pip install langgraph-cli")

    @staticmethod
    def validate_langgraph_json(path: str = ".") -> dict:
        config_file = f"{path}/langgraph.json"
        if not os.path.exists(config_file):
            raise FileNotFoundError(f"langgraph.json não encontrado em {path}")
        with open(config_file) as f:
            config = json.load(f)
        if "graphs" not in config:
            raise ValueError("langgraph.json deve conter a chave 'graphs'")
        mantis_log("INFO", "langgraph_json_valid", str(list(config["graphs"].keys())))
        return config

    @staticmethod
    def test_local_dev_server(path: str = ".", port: int = 2024):
        proc = subprocess.Popen(["langgraph", "dev", "--port", str(port), "--no-browser"], cwd=path, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(5)
        try:
            r = requests.get(f"http://localhost:{port}/ok")
            if r.status_code == 200:
                mantis_log("INFO", "local_server_ok", f"port {port}")
                return True
        except:
            pass
        return False

# ═══════════════════════════════════════════════════════════════════════════
# 2. DEPLOY VIA UI (SIMULAÇÃO COM API)
# ═══════════════════════════════════════════════════════════════════════════
class CloudDeployer:
    def __init__(self, api_key: str, region: str = "us"):
        self.api_key = api_key
        self.base_url = "https://api.smith.langchain.com" if region == "us" else "https://eu.api.smith.langchain.com"
        self.headers = {"x-api-key": api_key, "Content-Type": "application/json"}

    def connect_github(self, owner: str, repo: str) -> dict:
        # Simula a conexão do repositório (a API real requer OAuth)
        payload = {"owner": owner, "repo": repo}
        r = requests.post(f"{self.base_url}/integrations/github", headers=self.headers, json=payload)
        if r.status_code == 200:
            mantis_log("INFO", "github_connected", f"{owner}/{repo}")
            return r.json()
        raise RuntimeError(f"Falha ao conectar repo: {r.text}")

    def create_deployment(self, name: str, repo_url: str) -> dict:
        payload = {
            "name": name,
            "repo_url": repo_url,
            "type": "Development"
        }
        r = requests.post(f"{self.base_url}/deployments", headers=self.headers, json=payload)
        if r.status_code == 201:
            mantis_log("INFO", "deployment_created", name)
            return r.json()
        raise RuntimeError(f"Falha ao criar deployment: {r.text}")

    def get_deployment_url(self, deployment_id: str) -> str:
        # Assume padrão de URL
        return f"https://{deployment_id}.langgraph.app"

# ═══════════════════════════════════════════════════════════════════════════
# 3. TESTE AUTOMATIZADO DO DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════
class DeploymentTester:
    def __init__(self, deployment_url: str, api_key: str):
        self.client = get_sync_client(url=deployment_url, api_key=api_key)

    def healthcheck(self) -> bool:
        try:
            r = requests.get(f"{self.client.url}/ok")
            return r.status_code == 200
        except:
            return False

    def test_with_sdk(self, assistant_id: str, message: str = "What is LangGraph?") -> str:
        response = self.client.runs.stream(
            None,
            assistant_id,
            input={"messages": [{"role": "human", "content": message}]},
            stream_mode="updates"
        )
        output = ""
        for chunk in response:
            output += str(chunk.data)
            mantis_log("DEBUG", "stream_chunk", str(chunk.event))
        return output

    def test_with_rest(self, assistant_id: str, message: str) -> str:
        payload = {
            "assistant_id": assistant_id,
            "input": {"messages": [{"role": "user", "content": message}]},
            "stream_mode": "values"
        }
        r = requests.post(f"{self.client.url}/runs/stream", json=payload, headers={"x-api-key": self.client.api_key}, stream=True)
        result = ""
        for line in r.iter_lines():
            if line:
                result += line.decode()
        return result

# ═══════════════════════════════════════════════════════════════════════════
# 4. ORQUESTRADOR DO QUICK DEPLOY
# ═══════════════════════════════════════════════════════════════════════════
class QuickDeployOrchestrator:
    def __init__(self, repo_path: str, langsmith_api_key: str):
        self.repo_path = repo_path
        self.api_key = langsmith_api_key

    def run(self, deployment_name: str, github_owner: str, github_repo: str) -> str:
        # Pré-requisitos
        LocalPrerequisites.check_langgraph_cli()
        config = LocalPrerequisites.validate_langgraph_json(self.repo_path)
        assistant_id = list(config["graphs"].keys())[0]  # usa o primeiro

        # Teste local opcional
        if not LocalPrerequisites.test_local_dev_server(self.repo_path):
            mantis_log("WARN", "local_test_skipped", "Servidor local não iniciou, continuando...")

        # Deploy
        deployer = CloudDeployer(self.api_key)
        repo_url = f"https://github.com/{github_owner}/{github_repo}"
        try:
            deployer.connect_github(github_owner, github_repo)
        except:
            mantis_log("WARN", "github_connect_failed", "Pode ser necessário configurar OAuth manualmente")
        deployment = deployer.create_deployment(deployment_name, repo_url)
        deployment_id = deployment["id"]
        url = deployer.get_deployment_url(deployment_id)

        # Aguardar readiness (polling)
        tester = DeploymentTester(url, self.api_key)
        for i in range(30):
            if tester.healthcheck():
                mantis_log("INFO", "deployment_ready", url)
                break
            time.sleep(30)
        else:
            raise TimeoutError("Deployment não ficou pronto a tempo")

        # Teste rápido
        output = tester.test_with_sdk(assistant_id, "Say hello!")
        mantis_log("INFO", "test_output", output[:100])

        print(f"Deployment pronto: {url}")
        print(f"Assistant ID: {assistant_id}")
        return url
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from langsmith_quick_deploy import LocalPrerequisites, CloudDeployer, DeploymentTester

def test_validate_langgraph_json(tmp_path):
    (tmp_path / "langgraph.json").write_text('{"graphs": {"agent": "./agent.py:graph"}}')
    config = LocalPrerequisites.validate_langgraph_json(str(tmp_path))
    assert config["graphs"]["agent"] == "./agent.py:graph"

@patch('requests.get')
def test_healthcheck(mock_get):
    mock_get.return_value.status_code = 200
    tester = DeploymentTester("http://localhost:8123", "fake-key")
    assert tester.healthcheck()

@patch('requests.post')
def test_create_deployment(mock_post):
    mock_post.return_value.status_code = 201
    mock_post.return_value.json = lambda: {"id": "dep-123"}
    deployer = CloudDeployer("fake-key")
    dep = deployer.create_deployment("test", "https://github.com/user/repo")
    assert dep["id"] == "dep-123"
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langsmith-quick-deploy.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-create-agent.md]]
- [[deploy-with-control-plane.md]]
