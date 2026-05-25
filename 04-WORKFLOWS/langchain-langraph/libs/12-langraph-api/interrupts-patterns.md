---
artifact_id: "interrupts-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/interrupts-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/interrupts-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:interrupts-patterns-v1"
generated_at: "2026-05-27T16:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["graph-api-advanced", "functional-api-advanced", "workflows-ceo", "lgpd-guard-mantis"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks", "workflows-ceo"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Interrupts Patterns — HITL com `interrupt()`, Múltiplos Interrupts e Regras

> **Contrato modular**: Artefato filho do Master Agent. Implementa padrões completos de human-in-the-loop usando `interrupt()`, `Command(resume=...)`, múltiplos interrupts com mapeamento por ID, interrupts em tools, e regras estritas de uso.

## 🎯 Propósito

Fornecer uma biblioteca de padrões HITL robustos para pausar execução, solicitar input humano, validar respostas e retomar fluxos, com suporte a múltiplos interrupts simultâneos e integração com ferramentas.

## 📋 Especificação (SDD)
- **Entradas**: Grafo com checkpointer, config com `thread_id`, pontos de `interrupt`
- **Saídas**: Execução pausada com payload, retomada com `Command(resume=...)`
- **Side Effects**: Salvamento de checkpoint, logging de interrupts
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `langgraph`, `langgraph-checkpoint`

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
# 1. PADRÃO BÁSICO: APROVAÇÃO SIMPLES
# ═══════════════════════════════════════════════════════════════════════════
from typing import Literal, Optional, Any, Dict, List
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class ApprovalState(TypedDict):
    action_details: str
    status: str

class ApprovalPattern:
    """Implementa o padrão de aprovação com interrupt."""
    def __init__(self, checkpointer=None):
        self.checkpointer = checkpointer or InMemorySaver()

    def build(self):
        def approval_node(state: ApprovalState) -> Command[Literal["proceed", "cancel"]]:
            decision = interrupt({
                "question": "Aprovar esta ação?",
                "details": state["action_details"],
            })
            mantis_log("INFO", "approval_decision", str(decision))
            return Command(goto="proceed" if decision else "cancel")

        def proceed_node(state: ApprovalState) -> dict:
            return {"status": "approved"}

        def cancel_node(state: ApprovalState) -> dict:
            return {"status": "rejected"}

        builder = StateGraph(ApprovalState)
        builder.add_node("approval", approval_node)
        builder.add_node("proceed", proceed_node)
        builder.add_node("cancel", cancel_node)
        builder.add_edge(START, "approval")
        builder.add_edge("proceed", END)
        builder.add_edge("cancel", END)
        return builder.compile(checkpointer=self.checkpointer)

# ═══════════════════════════════════════════════════════════════════════════
# 2. PADRÃO AVANÇADO: MÚLTIPLOS INTERRUPTS COM MAPEAMENTO POR ID
# ═══════════════════════════════════════════════════════════════════════════
from operator import add

class MultiInterruptState(TypedDict):
    vals: Annotated[list[str], add]

class MultiInterruptPattern:
    """Gerencia múltiplos interrupts simultâneos com mapeamento por ID."""
    def __init__(self):
        self.checkpointer = InMemorySaver()

    def build(self):
        def node_a(state: MultiInterruptState):
            answer = interrupt("question_a")
            return {"vals": [f"a:{answer}"]}

        def node_b(state: MultiInterruptState):
            answer = interrupt("question_b")
            return {"vals": [f"b:{answer}"]}

        builder = StateGraph(MultiInterruptState)
        builder.add_node("a", node_a)
        builder.add_node("b", node_b)
        builder.add_edge(START, "a")
        builder.add_edge(START, "b")
        builder.add_edge("a", END)
        builder.add_edge("b", END)
        return builder.compile(checkpointer=self.checkpointer)

    @staticmethod
    def create_resume_map(interrupts: tuple) -> dict:
        """Cria um mapa de resume values a partir dos interrupts pendentes."""
        return {i.id: f"response_for_{i.value}" for i in interrupts}

# ═══════════════════════════════════════════════════════════════════════════
# 3. INTERRUPTS EM FERRAMENTAS (TOOLS)
# ═══════════════════════════════════════════════════════════════════════════
from langchain_core.tools import tool

def create_interruptible_tool(tool_name: str, tool_description: str, interrupt_prompt: str):
    """Cria uma ferramenta que pausa para aprovação antes de executar."""
    @tool(tool_name, description=tool_description)
    def interruptible_func(**kwargs) -> str:
        response = interrupt({
            "action": tool_name,
            "args": kwargs,
            "message": interrupt_prompt,
        })
        if isinstance(response, dict) and response.get("action") == "approve":
            mantis_log("INFO", f"tool_{tool_name}_approved", str(kwargs))
            return f"Tool {tool_name} executed with {kwargs}"
        mantis_log("INFO", f"tool_{tool_name}_cancelled")
        return f"Tool {tool_name} cancelled by user"
    return interruptible_func

# ═══════════════════════════════════════════════════════════════════════════
# 4. PADRÃO DE VALIDAÇÃO COM LOOP
# ═══════════════════════════════════════════════════════════════════════════
class ValidationLoopPattern:
    """Implementa validação de input com loop até entrada válida."""
    def __init__(self):
        self.checkpointer = InMemorySaver()

    def build(self):
        class FormState(TypedDict):
            age: Optional[int]

        def get_age_node(state: FormState):
            prompt = "Qual é a sua idade?"
            while True:
                answer = interrupt(prompt)
                if isinstance(answer, int) and answer > 0:
                    mantis_log("INFO", "age_validated", str(answer))
                    return {"age": answer}
                prompt = f"'{answer}' não é uma idade válida. Digite um número positivo."
                mantis_log("WARN", "age_invalid", str(answer))

        builder = StateGraph(FormState)
        builder.add_node("collect_age", get_age_node)
        builder.add_edge(START, "collect_age")
        builder.add_edge("collect_age", END)
        return builder.compile(checkpointer=self.checkpointer)

# ═══════════════════════════════════════════════════════════════════════════
# 5. REGRAS DE USO DE INTERRUPTS (VALIDAÇÃO ESTÁTICA)
# ═══════════════════════════════════════════════════════════════════════════
class InterruptRulesValidator:
    """Valida código de nós para garantir conformidade com regras de interrupts."""

    @staticmethod
    def check_no_bare_try_except(source_code: str) -> List[str]:
        """Verifica se há try/except envolvendo interrupt()."""
        import re
        issues = []
        if "try:" in source_code and "interrupt(" in source_code:
            try_positions = [m.start() for m in re.finditer(r"try\s*:", source_code)]
            interrupt_positions = [m.start() for m in re.finditer(r"interrupt\s*\(", source_code)]
            for ipos in interrupt_positions:
                for tpos in try_positions:
                    if tpos < ipos:
                        except_pos = source_code.find("except", tpos)
                        if except_pos > ipos:
                            issues.append(f"interrupt() no try block (linha ~{source_code[:ipos].count(chr(10))+1})")
        return issues

    @staticmethod
    def check_deterministic_order(node_code: str) -> bool:
        """Verifica se interrupts estão em ordem determinística (sem condicionais)."""
        import re
        interrupt_calls = re.findall(r"interrupt\s*\(([^)]*)\)", node_code)
        if_blocks = re.findall(r"if\s+.*:\s*\n\s*interrupt", node_code)
        for_blocks = re.findall(r"for\s+.*:\s*\n\s*interrupt", node_code)
        if if_blocks or for_blocks:
            mantis_log("WARN", "non_deterministic_interrupts", f"ifs={len(if_blocks)}, fors={len(for_blocks)}")
            return False
        return True

    @staticmethod
    def check_serializable_payload(payload: Any) -> bool:
        """Verifica se o payload do interrupt é JSON-serializável."""
        try:
            json.dumps(payload)
            return True
        except (TypeError, ValueError):
            mantis_log("ERROR", "non_serializable_interrupt_payload", str(type(payload)))
            return False

# ═══════════════════════════════════════════════════════════════════════════
# 6. ORQUESTRADOR DE HITL (EXECUÇÃO COMPLETA)
# ═══════════════════════════════════════════════════════════════════════════
class HITLOrchestrator:
    """Orquestra workflows com HITL, gerenciando interrupts e retomadas."""
    def __init__(self, graph):
        self.graph = graph

    def execute_until_interrupt(self, inputs: dict, thread_id: str) -> dict:
        """Executa o grafo até encontrar um interrupt."""
        config = {"configurable": {"thread_id": thread_id}}
        result = self.graph.invoke(inputs, config=config, version="v2")
        mantis_log("INFO", "hitl_interrupted", f"Thread={thread_id}, Interrupts={len(result.interrupts)}")
        return {
            "value": result.value,
            "interrupts": result.interrupts,
            "thread_id": thread_id,
        }

    def resume(self, thread_id: str, resume_value: Any) -> dict:
        """Retoma a execução após um interrupt."""
        config = {"configurable": {"thread_id": thread_id}}
        result = self.graph.invoke(Command(resume=resume_value), config=config, version="v2")
        mantis_log("INFO", "hitl_resumed", f"Thread={thread_id}")
        return {"value": result.value, "interrupts": result.interrupts}

    def resume_multiple(self, thread_id: str, resume_map: Dict[str, Any]) -> dict:
        """Retoma múltiplos interrupts com mapeamento por ID."""
        config = {"configurable": {"thread_id": thread_id}}
        result = self.graph.invoke(Command(resume=resume_map), config=config, version="v2")
        mantis_log("INFO", "hitl_resumed_multiple", f"Thread={thread_id}, Map={list(resume_map.keys())}")
        return {"value": result.value, "interrupts": result.interrupts}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from interrupts_patterns import (
    ApprovalPattern, MultiInterruptPattern, InterruptRulesValidator,
    HITLOrchestrator, create_interruptible_tool
)

def test_approval_pattern():
    pattern = ApprovalPattern()
    graph = pattern.build()
    result = graph.invoke({"action_details": "Test", "status": "pending"}, {"configurable": {"thread_id": "test-1"}})
    assert "__interrupt__" in result or hasattr(result, 'interrupts')

def test_multi_interrupt_resume_map():
    from langgraph.types import Interrupt
    interrupts = (
        Interrupt(value="q1", id="id1"),
        Interrupt(value="q2", id="id2"),
    )
    resume_map = MultiInterruptPattern.create_resume_map(interrupts)
    assert "id1" in resume_map
    assert "id2" in resume_map

def test_rules_validator_no_bare_try():
    code_with_issue = """
def node(state):
    try:
        interrupt("ask")
    except:
        pass
"""
    issues = InterruptRulesValidator.check_no_bare_try_except(code_with_issue)
    assert len(issues) > 0

def test_rules_validator_deterministic():
    code_good = """
def node(state):
    name = interrupt("name?")
    age = interrupt("age?")
    return {"name": name, "age": age}
"""
    assert InterruptRulesValidator.check_deterministic_order(code_good)

def test_serializable_payload():
    assert InterruptRulesValidator.check_serializable_payload({"key": "value"})
    assert not InterruptRulesValidator.check_serializable_payload(lambda x: x)
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/interrupts-patterns.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[functional-api-advanced.md]]
- [[graph-api-advanced.md]]
- [[lgpd-guard-mantis.md]]
