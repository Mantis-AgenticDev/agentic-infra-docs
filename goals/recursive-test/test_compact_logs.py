"""
---
artifact_id: "goals-recursive-test-test-compact-logs"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_compact_logs.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas de compactación de logs.
"""

import pytest
import gzip
from pathlib import Path
from datetime import datetime, timezone, timedelta
from goals.scripts.compact_logs import compact_logs


def test_compresses_old_logs(tmp_path):
    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    old_log = log_dir / "old.log"
    old_log.write_text("old content")
    # Forzar timestamp antiguo
    old_time = (datetime.now(timezone.utc) - timedelta(days=60)).timestamp()
    import os
    os.utime(str(old_log), (old_time, old_time))
    compact_logs(str(log_dir), days=30, dry_run=False)
    gz_path = log_dir / "old.log.gz"
    assert gz_path.exists()
    assert not old_log.exists()


def test_compact_dry_run(tmp_path):
    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    old_log = log_dir / "old.log"
    old_log.write_text("old")
    old_time = (datetime.now(timezone.utc) - timedelta(days=60)).timestamp()
    import os
    os.utime(str(old_log), (old_time, old_time))
    compact_logs(str(log_dir), days=30, dry_run=True)
    assert not (log_dir / "old.log.gz").exists()
    assert old_log.exists()


def test_keeps_recent_logs(tmp_path):
    log_dir = tmp_path / "logs"
    log_dir.mkdir()
    new_log = log_dir / "new.log"
    new_log.write_text("new")
    compact_logs(str(log_dir), days=30, dry_run=False)
    assert new_log.exists()
    assert not (log_dir / "new.log.gz").exists()
