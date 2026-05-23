"""
---
artifact_id: "goals-recursive-test-test-quota-parser"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_quota_parser.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del calculador de cuotas (next_wakeup).
"""

import pytest
import yaml
from datetime import datetime, timezone
from pathlib import Path
from goals.libs.quota_parser import QuotaParser


@pytest.fixture
def policies_file(tmp_path):
    data = {
        "providers": {
            "claude": {
                "window": "fixed",
                "reset_time_utc": "00:00",
                "safety_margin_minutes": 30
            },
            "gemini": {
                "window": "rolling",
                "interval_hours": 1,
                "safety_margin_minutes": 5
            },
            "chatgpt-plus": {
                "window": "rolling",
                "interval_hours": 3,
                "safety_margin_minutes": 5
            },
            "antigravity-pro": {
                "window": "weekly",
                "reset_hour_utc": 0
            }
        }
    }
    p = tmp_path / "provider-policies.yaml"
    p.write_text(yaml.dump(data))
    return str(p)


def test_get_next_wakeup_fixed(policies_file):
    parser = QuotaParser(policies_path=policies_file)
    wake = parser.get_next_wakeup("claude")
    assert wake is not None


def test_get_next_wakeup_rolling(policies_file):
    parser = QuotaParser(policies_path=policies_file)
    wake = parser.get_next_wakeup("gemini")
    assert wake is not None


def test_get_next_wakeup_weekly(policies_file):
    parser = QuotaParser(policies_path=policies_file)
    wake = parser.get_next_wakeup("antigravity-pro")
    assert wake is not None


def test_get_next_wakeup_unknown_provider(policies_file):
    parser = QuotaParser(policies_path=policies_file)
    wake = parser.get_next_wakeup("proveedor-inexistente")
    assert wake is None
