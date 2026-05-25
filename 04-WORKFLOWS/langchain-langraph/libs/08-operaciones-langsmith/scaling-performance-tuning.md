---
artifact_id: "scaling-performance-tuning"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/scaling-performance-tuning.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/scaling-performance-tuning.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:scaling-tuning-v1"
generated_at: "2026-05-26T11:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["data-plane-infra", "checkpointer-backend-config"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Scaling & Performance Tuning

> **Contrato modular**: Artefato filho do Master Agent. Contém modelos de cálculo de capacidade, configurações de workers e ajustes finos de performance para Agent Servers sob diferentes cargas.

## 🎯 Propósito

Otimizar o desempenho e o escalonamento de Agent Servers, ajustando parâmetros como `N_JOBS_PER_WORKER`, número de API servers e queue workers, e aplicando melhores práticas de leitura/escrita.

## 📋 Especificação (SDD)
- **Entradas**: Métricas de carga (reads/s, writes/s), tipo de workload, recursos do cluster
- **Saídas**: Configuração YAML recomendada, número de réplicas, limites de recursos
- **Side Effects**: Geração de alertas, ajustes automáticos de scaling
- **Constraints Aplicáveis**: C1, C2, C3, C5, C8
- **Dependências**: `PyYAML`, `psutil`, `asyncio`

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
import yaml, math
from typing import Dict, Any, Tuple
from dataclasses import dataclass

# ═══════════════════════════════════════════════════════════════════════════
# 1. MODELOS DE CAPACIDADE
# ═══════════════════════════════════════════════════════════════════════════
@dataclass
class WorkloadProfile:
    read_rps: float          # leituras por segundo
    write_rps: float         # escritas (runs) por segundo
    avg_run_time: float = 1.0 # tempo médio de execução em segundos
    cpu_bound: bool = False
    io_bound: bool = False

class CapacityPlanner:
    """
    Calcula a configuração ideal do Agent Server baseado no workload.
    Baseado nas fórmulas:
    - available_jobs = number_of_queue_workers * N_JOBS_PER_WORKER
    - throughput_per_second = available_jobs / avg_run_time
    - number_of_queue_workers = write_rps * avg_run_time / N_JOBS_PER_WORKER
    """
    DEFAULT_N_JOBS = 10
    API_CPU_PER_REPLICA = 1.0  # 1 CPU por API server
    API_MEM_PER_REPLICA = 2.0  # Gi
    QUEUE_CPU_PER_REPLICA = 1.0
    QUEUE_MEM_PER_REPLICA = 2.0

    def __init__(self, n_jobs_per_worker: int = DEFAULT_N_JOBS):
        self.n_jobs = n_jobs_per_worker

    def calculate_workers(self, profile: WorkloadProfile) -> int:
        """Número mínimo de queue workers."""
        if profile.write_rps == 0:
            return 1  # default
        workers = math.ceil(profile.write_rps * profile.avg_run_time / self.n_jobs)
        mantis_log("INFO", "calculated_workers", f"Writes {profile.write_rps}/s, run_time {profile.avg_run_time}s -> {workers} workers")
        return max(1, workers)

    def calculate_api_servers(self, profile: WorkloadProfile) -> int:
        """API servers baseados na carga de leitura (regra empírica)."""
        # 1 API server ~100 reads/s como baseline
        base = max(1, math.ceil(profile.read_rps / 100))
        mantis_log("INFO", "calculated_api_servers", f"Reads {profile.read_rps}/s -> {base} servers")
        return base

    def generate_yaml(self, profile: WorkloadProfile) -> str:
        workers = self.calculate_workers(profile)
        api = self.calculate_api_servers(profile)
        config = {
            "api": {
                "replicas": api,
                "resources": {
                    "requests": {"cpu": f"{self.API_CPU_PER_REPLICA}", "memory": f"{self.API_MEM_PER_REPLICA}Gi"},
                    "limits": {"cpu": f"{self.API_CPU_PER_REPLICA * 2}", "memory": f"{self.API_MEM_PER_REPLICA * 2}Gi"}
                }
            },
            "queue": {
                "replicas": workers,
                "resources": {
                    "requests": {"cpu": f"{self.QUEUE_CPU_PER_REPLICA}", "memory": f"{self.QUEUE_MEM_PER_REPLICA}Gi"},
                    "limits": {"cpu": f"{self.QUEUE_CPU_PER_REPLICA * 2}", "memory": f"{self.QUEUE_MEM_PER_REPLICA * 2}Gi"}
                }
            },
            "config": {
                "numberOfJobsPerWorker": self.n_jobs
            }
        }
        return yaml.dump(config, default_flow_style=False)

# ═══════════════════════════════════════════════════════════════════════════
# 2. OTIMIZAÇÕES DE EXECUÇÃO
# ═══════════════════════════════════════════════════════════════════════════
class ExecutionOptimizer:
    @staticmethod
    def suggest_durability(use_case: str) -> str:
        suggestions = {
            "chatbot": "async",   # normal
            "batch": "exit",      # só estado final
            "critical": "sync"    # cada passo persistido
        }
        return suggestions.get(use_case, "async")

    @staticmethod
    def suggest_n_jobs(cpu_bound: bool, io_bound: bool) -> int:
        if cpu_bound:
            return 10
        if io_bound:
            return 50
        return 10

    @staticmethod
    def recommend_read_optimizations(reads: float) -> list:
        tips = []
        if reads > 50:
            tips.append("Use /join em vez de polling")
        if reads > 200:
            tips.append("Considere read replicas para Postgres")
        return tips

# ═══════════════════════════════════════════════════════════════════════════
# 3. SIMULADOR DE THROUGHPUT
# ═══════════════════════════════════════════════════════════════════════════
class ThroughputSimulator:
    def __init__(self, planner: CapacityPlanner):
        self.planner = planner

    def simulate(self, profile: WorkloadProfile, workers: int) -> dict:
        available_jobs = workers * self.planner.n_jobs
        max_throughput = available_jobs / profile.avg_run_time
        utilization = profile.write_rps / max_throughput if max_throughput > 0 else float('inf')
        return {
            "available_jobs": available_jobs,
            "max_throughput_rps": max_throughput,
            "utilization_percent": utilization * 100,
            "saturated": utilization > 0.8
        }

    def generate_report(self, profiles: list) -> str:
        report_lines = ["Load Profile | Workers | Max Throughput | Util % | Saturated"]
        for p in profiles:
            w = self.planner.calculate_workers(p)
            res = self.simulate(p, w)
            report_lines.append(f"{p.write_rps}w/{p.read_rps}r | {w} | {res['max_throughput_rps']:.1f} | {res['utilization_percent']:.0f}% | {res['saturated']}")
        return "\n".join(report_lines)

# ═══════════════════════════════════════════════════════════════════════════
# 4. MONITOR DE SAÚDE PARA ESCALONAMENTO
# ═══════════════════════════════════════════════════════════════════════════
class ScalingHealthMonitor:
    def __init__(self, planner: CapacityPlanner):
        self.planner = planner

    async def check_and_alert(self, current_workers: int, profile: WorkloadProfile):
        recommended = self.planner.calculate_workers(profile)
        if recommended > current_workers:
            mantis_log("WARN", "scaling_needed", f"Current: {current_workers}, Recommended: {recommended}")
            return {"action": "scale_up", "target_workers": recommended}
        elif recommended < current_workers * 0.5:
            mantis_log("INFO", "overprovisioned", f"Current: {current_workers}, Recommended: {recommended}")
            return {"action": "scale_down", "target_workers": recommended}
        return {"action": "stable"}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from scaling_performance_tuning import CapacityPlanner, WorkloadProfile, ThroughputSimulator

def test_light_workload():
    planner = CapacityPlanner(n_jobs_per_worker=10)
    profile = WorkloadProfile(read_rps=5, write_rps=5, avg_run_time=1.0)
    workers = planner.calculate_workers(profile)
    assert workers == 1

def test_heavy_write_workload():
    planner = CapacityPlanner(n_jobs_per_worker=10)
    profile = WorkloadProfile(read_rps=5, write_rps=500, avg_run_time=1.0)
    workers = planner.calculate_workers(profile)
    assert workers == 50

def test_generate_yaml():
    planner = CapacityPlanner()
    y = planner.generate_yaml(WorkloadProfile(50, 50))
    assert "api:" in y
    assert "queue:" in y

def test_simulator_saturation():
    planner = CapacityPlanner(n_jobs_per_worker=10)
    sim = ThroughputSimulator(planner)
    profile = WorkloadProfile(read_rps=0, write_rps=150, avg_run_time=2.0)
    workers = 5  # underprovisioned
    res = sim.simulate(profile, workers)
    assert res["saturated"]
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/scaling-performance-tuning.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[data-plane-infra.md]]
- [[checkpointer-backend-config.md]]
