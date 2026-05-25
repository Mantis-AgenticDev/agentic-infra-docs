
---
artifact_id: "deep-agents-filesystem-tools"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-filesystem-tools.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-filesystem-tools.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-filesystem-tools-v1.0.0"
generated_at: "2026-05-25T23:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-overview"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗂️ Deep Agents – Ferramentas de Arquivos em Profundidade

> **Contrato modular**: Artefato filho do Master Agent. Detalha cada ferramenta de arquivo disponível em Deep Agents (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`, `execute`), com exemplos de uso, padrões de escrita segura e integração com backends.

---

## 🎯 Propósito
Permitir que agentes MANTIS manipulem arquivos de forma eficiente e segura, entendendo cada ferramenta e suas capacidades.

## 📋 Especificação (SDD)
- **Entradas**: Backend configurado, paths e conteúdo.
- **Saídas**: Operações de arquivo executadas.
- **Side Effects**: Leitura/escrita no backend.
- **Constraints Aplicáveis**: C1 (paths e contratos), C3 (segurança), C5 (formato), C7 (tratamento de erros), C8 (logs).
- **Dependências**: `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. `ls` – Listar Diretório

```python
# Lista arquivos e diretórios em um path.
# Retorna lista de FileInfo com path, is_dir, size, modified_at.
result = agent.invoke({"messages": [{"role": "user", "content": "Liste os arquivos em /workspace/"}]})
# Agente chama ls(path="/workspace/")
```

### 2. `read_file` – Ler Arquivo

```python
# Lê conteúdo de um arquivo com offset e limite.
# Suporta imagens (retorna como conteúdo multimodal).
# read_file(path, offset=0, limit=2000)
```

### 3. `write_file` – Criar Arquivo

```python
# Cria um novo arquivo. Falha se o arquivo já existir.
# write_file(path, content)
# Exemplo de prompt: "Crie um arquivo /workspace/notes.md com o conteúdo '## Notas'"
```

### 4. `edit_file` – Editar Arquivo Existente

```python
# Edita um arquivo substituindo old_string por new_string.
# Se replace_all=True, substitui todas as ocorrências.
# edit_file(path, old_string, new_string, replace_all=False)
# Exemplo: "Substitua 'foo' por 'bar' em /workspace/config.yaml"
```

### 5. `glob` – Buscar por Padrão

```python
# Busca arquivos por padrão glob.
# glob(pattern, path="/")
# Exemplo: "Encontre todos os arquivos .py em /workspace/"
# glob("*.py", "/workspace/")
```

### 6. `grep` – Buscar Conteúdo

```python
# Busca por padrão textual dentro de arquivos.
# grep(pattern, path=None, glob=None)
# Exemplo: "Busque 'TODO' em todos os arquivos .py"
# grep("TODO", glob="*.py")
```

### 7. `execute` – Executar Comando (Sandboxes/Shell)

```python
# Executa comando shell. Disponível apenas em sandboxes e LocalShellBackend.
# execute(command)
```

### 8. Padrão de Escrita Segura

```python
# 1. Escrever rascunho
# write_file("/workspace/draft.md", content)
# 2. Revisar com subagente
# task(agent="reviewer", instruction="Revise /workspace/draft.md")
# 3. Aplicar correções
# edit_file("/workspace/draft.md", old, new)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_fileinfo_structure():
    info = FileInfo(path="/test.txt", is_dir=False, size=100)
    assert info.path == "/test.txt"
    assert info.is_dir == False
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-filesystem-tools.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-backends-overview.md]]
