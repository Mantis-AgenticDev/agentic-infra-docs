"""
---
artifact_id: "goals-recursive-test-test-sync-supabase"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_sync_supabase.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de sincronización a Supabase (mock).
"""

import pytest
import yaml
from pathlib import Path
from goals.scripts.sync_to_supabase import SupabaseSyncer


@pytest.fixture
def sync_config(tmp_path):
    config = {
        "supabase": {
            "enabled": True,
            "url": "http://test",
            "anon_key": "test-key",
            "table_prefix": "mantis_",
            "sync_interval_seconds": 300
        }
    }
    p = tmp_path / "sync-config.yaml"
    p.write_text(yaml.dump(config))
    return str(p)


def test_syncer_disabled_by_default(tmp_path):
    config = {"supabase": {"enabled": False}}
    p = tmp_path / "config.yaml"
    p.write_text(yaml.dump(config))
    syncer = SupabaseSyncer(str(p))
    assert syncer.enabled is False


def test_syncer_sync_goals_no_client(sync_config, monkeypatch):
    syncer = SupabaseSyncer(sync_config)
    # Sin cliente real, sync_goals retorna 0
    syncer.client = None
    count = syncer.sync_goals()
    assert count == 0
