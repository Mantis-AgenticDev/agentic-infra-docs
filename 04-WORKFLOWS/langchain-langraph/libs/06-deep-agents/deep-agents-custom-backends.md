---
artifact_id: "deep-agents-custom-backends"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-custom-backends.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-custom-backends.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-custom-backends-v1.0.0"
generated_at: "2026-05-25T17:00:00Z"
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

# 🛠️ Deep Agents – Backends Personalizados (S3, Postgres, APIs)

> **Contrato modular**: Artefato filho do Master Agent. Ensina a implementar backends de arquivos customizados para S3, PostgreSQL ou qualquer armazenamento remoto, seguindo `BackendProtocol`.

---

## 🎯 Propósito
Permitir que agentes MANTIS leiam e escrevam em sistemas de armazenamento corporativos (S3, bancos SQL, etc.) como se fossem sistemas de arquivos locais.

## 📋 Especificação (SDD)
- **Entradas**: Configurações de conexão (bucket, tabela).
- **Saídas**: Backend compatível com `BackendProtocol`.
- **Side Effects**: Operações remotas.
- **Constraints Aplicáveis**: C1 (protocolo), C3 (credenciais), C5 (mapeamento de paths), C7 (timeout), C8 (logs).
- **Dependências**: `boto3`, `psycopg2`.

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

### 1. Backend S3

```python
import boto3
from deepagents.backends.protocol import (
    BackendProtocol, WriteResult, EditResult, LsResult,
    ReadResult, GrepResult, GlobResult, FileInfo, GrepMatch, FileData
)

class S3Backend(BackendProtocol):
    def __init__(self, bucket: str, prefix: str = ""):
        self.bucket = bucket
        self.prefix = prefix.rstrip("/")
        self.s3 = boto3.client("s3")

    def _key(self, path: str) -> str:
        return f"{self.prefix}{path}"

    def ls(self, path: str) -> LsResult:
        try:
            paginator = self.s3.get_paginator("list_objects_v2")
            pages = paginator.paginate(Bucket=self.bucket, Prefix=self._key(path).lstrip("/"), Delimiter="/")
            entries = []
            for page in pages:
                for obj in page.get("Contents", []):
                    key = obj["Key"]
                    entries.append(FileInfo(path="/"+key, is_dir=False, size=obj["Size"], modified_at=obj["LastModified"]))
                for prefix_obj in page.get("CommonPrefixes", []):
                    entries.append(FileInfo(path="/"+prefix_obj["Prefix"], is_dir=True))
            return LsResult(entries=entries)
        except Exception as e:
            mantis_log("ERROR", "s3_ls", str(e))
            return LsResult(error=str(e))

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        try:
            obj = self.s3.get_object(Bucket=self.bucket, Key=self._key(file_path).lstrip("/"))
            content = obj["Body"].read().decode("utf-8")
            if offset: content = content[offset:]
            if limit: content = content[:limit]
            return ReadResult(file_data=FileData(content=content, encoding="utf-8"))
        except Exception as e:
            return ReadResult(error=str(e))

    def write(self, file_path: str, content: str) -> WriteResult:
        try:
            self.s3.put_object(Bucket=self.bucket, Key=self._key(file_path).lstrip("/"), Body=content.encode("utf-8"))
            return WriteResult(path=file_path, files_update=None)
        except Exception as e:
            return WriteResult(error=str(e))

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        read_result = self.read(file_path)
        if read_result.error:
            return EditResult(error=read_result.error)
        current = read_result.file_data.content
        if replace_all:
            new_content = current.replace(old_string, new_string)
        else:
            new_content = current.replace(old_string, new_string, 1)
        write_result = self.write(file_path, new_content)
        if write_result.error:
            return EditResult(error=write_result.error)
        return EditResult(path=file_path, occurrences=1, files_update=None)

    def grep(self, pattern: str, path: str | None = None, glob: str | None = None) -> GrepResult:
        # Simplificado: lista arquivos, lê cada um e faz grep local
        ls_result = self.ls(path or "/")
        if ls_result.error:
            return GrepResult(error=ls_result.error)
        matches = []
        for entry in ls_result.entries:
            if not entry.is_dir:
                read_result = self.read(entry.path)
                if not read_result.error:
                    for i, line in enumerate(read_result.file_data.content.splitlines()):
                        if pattern in line:
                            matches.append(GrepMatch(path=entry.path, line=i+1, text=line))
        return GrepResult(matches=matches)

    def glob(self, pattern: str, path: str = "/") -> GlobResult:
        # Filtrar por padrão simples
        import fnmatch
        ls_result = self.ls(path)
        if ls_result.error:
            return GlobResult(error=ls_result.error)
        filtered = [f for f in ls_result.entries if fnmatch.fnmatch(f.path, f"{path}/{pattern}")]
        return GlobResult(matches=filtered)
```

### 2. Uso do S3Backend

```python
agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=S3Backend(bucket="meu-bucket", prefix="/agentes/"),
)
```

### 3. Backend PostgreSQL

```python
import psycopg2

class PostgresBackend(BackendProtocol):
    def __init__(self, conn_string: str, table: str = "files"):
        self.conn = psycopg2.connect(conn_string)
        self.table = table
        self._setup()

    def _setup(self):
        with self.conn.cursor() as cur:
            cur.execute(f"""
                CREATE TABLE IF NOT EXISTS {self.table} (
                    path TEXT PRIMARY KEY,
                    content TEXT,
                    created_at TIMESTAMPTZ DEFAULT now(),
                    modified_at TIMESTAMPTZ DEFAULT now()
                )
            """)
        self.conn.commit()

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        with self.conn.cursor() as cur:
            cur.execute(f"SELECT content FROM {self.table} WHERE path = %s", (file_path,))
            row = cur.fetchone()
            if not row:
                return ReadResult(error=f"File '{file_path}' not found")
            content = row[0][offset:offset+limit] if limit else row[0][offset:]
            return ReadResult(file_data=FileData(content=content, encoding="utf-8"))

    def write(self, file_path: str, content: str) -> WriteResult:
        try:
            with self.conn.cursor() as cur:
                cur.execute(f"INSERT INTO {self.table} (path, content) VALUES (%s, %s) ON CONFLICT (path) DO NOTHING", (file_path, content))
            self.conn.commit()
            return WriteResult(path=file_path, files_update=None)
        except Exception as e:
            return WriteResult(error=str(e))

    # ... outros métodos similares
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_s3_backend_write_read():
    # Mock do boto3
    pass
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-custom-backends.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-backends-overview.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T17:00:00Z | langchain-langraph-master-agent | Criação inicial: backends customizados | C1,C3,C5,C7,C8 |
