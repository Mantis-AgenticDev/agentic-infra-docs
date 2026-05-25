---
artifact_id: "rag-evaluation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-evaluation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-evaluation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-evaluation-v1.0.0"
generated_at: "2026-05-25T00:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["rag-production", "agents-swarm-testing"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📏 RAG Evaluation – Métricas RAGAS e Validação Contínua

> **Contrato modular**: Define o framework de avaliação para sistemas RAG usando RAGAS (Faithfulness, Answer Relevancy, Context Precision/Recall) e integração com LangSmith para datasets de teste.

---

## 🎯 Propósito
Garantir que os pipelines RAG dos agentes MANTIS atinjam níveis de qualidade mensuráveis, detectando degradação e orientando melhorias contínuas.

## 📋 Especificação (SDD)
- **Entradas**: Perguntas de teste, respostas geradas, contextos recuperados.
- **Saídas**: Métricas de qualidade (faithfulness, relevância, precisão de contexto).
- **Side Effects**: Logs das métricas no LangSmith (se ativo).
- **Constraints**: C1 (contrato de métrica), C5 (formato de resultado), C8 (rastreio).
- **Dependências**: `ragas`, `langsmith`, `datasets`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Instalação e Configuração
```bash
pip install ragas langsmith datasets
```

### 2. Métricas RAGAS Essenciais
```python
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
from datasets import Dataset

# Dados de exemplo
data = {
    "question": ["O que é RAG?"],
    "answer": ["RAG significa Retrieval-Augmented Generation..."],
    "contexts": [["RAG combina recuperação de documentos com geração de texto."]],
    "ground_truth": ["RAG é uma técnica que aumenta a geração de texto com recuperação de informação."]
}
dataset = Dataset.from_dict(data)

result = evaluate(
    dataset,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall]
)
mantis_log("INFO", "ragas_eval", str(result))
print(result)
```

### 3. Interpretação das Métricas
| Métrica | Significado | Alvo MANTIS |
|---------|-------------|-------------|
| **Faithfulness** | A resposta é fiel ao contexto (sem alucinações) | > 0.90 |
| **Answer Relevancy** | A resposta é relevante para a pergunta | > 0.85 |
| **Context Precision** | Os documentos recuperados são precisos | > 0.80 |
| **Context Recall** | Todos os documentos relevantes foram recuperados | > 0.85 |

### 4. Integração com LangSmith para Avaliação Contínua
```python
from langsmith import Client
client = Client()

# Criar dataset
dataset = client.create_dataset("rag-qa-pairs")
client.create_examples(
    inputs=[{"question": "Como criar um agente?"}],
    outputs=[{"answer": "Use create_agent() com ferramentas."}],
    dataset_id=dataset.id
)

# Definir função de avaliação
def evaluate_rag(question: str, answer: str, context: list):
    metrics = evaluate(
        Dataset.from_dict({"question": [question], "answer": [answer], "contexts": [context]}),
        metrics=[faithfulness, answer_relevancy]
    )
    return metrics

# Executar avaliação com LangSmith
from langsmith.evaluation import run_evaluator
run_evaluator(client, dataset_name="rag-qa-pairs", llm_or_chain_factory=lambda: rag_chain)
```

### 5. Teste de Regressão Automatizado
```python
def regression_test():
    test_cases = [
        ("O que é LangChain?", "LangChain é um framework para LLM apps."),
        ("Como funciona RAG?", "RAG recupera documentos e gera respostas baseadas neles."),
    ]
    for question, expected_keywords in test_cases:
        answer = rag_chain.invoke(question)
        assert expected_keywords.lower() in answer.lower(), f"Falha na regressão para '{question}'"
        mantis_log("INFO", "regression_ok", question)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_faithfulness_metric():
    from ragas.metrics import faithfulness
    assert faithfulness is not None
    # Simples verificação de existência do módulo
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-evaluation.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-advanced-patterns.md]]
- [[observability-langsmith.md]]
