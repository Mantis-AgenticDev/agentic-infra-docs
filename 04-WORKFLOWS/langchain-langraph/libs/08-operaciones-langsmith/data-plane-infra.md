---
artifact_id: "data-plane-infra"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:data-plane-infra-v1"
generated_at: "2026-05-26T10:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["scaling-performance-tuning", "checkpointer-backend-config"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Data Plane Infrastructure Automation

> **Contrato modular**: Artefato filho do Master Agent. Contém a lógica para interagir com a infraestrutura do Data Plane: PostgreSQL, Redis, MongoDB, autoescalonamento e telemetria.

## 🎯 Propósito

Fornecer uma biblioteca de funções para gerenciar, monitorar e configurar a infraestrutura de execução dos Agent Servers, incluindo health checks, pool de conexões, métricas de autoescalonamento e configuração de backends de checkpoint.

## 📋 Especificação (SDD)
- **Entradas**: Configurações de conexão (URI), limites de recursos, métricas
- **Saídas**: Status de saúde, métricas de performance, ações de scaling
- **Side Effects**: Criação de índices, ajuste de parâmetros de pool, queries de monitoramento
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `asyncpg`, `redis`, `psutil`, `pymongo`, `langgraph-checkpoint`

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
import asyncio, os, logging, time
from typing import Optional, Dict, Any, List, Tuple
import asyncpg
import redis.asyncio as redis
import psutil
from pymongo import MongoClient

# ═══════════════════════════════════════════════════════════════════════════
# 1. HEALTH CHECKER MULTI-BACKEND
# ═══════════════════════════════════════════════════════════════════════════
class DataPlaneHealth:
    def __init__(self, db_uri: str, redis_uri: str, mongo_uri: Optional[str] = None):
        self.db_uri = db_uri
        self.redis_uri = redis_uri
        self.mongo_uri = mongo_uri

    async def check_postgres(self) -> Dict[str, Any]:
        try:
            conn = await asyncpg.connect(self.db_uri)
            row = await conn.fetchrow("SELECT 1 AS ok, pg_database_size(current_database()) AS size, version() AS version")
            await conn.close()
            mantis_log("INFO", "pg_health_ok", str(dict(row)))
            return {"status": "healthy", "size": row["size"], "version": row["version"]}
        except Exception as e:
            mantis_log("ERROR", "pg_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

    async def check_redis(self) -> Dict[str, Any]:
        try:
            r = redis.Redis.from_url(self.redis_uri)
            await r.ping()
            info = await r.info()
            await r.close()
            mantis_log("INFO", "redis_health_ok", f"Memory used: {info.get('used_memory_human')}")
            return {"status": "healthy", "used_memory": info.get("used_memory_human")}
        except Exception as e:
            mantis_log("ERROR", "redis_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

    def check_mongodb(self) -> Dict[str, Any]:
        if not self.mongo_uri:
            return {"status": "not_configured"}
        try:
            client = MongoClient(self.mongo_uri, serverSelectionTimeoutMS=5000)
            client.server_info()
            db = client.get_default_database()
            stats = db.command("dbStats")
            mantis_log("INFO", "mongo_health_ok", f"Data size: {stats.get('dataSize')}")
            return {"status": "healthy", "data_size": stats.get("dataSize")}
        except Exception as e:
            mantis_log("ERROR", "mongo_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

# ═══════════════════════════════════════════════════════════════════════════
# 2. AUTOESCALONAMENTO SIMULADO (MÉTRICAS E DECISÃO)
# ═══════════════════════════════════════════════════════════════════════════
class AutoscalingSimulator:
    """
    Simula o autoescalonamento baseado em CPU, memória e fila de runs pendentes.
    Pode ser usado para testar políticas de scaling ou gerar alertas.
    """
    def __init__(self, target_cpu: float = 75, target_memory: float = 75, target_pending: int = 10):
        self.target_cpu = target_cpu
        self.target_memory = target_memory
        self.target_pending = target_pending

    def get_current_metrics(self) -> Dict[str, float]:
        cpu = psutil.cpu_percent()
        mem = psutil.virtual_memory().percent
        # pending runs seria lido de uma fonte externa, simulamos aqui
        pending = self._read_pending_runs()
        mantis_log("INFO", "current_metrics", f"CPU={cpu}%, Memory={mem}%, Pending={pending}")
        return {"cpu": cpu, "memory": mem, "pending_runs": pending}

    def _read_pending_runs(self) -> int:
        # Em produção, isso viria do Agent Server queue stats
        return int(os.getenv("PENDING_RUNS", "5"))

    def calculate_desired_replicas(self, current_replicas: int) -> int:
        metrics = self.get_current_metrics()
        reasons = []
        desired = current_replicas
        if metrics["cpu"] > self.target_cpu:
            desired = max(desired, min(current_replicas * 2, 10))
            reasons.append(f"CPU {metrics['cpu']}% > {self.target_cpu}%")
        if metrics["memory"] > self.target_memory:
            desired = max(desired, min(current_replicas * 2, 10))
            reasons.append(f"Memory {metrics['memory']}% > {self.target_memory}%")
        if metrics["pending_runs"] > self.target_pending * current_replicas:
            new = int(metrics["pending_runs"] / self.target_pending)
            desired = max(desired, new)
            reasons.append(f"Pending {metrics['pending_runs']} > {self.target_pending * current_replicas}")
        if desired > current_replicas:
            mantis_log("WARN", "autoscale_up", f"From {current_replicas} to {desired}, reasons: {', '.join(reasons)}")
        elif desired < current_replicas:
            mantis_log("INFO", "autoscale_down", f"From {current_replicas} to {desired}")
        return desired

# ═══════════════════════════════════════════════════════════════════════════
# 3. CONFIGURAÇÃO DE CHECKPOINTER (POSTGRES / MONGODB / CUSTOM)
# ═══════════════════════════════════════════════════════════════════════════
class CheckpointerConfigurator:
    """Configura o backend de checkpoint conforme langgraph.json ou variáveis de ambiente."""
    BACKEND_POSTGRES = "postgres"
    BACKEND_MONGO = "mongo"
    BACKEND_CUSTOM = "custom"

    def __init__(self, config: dict):
        self.backend = config.get("backend", "default")
        self.ttl = config.get("ttl", {})

    def get_connection_args(self) -> dict:
        if self.backend == CheckpointerConfigurator.BACKEND_MONGO:
            uri = os.getenv("LS_MONGODB_URI", "mongodb://localhost:27017/langgraph")
            return {"uri": uri, "replica_set": "rs0"}
        elif self.backend == CheckpointerConfigurator.BACKEND_POSTGRES:
            uri = os.getenv("DATABASE_URI") or os.getenv("POSTGRES_URI_CUSTOM")
            if not uri:
                raise ValueError("DATABASE_URI não configurada")
            return {"uri": uri}
        else:
            # Custom – carregar dinamicamente
            return {"backend": "custom", "path": config.get("path")}

    def get_ttl_settings(self) -> dict:
        return {
            "strategy": self.ttl.get("strategy", "delete"),
            "default_ttl": self.ttl.get("default_ttl", 43200),
            "sweep_interval_minutes": self.ttl.get("sweep_interval_minutes", 10)
        }

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE POOL DE CONEXÕES (POSTGRES)
# ═══════════════════════════════════════════════════════════════════════════
class PoolManager:
    def __init__(self, uri: str, min_size: int = 5, max_size: int = 20):
        self.uri = uri
        self.min_size = min_size
        self.max_size = max_size
        self._pool = None

    async def initialize(self):
        self._pool = await asyncpg.create_pool(
            self.uri,
            min_size=self.min_size,
            max_size=self.max_size,
            max_inactive_connection_lifetime=300
        )
        mantis_log("INFO", "pool_initialized", f"min={self.min_size}, max={self.max_size}")

    async def acquire(self):
        if not self._pool:
            await self.initialize()
        return await self._pool.acquire()

    async def close(self):
        if self._pool:
            await self._pool.close()
            mantis_log("INFO", "pool_closed")

# ═══════════════════════════════════════════════════════════════════════════
# 5. SIMULADOR DE CARGA PARA TESTE DE ESTRESSE
# ═══════════════════════════════════════════════════════════════════════════
class LoadSimulator:
    """Simula um número de runs concorrentes para testar o scaling."""
    def __init__(self, autoscaler: AutoscalingSimulator, pool_manager: PoolManager):
        self.autoscaler = autoscaler
        self.pool = pool_manager

    async def simulate_runs(self, count: int):
        tasks = [self._simulate_run(i) for i in range(count)]
        await asyncio.gather(*tasks)

    async def _simulate_run(self, run_id: int):
        conn = await self.pool.acquire()
        try:
            await conn.execute("SELECT pg_sleep(0.1)")  # trabalho simulado
            mantis_log("DEBUG", "run_completed", f"Run {run_id}")
        finally:
            await self.pool.release(conn)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from data_plane_infra import AutoscalingSimulator, DataPlaneHealth, CheckpointerConfigurator

def test_autoscaler_scale_up():
    asm = AutoscalingSimulator(target_cpu=50, target_memory=50, target_pending=5)
    # Simula alta CPU
    with patch('psutil.cpu_percent', return_value=90):
        with patch.object(asm, '_read_pending_runs', return_value=20):
            desired = asm.calculate_desired_replicas(1)
            assert desired > 1

def test_checkpointer_config_postgres():
    config = {"backend": "postgres"}
    cc = CheckpointerConfigurator(config)
    assert cc.backend == "postgres"
    args = cc.get_connection_args()
    assert "uri" in args

def test_health_check_pg_mock():
    import asyncio
    async def run():
        hp = DataPlaneHealth("postgres://test", "redis://test")
        with patch('asyncpg.connect') as mock_conn:
            mock_conn.return_value.fetchrow = AsyncMock(return_value={"ok": 1, "size": 123, "version": "PostgreSQL 16"})
            result = await hp.check_postgres()
            assert result["status"] == "healthy"
    asyncio.run(run())
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[scaling-performance-tuning.md]]
- [[checkpointer-backend-config.md]]
