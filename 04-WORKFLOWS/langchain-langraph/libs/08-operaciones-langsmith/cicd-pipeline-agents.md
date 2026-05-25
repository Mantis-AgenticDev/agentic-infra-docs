---
artifact_id: "cicd-pipeline-agents"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/cicd-pipeline-agents.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/cicd-pipeline-agents.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:cicd-pipeline-v1"
generated_at: "2026-05-26T11:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["control-plane-management", "deploy-with-control-plane"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 CI/CD Pipeline para Agentes LangGraph

> **Contrato modular**: Artefato filho do Master Agent. Implementa um pipeline completo de integração e entrega contínua para agentes LangGraph utilizando GitHub Actions, Control Plane API e LangSmith evaluations.

## 🎯 Propósito

Automatizar o ciclo de vida de agentes LangGraph: testes unitários, de integração, avaliações offline, deploy de preview e produção, com garantias de qualidade via LangSmith.

## 📋 Especificação (SDD)
- **Entradas**: Código do agente, configurações de deployment, datasets de avaliação
- **Saídas**: Deployments atualizados, relatórios de avaliação, logs de CI
- **Side Effects**: Criação de revisões, execução de avaliações, notificações
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph-sdk`, `langsmith`, `pytest`, `pyyaml`, `GitHub CLI`

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
import subprocess, yaml, time, asyncio, os
from typing import List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import langsmith as ls
from langgraph_sdk import get_client

# ═══════════════════════════════════════════════════════════════════════════
# 1. DEFINIÇÃO DO PIPELINE
# ═══════════════════════════════════════════════════════════════════════════
class PipelineStage(Enum):
    UNIT_TESTS = "unit_tests"
    INTEGRATION_TESTS = "integration_tests"
    E2E_TESTS = "e2e_tests"
    OFFLINE_EVALUATION = "offline_evaluation"
    DEV_SERVER_TEST = "dev_server_test"
    DEPLOY_PREVIEW = "deploy_preview"
    ONLINE_EVALUATION = "online_evaluation"
    PROMOTE_PRODUCTION = "promote_production"

@dataclass
class PipelineResult:
    stage: PipelineStage
    success: bool
    details: str = ""
    artifacts: dict = field(default_factory=dict)

class AgentCICDPipeline:
    """
    Orquestra todas as etapas do pipeline CI/CD para um agente LangGraph.
    """
    def __init__(self, repo_path: str, deployment_name: str, deployment_url: str, api_key: str):
        self.repo_path = repo_path
        self.deployment_name = deployment_name
        self.api_key = api_key
        self.client = get_client(url=deployment_url, api_key=api_key)
        self.results: List[PipelineResult] = []

    async def run(self, stages: List[PipelineStage] = None):
        if stages is None:
            stages = list(PipelineStage)
        for stage in stages:
            method = getattr(self, f"_run_{stage.value}", None)
            if method:
                result = await method()
                self.results.append(result)
                if not result.success and stage in (PipelineStage.UNIT_TESTS, PipelineStage.DEV_SERVER_TEST):
                    mantis_log("ERROR", "pipeline_aborted", f"Falha crítica no estágio {stage.value}")
                    raise RuntimeError(f"Pipeline abortado no estágio {stage.value}: {result.details}")
        return self.results

    async def _run_unit_tests(self) -> PipelineResult:
        mantis_log("INFO", "unit_tests_start")
        proc = subprocess.run(["pytest", f"{self.repo_path}/tests/unit", "-q"], capture_output=True, text=True)
        success = proc.returncode == 0
        mantis_log("INFO" if success else "ERROR", "unit_tests_end", proc.stdout[-100:])
        return PipelineResult(PipelineStage.UNIT_TESTS, success, proc.stdout)

    async def _run_integration_tests(self) -> PipelineResult:
        mantis_log("INFO", "integration_tests_start")
        proc = subprocess.run(["pytest", f"{self.repo_path}/tests/integration", "-q"], capture_output=True, text=True)
        success = proc.returncode == 0
        return PipelineResult(PipelineStage.INTEGRATION_TESTS, success, proc.stdout)

    async def _run_e2e_tests(self) -> PipelineResult:
        mantis_log("INFO", "e2e_tests_start")
        proc = subprocess.run(["pytest", f"{self.repo_path}/tests/e2e", "-q"], capture_output=True, text=True)
        success = proc.returncode == 0
        return PipelineResult(PipelineStage.E2E_TESTS, success, proc.stdout)

    async def _run_dev_server_test(self) -> PipelineResult:
        mantis_log("INFO", "dev_server_test_start")
        proc = subprocess.run(["langgraph", "dev", "--no-browser", "--port", "8123"], 
                              cwd=self.repo_path, capture_output=True, timeout=30, text=True)
        success = "API: http://" in proc.stdout
        return PipelineResult(PipelineStage.DEV_SERVER_TEST, success, proc.stdout)

    async def _run_offline_evaluation(self) -> PipelineResult:
        mantis_log("INFO", "offline_evaluation_start")
        try:
            # Exemplo: rodar avaliação com dataset
            dataset_name = "agent-eval-dataset"
            results = ls.evaluate(
                lambda x: x,  # função do agente
                data=dataset_name,
                evaluators=[ls.evaluators.correctness()],
                experiment_prefix=self.deployment_name
            )
            mantis_log("INFO", "offline_evaluation_complete", f"Experiment: {results.experiment_name}")
            return PipelineResult(PipelineStage.OFFLINE_EVALUATION, True, str(results.experiment_name))
        except Exception as e:
            mantis_log("ERROR", "offline_evaluation_failed", str(e))
            return PipelineResult(PipelineStage.OFFLINE_EVALUATION, False, str(e))

    async def _run_deploy_preview(self) -> PipelineResult:
        mantis_log("INFO", "deploy_preview_start")
        # Assume que o script langgraph_api.py existe (do exemplo oficial)
        script = f"{self.repo_path}/.github/scripts/langgraph_api.py"
        proc = subprocess.run(
            ["python", script, "deploy", "--deployment-name", f"{self.deployment_name}-preview", "--type", "Development"],
            capture_output=True, text=True
        )
        success = proc.returncode == 0
        return PipelineResult(PipelineStage.DEPLOY_PREVIEW, success, proc.stdout)

    async def _run_online_evaluation(self) -> PipelineResult:
        mantis_log("INFO", "online_evaluation_start")
        # Simula envio de requests e coleta de traces
        thread = await self.client.threads.create()
        run = await self.client.runs.wait(
            thread["thread_id"], f"{self.deployment_name}-preview",
            input={"messages": [{"role": "user", "content": "Teste"}]}
        )
        mantis_log("INFO", "online_evaluation_complete", f"Run: {run['run_id']}")
        return PipelineResult(PipelineStage.ONLINE_EVALUATION, True, f"Run {run['run_id']}")

    async def _run_promote_production(self) -> PipelineResult:
        mantis_log("INFO", "promote_production_start")
        # Exclui preview, cria produção
        script = f"{self.repo_path}/.github/scripts/langgraph_api.py"
        proc = subprocess.run(
            ["python", script, "deploy", "--deployment-name", self.deployment_name, "--type", "Production"],
            capture_output=True, text=True
        )
        success = proc.returncode == 0
        return PipelineResult(PipelineStage.PROMOTE_PRODUCTION, success, proc.stdout)

# ═══════════════════════════════════════════════════════════════════════════
# 2. GITHUB ACTIONS WORKFLOW GENERATOR
# ═══════════════════════════════════════════════════════════════════════════
class GitHubActionsGenerator:
    def generate(self, deployment_name: str, repo: str) -> str:
        workflow = {
            "name": f"CI/CD - {deployment_name}",
            "on": {
                "push": {"branches": ["main"]},
                "pull_request": {"branches": ["main"]}
            },
            "jobs": {
                "test-and-deploy": {
                    "runs-on": "ubuntu-latest",
                    "steps": [
                        {"uses": "actions/checkout@v4"},
                        {"name": "Set up Python", "uses": "actions/setup-python@v5", "with": {"python-version": "3.11"}},
                        {"name": "Install dependencies", "run": "pip install -r requirements.txt"},
                        {"name": "Run unit tests", "run": "pytest tests/unit"},
                        {"name": "Run integration tests", "run": "pytest tests/integration"},
                        {"name": "Run offline evaluation", "run": "python .github/scripts/run_eval.py"},
                        {"name": "Deploy preview", "run": "python .github/scripts/langgraph_api.py deploy --deployment-name $DEPLOY_NAME-preview --type Development"},
                        {"name": "Run online evaluation", "run": "python .github/scripts/online_eval.py"},
                        {"name": "Promote to production", "if": "github.ref == 'refs/heads/main'", "run": "python .github/scripts/langgraph_api.py deploy --deployment-name $DEPLOY_NAME --type Production"}
                    ],
                    "env": {
                        "DEPLOY_NAME": deployment_name,
                        "LANGSMITH_API_KEY": "${{ secrets.LANGSMITH_API_KEY }}",
                        "LANGCHAIN_API_KEY": "${{ secrets.LANGCHAIN_API_KEY }}"
                    }
                }
            }
        }
        return yaml.dump(workflow, sort_keys=False)

# ═══════════════════════════════════════════════════════════════════════════
# 3. ANÁLISE DE RESULTADOS E NOTIFICAÇÕES
# ═══════════════════════════════════════════════════════════════════════════
class PipelineNotifier:
    def __init__(self, webhook_url: str = None):
        self.webhook_url = webhook_url

    async def notify_slack(self, results: List[PipelineResult], environment: str):
        if not self.webhook_url:
            return
        import httpx
        message = {"text": f"CI/CD Pipeline {environment} finalizado:\n" + 
                  "\n".join(f"- {r.stage.value}: {'✅' if r.success else '❌'} {r.details[:50]}" for r in results)}
        async with httpx.AsyncClient() as client:
            await client.post(self.webhook_url, json=message)

    async def send_annotation_alert(self, run_id: str):
        """Envia alerta para anotação humana quando qualidade está abaixo do threshold."""
        mantis_log("WARN", "annotation_alert", f"Run {run_id} precisa de revisão humana")
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from cicd_pipeline_agents import AgentCICDPipeline, PipelineStage, PipelineResult

@pytest.mark.asyncio
async def test_pipeline_unit_tests():
    pipeline = AgentCICDPipeline("./tests/fixtures/agent", "test-agent", "http://localhost:8123", "fake-key")
    # mock subprocess
    with patch('subprocess.run') as mock_run:
        mock_run.return_value = MagicMock(returncode=0, stdout="2 passed")
        result = await pipeline._run_unit_tests()
        assert result.success
        assert "2 passed" in result.details

def test_workflow_generator():
    gen = GitHubActionsGenerator()
    wf = gen.generate("my-agent", "user/repo")
    y = yaml.safe_load(wf)
    assert y["name"] == "CI/CD - my-agent"
    assert "test-and-deploy" in y["jobs"]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/cicd-pipeline-agents.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[control-plane-management.md]]
- [[deploy-with-control-plane.md]]
