---
artifact_id: "deep-agents-profiles"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-profiles.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-profiles.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-profiles-v1.0.0"
generated_at: "2026-05-25T16:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🎭 Deep Agents – Perfis (HarnessProfile e ProviderProfile)

> **Contrato modular**: Artefato filho do Master Agent. Explica como criar e registrar perfis que ajustam automaticamente o comportamento dos agentes por provedor/modelo.

---

## 🎯 Propósito
Empacotar configurações reutilizáveis (prompts, exclusão de ferramentas, middleware extra) que são aplicadas automaticamente quando um modelo é selecionado.

## 📋 Especificação (SDD)
- **Entradas**: Definições de `HarnessProfile` e `ProviderProfile`.
- **Saídas**: Perfis registrados e aplicados na criação de agentes.
- **Side Effects**: Modificação do comportamento do agente.
- **Constraints Aplicáveis**: C1 (merge determinístico), C2 (versionamento de perfil), C5 (schema YAML/JSON), C7 (fallback se perfil não encontrado), C8 (logs de aplicação).
- **Dependências**: `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Registrar um HarnessProfile

```python
from deepagents import HarnessProfile, register_harness_profile, GeneralPurposeSubagentProfile

register_harness_profile(
    "openai:gpt-5.4",
    HarnessProfile(
        system_prompt_suffix="Responda em menos de 100 palavras.",
        excluded_tools={"execute"},
        excluded_middleware={"SummarizationMiddleware"},
        general_purpose_subagent=GeneralPurposeSubagentProfile(enabled=False),
    ),
)
```

### 2. Registrar um ProviderProfile

```python
from deepagents import ProviderProfile, register_provider_profile

register_provider_profile(
    "openai",
    ProviderProfile(init_kwargs={"temperature": 0}),
)
```

### 3. Carregar de Arquivo YAML

```yaml
# openai.yaml
base_system_prompt: You are helpful.
system_prompt_suffix: Respond briefly.
excluded_tools:
  - execute
  - grep
excluded_middleware:
  - SummarizationMiddleware
general_purpose_subagent:
  enabled: false
```

```python
import yaml
from deepagents import HarnessProfileConfig, register_harness_profile

with open("openai.yaml") as f:
    register_harness_profile("openai", HarnessProfileConfig.from_dict(yaml.safe_load(f)))
```

### 4. Plugin via entry point

```toml
[project.entry-points."deepagents.harness_profiles"]
my_provider = "my_pkg.profiles:register_harness"
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_harness_profile():
    profile = HarnessProfile(system_prompt_suffix="Be concise.")
    assert profile.system_prompt_suffix == "Be concise."
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-profiles.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
