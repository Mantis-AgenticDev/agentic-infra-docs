---
artifact_id: "swarm-researcher-template"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-researcher-template.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-researcher-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:researcher-template-v1"
generated_at: "2026-05-27T09:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-supervisor-patterns", "workflows-ceo"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Swarm Researcher Template — Sistema de Pesquisa e Implementação com Dois Agentes

> **Contrato modular**: Artefato filho do Master Agent. Implementa um template completo de enxame de pesquisa, com agente planejador e agente pesquisador, que colaboram para analisar documentação e gerar soluções.

## 🎯 Propósito

Fornecer um sistema multi-agente reutilizável para tarefas de pesquisa e implementação, onde um planejador lê documentação, refina o escopo, e um pesquisador implementa a solução baseada nas fontes selecionadas.

## 📋 Especificação (SDD)
- **Entradas**: Solicitação do usuário, URL do `llms.txt`, número de URLs a selecionar
- **Saídas**: Solução implementada (código, texto), lista de fontes utilizadas
- **Side Effects**: Fetch de documentação externa, logs de planejamento e execução
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8, C9
- **Dependências**: `langgraph-swarm`, `langchain`, `httpx`, `markdownify`

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
# 1. FERRAMENTAS DE PESQUISA
# ═══════════════════════════════════════════════════════════════════════════
import httpx
from markdownify import markdownify

class DocumentFetcher:
    """Cliente HTTP resiliente para buscar documentação externa."""
    def __init__(self, timeout: int = 15, max_retries: int = 2):
        self.client = httpx.Client(follow_redirects=True, timeout=timeout)
        self.max_retries = max_retries

    def fetch(self, url: str) -> str:
        for attempt in range(self.max_retries + 1):
            try:
                response = self.client.get(url)
                response.raise_for_status()
                content = markdownify(response.text)
                mantis_log("INFO", "doc_fetched", f"URL={url}, Size={len(content)}")
                return content
            except Exception as e:
                if attempt == self.max_retries:
                    mantis_log("ERROR", "doc_fetch_failed", f"URL={url}, Error={str(e)}")
                    return f"Erro ao buscar {url}: {str(e)}"
                time.sleep(1)
        return ""

fetcher = DocumentFetcher()

def fetch_doc(url: str) -> str:
    """Busca um documento e retorna o conteúdo em markdown."""
    return fetcher.fetch(url)

# ═══════════════════════════════════════════════════════════════════════════
# 2. DEFINIÇÃO DOS PROMPTS
# ═══════════════════════════════════════════════════════════════════════════
PLANNER_PROMPT = """
<Task>
Você ajudará a planejar os passos para implementar uma aplicação LangGraph baseada na solicitação do usuário.
</Task>

<Instructions>
1. Reflita sobre a solicitação do usuário e o escopo do projeto.
2. Use a ferramenta fetch_doc para ler o arquivo llms.txt, que dá acesso à documentação do LangGraph: {llms_txt}
3. Após ler o arquivo llms.txt, faça perguntas esclarecedoras ao usuário para refinar o escopo.
4. Quando tiver um escopo claro, selecione as {num_urls} URLs mais relevantes do llms.txt para implementar o projeto.
5. Produza um resumo com duas seções markdown:
   - ## Scope: descrição do escopo com até 5 bullet points
   - ## URLs: lista das {num_urls} URLs relevantes
6. Finalmente, transfira para o agente pesquisador usando a ferramenta transfer_to_researcher_agent.
</Instructions>
"""

RESEARCHER_PROMPT = """
<Task>
Você implementará a solução para a solicitação do usuário.
</Task>

<Instructions>
1. Primeiro, reflita sobre o escopo fornecido pelo agente planejador.
2. Use a ferramenta fetch_doc para buscar e ler cada URL na lista fornecida.
3. Reflita sobre as informações nas URLs.
4. Pense cuidadosamente.
5. Implemente a solução usando as informações das URLs.
6. Se precisar de mais esclarecimentos ou fontes adicionais, transfira para transfer_to_planner_agent.
</Instructions>

<Checklist>
Verifique se sua solução atende a todos os pontos do escopo.
</Checklist>
"""

# ═══════════════════════════════════════════════════════════════════════════
# 3. CONSTRUÇÃO DO ENXAME DE PESQUISA
# ═══════════════════════════════════════════════════════════════════════════
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent
from langgraph_swarm import create_handoff_tool, create_swarm
from langgraph.checkpoint.memory import InMemorySaver

class ResearcherSwarm:
    """Fábrica do enxame de pesquisa com planejador e pesquisador."""
    def __init__(
        self,
        model_provider: str = "deepseek",
        llms_txt_url: str = "https://langchain-ai.github.io/langgraph/llms.txt",
        num_urls: int = 3,
    ):
        self.model = init_chat_model(
            model="deepseek-chat" if model_provider == "deepseek" else "gpt-4o",
            model_provider=model_provider,
            temperature=0.05,
        )
        self.llms_txt_url = llms_txt_url
        self.num_urls = num_urls

    def build(self):
        # Handoff tools
        transfer_to_researcher = create_handoff_tool(
            agent_name="researcher_agent",
            description="Transferir para o agente pesquisador para implementar a solução.",
        )
        transfer_to_planner = create_handoff_tool(
            agent_name="planner_agent",
            description="Transferir para o agente planejador para esclarecer dúvidas.",
        )

        planner_prompt = PLANNER_PROMPT.format(
            llms_txt=self.llms_txt_url, num_urls=self.num_urls
        )

        planner = create_agent(
            self.model,
            system_prompt=planner_prompt,
            tools=[fetch_doc, transfer_to_researcher],
            name="planner_agent",
        )

        researcher = create_agent(
            self.model,
            system_prompt=RESEARCHER_PROMPT,
            tools=[fetch_doc, transfer_to_planner],
            name="researcher_agent",
        )

        checkpointer = InMemorySaver()
        workflow = create_swarm(
            [planner, researcher],
            default_active_agent="planner_agent",
        )
        app = workflow.compile(checkpointer=checkpointer)
        mantis_log("INFO", "researcher_swarm_built")
        return app

# ═══════════════════════════════════════════════════════════════════════════
# 4. EXECUTOR COM STREAMING
# ═══════════════════════════════════════════════════════════════════════════
class ResearcherRunner:
    def __init__(self, app):
        self.app = app

    def run(self, request: str, thread_id: str = "1"):
        config = {"configurable": {"thread_id": thread_id}}
        mantis_log("INFO", "researcher_run_start", request[:80])
        result = self.app.invoke(
            {"messages": [{"role": "user", "content": request}]},
            config,
        )
        mantis_log("INFO", "researcher_run_done", f"Messages={len(result['messages'])}")
        return result

    def stream(self, request: str, thread_id: str = "1"):
        config = {"configurable": {"thread_id": thread_id}}
        for chunk in self.app.stream(
            {"messages": [{"role": "user", "content": request}]},
            config,
            stream_mode="values",
            subgraphs=True,
        ):
            yield chunk

# ═══════════════════════════════════════════════════════════════════════════
# 5. CONFIGURAÇÃO DE DEPLOY (LANGGRAPH.JSON)
# ═══════════════════════════════════════════════════════════════════════════
DEPLOY_CONFIG = """
{
  "dependencies": ["."],
  "graphs": {
    "researcher_swarm": "./swarm_researcher.py:build"
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from swarm_researcher_template import ResearcherSwarm, ResearcherRunner, fetch_doc

def test_fetch_doc():
    # Test with a known URL; might fail if no network, so mock
    from unittest.mock import patch
    with patch('httpx.Client.get') as mock_get:
        mock_get.return_value.status_code = 200
        mock_get.return_value.text = "# Test Doc"
        result = fetch_doc("https://example.com")
        assert "Test Doc" in result

def test_researcher_swarm_build():
    swarm = ResearcherSwarm(model_provider="deepseek")
    app = swarm.build()
    assert app is not None

def test_runner_stream():
    swarm = ResearcherSwarm(model_provider="deepseek")
    app = swarm.build()
    runner = ResearcherRunner(app)
    # We can't easily test full stream without LLM, but check it's callable
    chunks = list(runner.stream("Test request"))
    assert len(chunks) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/swarm-researcher-template.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[swarm-supervisor-patterns.md]]
