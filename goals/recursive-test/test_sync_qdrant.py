"""
---
artifact_id: "goals-recursive-test-test-sync-qdrant"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_sync_qdrant.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de sincronización a Qdrant (mock).
"""

import pytest
import yaml
from pathlib import Path
from goals.scripts.sync_to_qdrant import QdrantSyncer


@pytest.fixture
def sync_config(tmp_path):
    config = {
        "qdrant": {
            "enabled": True,
            "url": "http://localhost:6333",
            "collection_name": "test_collection",
            "vector_size": 1536
        }
    }
    p = tmp_path / "sync-config.yaml"
    p.write_text(yaml.dump(config))
    return str(p)


def test_syncer_disabled(tmp_path):
    config = {"qdrant": {"enabled": False}}
    p = tmp_path / "config.yaml"
    p.write_text(yaml.dump(config))
    syncer = QdrantSyncer(str(p))
    assert syncer.enabled is False


def test_syncer_sync_goals_no_client(sync_config, monkeypatch):
    syncer = QdrantSyncer(sync_config)
    syncer.client = None
    count = syncer.sync_goals()
    assert count == 0
