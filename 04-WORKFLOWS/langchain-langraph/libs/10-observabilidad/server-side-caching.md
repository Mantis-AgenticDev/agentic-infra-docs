---
artifact_id: "server-side-caching"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/server-side-caching.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/server-side-caching.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:server-cache-v1"
generated_at: "2026-05-26T13:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["custom-auth-authorization", "langgraph-create-agent"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Server-Side Caching (SWR & Key-Value)

> **Contrato modular**: Artefato filho do Master Agent. Implementa as APIs de cache do Agent Server (`swr`, `cache_get`, `cache_set`) com suporte a stale-while-revalidate, modelos Pydantic e métricas de status.

## 🎯 Propósito

Fornecer uma camada de cache dentro do Agent Server para acelerar cargas de trabalho, reduzir latência e evitar chamadas repetitivas a serviços externos, com revalidação assíncrona e controle de frescor.

## 📋 Especificação (SDD)
- **Entradas**: Chave (`str`), função loader assíncrona, `fresh_for`, `max_age`, modelo Pydantic opcional
- **Saídas**: `SWRResult` com valor e status (`miss`, `fresh`, `stale`, `expired`)
- **Side Effects**: Escrita e leitura no cache via `cache_set`/`cache_get`
- **Constraints Aplicáveis**: C1 (Resiliência), C3 (Segurança), C5 (Integridade), C8 (Observabilidade)
- **Dependências**: `langgraph-sdk`, `pydantic`, `datetime`, `asyncio`

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

# ─── IMPORTAÇÕES E TIPOS ────────────────────────────────────────────────
import asyncio
from datetime import timedelta, datetime, timezone
from typing import Any, Callable, Optional, Type, TypeVar, Generic, Dict
from pydantic import BaseModel
from langgraph_sdk.cache import cache_get, cache_set

T = TypeVar("T")

class SWRResult(Generic[T]):
    """Resultado da operação SWR."""
    def __init__(self, value: T, status: str, loader: Optional[Callable] = None, key: str = ""):
        self.value = value
        self.status = status  # miss, fresh, stale, expired
        self._loader = loader
        self._key = key

    async def mutate(self, new_value: Any = None):
        if new_value is not None:
            await cache_set(self._key, new_value)
            self.value = new_value
            self.status = "fresh"
            mantis_log("INFO", "cache_mutated", self._key)
        elif self._loader:
            value = await self._loader()
            await cache_set(self._key, value)
            self.value = value
            self.status = "fresh"
            mantis_log("INFO", "cache_revalidated", self._key)

# ═══════════════════════════════════════════════════════════════════════════
# 1. IMPLEMENTAÇÃO DO SWR
# ═══════════════════════════════════════════════════════════════════════════
class SWRManager:
    """Gerencia o padrão stale-while-revalidate."""
    def __init__(self, default_fresh: timedelta = timedelta(minutes=5), default_max_age: timedelta = timedelta(hours=1)):
        self.default_fresh = default_fresh
        self.default_max_age = default_max_age

    async def swr(
        self,
        key: str,
        loader: Callable[[], Any],
        fresh_for: Optional[timedelta] = None,
        max_age: Optional[timedelta] = None,
        model: Optional[Type[BaseModel]] = None
    ) -> SWRResult:
        fresh_for = fresh_for or self.default_fresh
        max_age = max_age or self.default_max_age

        cached = await cache_get(key)
        now = datetime.now(timezone.utc)

        if cached is None:
            # Cache miss
            mantis_log("INFO", "cache_miss", key)
            value = await loader()
            await self._store(key, value, model, fresh_for, max_age)
            return SWRResult(value, "miss", loader, key)

        cached_value, cached_at = cached if isinstance(cached, (list, tuple)) and len(cached) == 2 else (cached, now)
        age = now - cached_at

        if age < fresh_for:
            mantis_log("DEBUG", "cache_fresh", key)
            return SWRResult(cached_value, "fresh", loader, key)

        if age < max_age:
            mantis_log("DEBUG", "cache_stale", key)
            asyncio.ensure_future(self._revalidate(key, loader, model, fresh_for, max_age))
            return SWRResult(cached_value, "stale", loader, key)

        # Expirado
        mantis_log("WARN", "cache_expired", key)
        value = await loader()
        await self._store(key, value, model, fresh_for, max_age)
        return SWRResult(value, "expired", loader, key)

    async def _store(self, key, value, model, fresh_for, max_age):
        if model and isinstance(value, dict):
            value = model(**value)
        serialized = model.model_dump(mode="json") if model and isinstance(value, BaseModel) else value
        await cache_set(key, [serialized, datetime.now(timezone.utc)], ttl=max_age)

    async def _revalidate(self, key, loader, model, fresh_for, max_age):
        try:
            mantis_log("INFO", "cache_revalidate_start", key)
            value = await loader()
            await self._store(key, value, model, fresh_for, max_age)
            mantis_log("INFO", "cache_revalidate_done", key)
        except Exception as e:
            mantis_log("ERROR", "cache_revalidate_fail", f"{key}: {str(e)}")

# ═══════════════════════════════════════════════════════════════════════════
# 2. CACHE DE CREDENCIAIS (EXEMPLO DE USO EM AUTH)
# ═══════════════════════════════════════════════════════════════════════════
class AuthCache:
    """Cache para validação de tokens em custom auth handlers."""
    def __init__(self, cache_manager: SWRManager):
        self.cache = cache_manager

    async def get_user(self, token: str, validator: Callable) -> dict:
        key = f"auth:token:{hash(token)}"
        result = await self.cache.swr(
            key,
            lambda: validator(token),
            fresh_for=timedelta(minutes=5),
            max_age=timedelta(hours=1)
        )
        return result.value

# ═══════════════════════════════════════════════════════════════════════════
# 3. CACHE COM PYDANTIC (VALIDADO)
# ═══════════════════════════════════════════════════════════════════════════
class PydanticCache:
    """Wrapper que serializa/deserializa automaticamente com modelos Pydantic."""
    def __init__(self, cache: SWRManager):
        self.cache = cache

    async def get_or_load(self, key: str, loader: Callable, model: Type[BaseModel], fresh_for: Optional[timedelta] = None) -> BaseModel:
        result = await self.cache.swr(key, loader, fresh_for=fresh_for, model=model)
        if isinstance(result.value, model):
            return result.value
        return model(**result.value)

# ═══════════════════════════════════════════════════════════════════════════
# 4. MÉTRICAS E ESTATÍSTICAS DO CACHE
# ═══════════════════════════════════════════════════════════════════════════
class CacheStats:
    def __init__(self):
        self.hits = 0
        self.misses = 0
        self.stales = 0
        self.expirations = 0

    def record(self, status: str):
        if status == "miss":
            self.misses += 1
        elif status == "fresh":
            self.hits += 1
        elif status == "stale":
            self.stales += 1
        elif status == "expired":
            self.expirations += 1

    def hit_ratio(self) -> float:
        total = self.hits + self.misses + self.stales + self.expirations
        return (self.hits + self.stales) / total if total else 0.0

    def report(self) -> dict:
        return {
            "hits": self.hits,
            "misses": self.misses,
            "stales": self.stales,
            "expirations": self.expirations,
            "hit_ratio": self.hit_ratio()
        }
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from server_side_caching import SWRManager, SWRResult, CacheStats
from datetime import timedelta
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
async def test_cache_miss():
    mgr = SWRManager()
    with patch('server_side_caching.cache_get', new=AsyncMock(return_value=None)):
        with patch('server_side_caching.cache_set', new=AsyncMock()):
            result = await mgr.swr("key1", lambda: "value1")
            assert result.status == "miss"
            assert result.value == "value1"

@pytest.mark.asyncio
async def test_cache_fresh():
    mgr = SWRManager(default_fresh=timedelta(days=1))
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc)
    cached = ("value_old", now)
    with patch('server_side_caching.cache_get', new=AsyncMock(return_value=cached)):
        result = await mgr.swr("key2", lambda: "new")
        assert result.status == "fresh"
        assert result.value == "value_old"

@pytest.mark.asyncio
async def test_cache_stale():
    mgr = SWRManager(default_fresh=timedelta(seconds=0), default_max_age=timedelta(days=1))
    now = datetime.now(timezone.utc)
    cached = ("stale_val", now)
    with patch('server_side_caching.cache_get', new=AsyncMock(return_value=cached)):
        with patch('server_side_caching.cache_set', new=AsyncMock()):
            result = await mgr.swr("key3", lambda: "fresh_val")
            assert result.status == "stale"

def test_cache_stats():
    stats = CacheStats()
    stats.record("miss")
    stats.record("fresh")
    stats.record("fresh")
    assert stats.hit_ratio() == 2/3
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/server-side-caching.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[custom-auth-authorization.md]]
- [[langgraph-create-agent.md]]
