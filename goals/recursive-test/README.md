---
artifact_id: "goals-recursive-test-readme"
artifact_type: "test_documentation"
version: "2.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "goals/recursive-test/README.md"
tier: 2
immutable: false
audience: ["developers","qa"]
language_lock: "pt-BR"
prompt_hash: "sha256:recursive-test-readme-v2.0.0"
generated_at: "2026-05-23T11:00:00Z"
domain: "goals"
subdomain: "recursive-test"
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---

# Sistema de Pruebas Recursivas — MANTIS GOALS

## Requisitos
- Python 3.12+
- pytest
- Librerías estándar: `sqlite3`, `json`, `yaml`, `uuid`, `datetime`, `pathlib`

## Ejecución

```bash
# Todas las pruebas
pytest goals/recursive-test/ -v

# Solo unitarias
pytest goals/recursive-test/test_registry_client.py goals/recursive-test/test_agent_db_manager.py -v

# Integración completa
pytest goals/recursive-test/test_integration_handoff.py -v

# Estrés concurrente
pytest goals/recursive-test/test_stress_autonomy.py -v

# Con cobertura
pytest goals/recursive-test/ --cov=goals/libs --cov=goals/scripts
```

## Estructura

```
goals/recursive-test/
├── README.md
├── conftest.py                    # Fixtures con esquemas REALES
├── test_registry_client.py
├── test_agent_db_manager.py
├── test_context_segmenter.py
├── test_prompt_builder.py
├── test_contract_parser.py
├── test_quota_parser.py
├── test_handoff_package.py
├── test_log_reader.py
├── test_init_registry.py
├── test_init_agent_db.py
├── test_check_a2a_contract.py
├── test_rotate_agent_db.py
├── test_health_check_agents.py
├── test_validate_registry.py
├── test_team_orchestrator.py
├── test_observer_telegram.py
├── test_tui_dashboard.py
├── test_tui_validator.py
├── test_compact_logs.py
├── test_sync_supabase.py
├── test_sync_qdrant.py
├── test_mcp_server.py
├── test_schema_validation.py
├── test_integration_handoff.py
├── test_stress_autonomy.py
├── fixtures/
│   ├── sample_trace.json
│   └── sample_status.json
└── logs/
    └── (logs de ejecución)
```

## Cobertura esperada
- **>80%** en `goals/libs/` y `goals/scripts/`
- **100%** de métodos públicos de `RegistryClient` y `AgentDBManager`
