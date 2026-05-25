---
artifact_id: "standalone-deployment"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/standalone-deployment.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/standalone-deployment.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:standalone-deploy-v1"
generated_at: "2026-05-26T12:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["data-plane-infra", "scaling-performance-tuning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Standalone Agent Server Deployment

> **Contrato modular**: Artefato filho do Master Agent. Contém a lógica para empacotar e executar Agent Servers de forma autônoma com Docker, Docker Compose e Kubernetes, sem dependência do Control Plane.

## 🎯 Propósito

Permitir o deploy de Agent Servers diretamente em infraestrutura própria, usando imagens Docker construídas com `langgraph build`, e orquestração via Docker Compose ou Helm, mantendo integração opcional com LangSmith para tracing.

## 📋 Especificação (SDD)
- **Entradas**: Dockerfile, `langgraph.json`, variáveis de ambiente (REDIS_URI, DATABASE_URI, etc.)
- **Saídas**: Serviço rodando e respondendo em `/ok`
- **Side Effects**: Criação de volumes, redes, e inicialização de PostgreSQL/Redis/MongoDB
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: Docker, `langgraph-cli`, Helm, Kubernetes, `docker-compose`

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
import subprocess, os, yaml, time, shutil
from typing import Dict, List, Optional
import tempfile

# ═══════════════════════════════════════════════════════════════════════════
# 1. CONSTRUÇÃO DA IMAGEM DOCKER
# ═══════════════════════════════════════════════════════════════════════════
class ImageBuilder:
    """Constrói a imagem Docker usando 'langgraph build'."""
    def __init__(self, project_dir: str, tag: str, platform: Optional[str] = None):
        self.project_dir = os.path.abspath(project_dir)
        self.tag = tag
        self.platform = platform

    def build(self) -> bool:
        cmd = ["langgraph", "build", "-t", self.tag]
        if self.platform:
            cmd += ["--platform", self.platform]
        mantis_log("INFO", "image_build_start", f"Tag: {self.tag}")
        proc = subprocess.run(cmd, cwd=self.project_dir, capture_output=True, text=True)
        if proc.returncode == 0:
            mantis_log("INFO", "image_build_ok", self.tag)
            return True
        else:
            mantis_log("ERROR", "image_build_fail", proc.stderr)
            return False

    def push(self, registry: str):
        full_tag = f"{registry}/{self.tag}"
        subprocess.run(["docker", "tag", self.tag, full_tag], check=True)
        subprocess.run(["docker", "push", full_tag], check=True)
        mantis_log("INFO", "image_push_ok", full_tag)

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONFIGURAÇÃO DE DOCKER COMPOSE
# ═══════════════════════════════════════════════════════════════════════════
class DockerComposeGenerator:
    """Gera arquivo docker-compose.yml para Agent Server standalone."""
    def __init__(self, image_name: str, use_mongodb: bool = False):
        self.image_name = image_name
        self.use_mongodb = use_mongodb

    def generate(self, env_vars: Dict[str, str] = None) -> str:
        compose = {
            "version": "3.8",
            "volumes": {
                "langgraph-data": {"driver": "local"}
            },
            "services": {
                "langgraph-redis": {
                    "image": "redis:6",
                    "healthcheck": {
                        "test": "redis-cli ping",
                        "interval": "5s",
                        "timeout": "1s",
                        "retries": 5
                    }
                },
                "langgraph-postgres": {
                    "image": "postgres:16",
                    "ports": ["5432:5432"],
                    "environment": {
                        "POSTGRES_DB": "postgres",
                        "POSTGRES_USER": "postgres",
                        "POSTGRES_PASSWORD": "postgres"
                    },
                    "volumes": ["langgraph-data:/var/lib/postgresql/data"],
                    "healthcheck": {
                        "test": "pg_isready -U postgres",
                        "start_period": "10s",
                        "timeout": "1s",
                        "retries": 5,
                        "interval": "5s"
                    }
                },
                "langgraph-api": {
                    "image": self.image_name,
                    "ports": ["8123:8000"],
                    "depends_on": {
                        "langgraph-redis": {"condition": "service_healthy"},
                        "langgraph-postgres": {"condition": "service_healthy"}
                    },
                    "environment": {
                        "REDIS_URI": "redis://langgraph-redis:6379",
                        "DATABASE_URI": "postgres://postgres:postgres@langgraph-postgres:5432/postgres?sslmode=disable",
                        "LANGSMITH_API_KEY": "${LANGSMITH_API_KEY}"
                    }
                }
            }
        }

        if self.use_mongodb:
            compose["services"]["langgraph-mongo"] = {
                "image": "mongo:7",
                "command": ["mongod", "--replSet", "rs0"],
                "ports": ["27017:27017"],
                "volumes": ["langgraph-mongo-data:/data/db"],
                "healthcheck": {
                    "test": "mongosh --eval 'try { rs.status().ok } catch(e) { rs.initiate({_id:\"rs0\",members:[{_id:0,host:\"langgraph-mongo:27017\"}]}).ok }' --quiet",
                    "interval": "5s",
                    "timeout": "10s",
                    "retries": 10,
                    "start_period": "10s"
                }
            }
            compose["volumes"]["langgraph-mongo-data"] = {"driver": "local"}
            compose["services"]["langgraph-api"]["depends_on"]["langgraph-mongo"] = {"condition": "service_healthy"}
            compose["services"]["langgraph-api"]["environment"]["LS_DEFAULT_CHECKPOINTER_BACKEND"] = "mongo"
            compose["services"]["langgraph-api"]["environment"]["LS_MONGODB_URI"] = "mongodb://langgraph-mongo:27017/langgraph?replicaSet=rs0"

        if env_vars:
            compose["services"]["langgraph-api"]["environment"].update(env_vars)

        return yaml.dump(compose, default_flow_style=False)

# ═══════════════════════════════════════════════════════════════════════════
# 3. DEPLOY COM DOCKER PURO
# ═══════════════════════════════════════════════════════════════════════════
class DockerRunner:
    def run(self, image: str, env_file: str, port: int = 8123):
        cmd = [
            "docker", "run", "--env-file", env_file, "-p", f"{port}:8000",
            "-e", f"REDIS_URI=redis://redis:6379",
            "-e", f"DATABASE_URI=postgres://postgres:postgres@postgres:5432/postgres",
            image
        ]
        mantis_log("INFO", "docker_run", f"Port: {port}")
        subprocess.Popen(cmd)
        time.sleep(5)  # aguarda inicialização

    @staticmethod
    def healthcheck(port: int = 8123, timeout: int = 30) -> bool:
        import requests
        start = time.time()
        while time.time() - start < timeout:
            try:
                r = requests.get(f"http://localhost:{port}/ok")
                if r.status_code == 200:
                    mantis_log("INFO", "healthcheck_ok", f"Port: {port}")
                    return True
            except:
                pass
            time.sleep(2)
        mantis_log("ERROR", "healthcheck_fail", f"Porta {port} não respondeu")
        return False

# ═══════════════════════════════════════════════════════════════════════════
# 4. DEPLOY KUBERNETES COM HELM
# ═══════════════════════════════════════════════════════════════════════════
class HelmDeployer:
    """Implanta Agent Server no Kubernetes usando o chart langgraph-cloud."""
    def __init__(self, release_name: str, namespace: str):
        self.release_name = release_name
        self.namespace = namespace

    def generate_values(self, image_name: str, use_mongo: bool = False) -> str:
        values = {
            "image": {"repository": image_name, "tag": "latest"},
            "redis": {"uri": "redis://langgraph-redis:6379"},
            "database": {"uri": "postgres://postgres:postgres@langgraph-postgres:5432/postgres"},
            "langsmithApiKey": "${LANGSMITH_API_KEY}"
        }
        if use_mongo:
            values["mongo"] = {"enabled": True}
            values["LS_DEFAULT_CHECKPOINTER_BACKEND"] = "mongo"
            values["LS_MONGODB_URI"] = "mongodb://mongo:27017/langgraph?replicaSet=rs0"
        return yaml.dump(values, default_flow_style=False)

    def install(self, chart: str = "langchain/langgraph-cloud", version: str = ""):
        cmd = ["helm", "install", self.release_name, chart, "-n", self.namespace, "--create-namespace", "--wait", "--debug"]
        if version:
            cmd += ["--version", version]
        mantis_log("INFO", "helm_install", self.release_name)
        subprocess.run(cmd, check=True)

    def upgrade(self, values_file: str):
        subprocess.run(["helm", "upgrade", self.release_name, "langchain/langgraph-cloud", "-n", self.namespace, "-f", values_file, "--wait", "--debug"], check=True)

# ═══════════════════════════════════════════════════════════════════════════
# 5. GERENCIADOR DE CICLO DE VIDA
# ═══════════════════════════════════════════════════════════════════════════
class StandaloneLifecycle:
    def __init__(self, project_dir: str, image_tag: str):
        self.builder = ImageBuilder(project_dir, image_tag)
        self.compose_gen = DockerComposeGenerator(image_tag)
        self.helm = HelmDeployer(image_tag.split(":")[0], "default")

    def full_docker_compose_cycle(self, env_vars: dict = None, use_mongo: bool = False) -> bool:
        if not self.builder.build():
            return False
        compose_content = self.compose_gen.generate(env_vars)
        compose_file = os.path.join(self.builder.project_dir, "docker-compose.yml")
        with open(compose_file, "w") as f:
            f.write(compose_content)
        subprocess.run(["docker-compose", "-f", compose_file, "up", "-d"], check=True)
        return DockerRunner.healthcheck()

    def full_kubernetes_cycle(self, use_mongo: bool = False) -> bool:
        if not self.builder.build():
            return False
        values_yaml = self.helm.generate_values(self.builder.tag, use_mongo)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            f.write(values_yaml)
            values_path = f.name
        self.helm.install()
        return True
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from standalone_deployment import DockerComposeGenerator, ImageBuilder, DockerRunner

def test_compose_generator_postgres_only():
    gen = DockerComposeGenerator("my-agent:v1")
    y = gen.generate()
    data = yaml.safe_load(y)
    assert "langgraph-postgres" in data["services"]
    assert "langgraph-mongo" not in data["services"]

def test_compose_generator_with_mongo():
    gen = DockerComposeGenerator("my-agent:v1", use_mongodb=True)
    y = gen.generate()
    data = yaml.safe_load(y)
    assert "langgraph-mongo" in data["services"]
    assert data["services"]["langgraph-api"]["environment"]["LS_DEFAULT_CHECKPOINTER_BACKEND"] == "mongo"

@patch('subprocess.run')
def test_image_build_success(mock_run):
    mock_run.return_value = MagicMock(returncode=0, stdout="Success")
    builder = ImageBuilder("/fake/project", "test:latest")
    assert builder.build()

@patch('requests.get')
def test_healthcheck_ok(mock_get):
    mock_get.return_value.status_code = 200
    assert DockerRunner.healthcheck(timeout=1)
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/standalone-deployment.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[data-plane-infra.md]]
- [[scaling-performance-tuning.md]]
