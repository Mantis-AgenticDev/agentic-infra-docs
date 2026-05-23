"""
---
artifact_id: "goals-recursive-test-test-observer-telegram"
artifact_type: "unit_test"
version: "2.0.0"
canonical_path: "goals/recursive-test/test_observer_telegram.py"
tier: 2
status: "✅ Estável"
license: "CC-BY-NC-SA-4.0"
---
Pruebas del observer de Telegram.
"""

import pytest
import yaml
from pathlib import Path
from goals.scripts.observer_telegram import TelegramObserver


@pytest.fixture
def observer_config(tmp_path):
    config = {
        "telegram": {"bot_token": "test", "chat_id": "123", "enabled": False},
        "poll_interval_seconds": 60,
        "notify": {"goal_started": True, "goal_completed": True},
        "commands_enabled": False,
        "state_file": str(tmp_path / "state.json")
    }
    p = tmp_path / "config.yaml"
    p.write_text(yaml.dump(config))
    return str(p)


def test_observer_starts_disabled(observer_config):
    obs = TelegramObserver(observer_config)
    assert obs.enabled is False


def test_send_message_disabled(observer_config, caplog):
    obs = TelegramObserver(observer_config)
    obs.send_message("test message")
    assert "test message" in caplog.text


def test_detect_events_goal_completed(observer_config):
    obs = TelegramObserver(observer_config)
    prev = {"goal-001": {"status": "active", "goal_id": "goal-001", "objective": "Test"}}
    curr = {"goal-001": {"status": "complete", "goal_id": "goal-001", "objective": "Test", "tokens_used": 100, "time_used_seconds": 60}}
    obs.previous_state = prev
    events = obs.detect_events(curr)
    assert len(events) >= 1
    assert any("completada" in e.lower() for e in events)


def test_detect_events_goal_started(observer_config):
    obs = TelegramObserver(observer_config)
    prev = {}
    curr = {"goal-002": {"status": "active", "goal_id": "goal-002", "objective": "Nueva meta", "assigned_agent": "test"}}
    obs.previous_state = prev
    events = obs.detect_events(curr)
    assert len(events) >= 1
    assert any("iniciada" in e.lower() for e in events)
