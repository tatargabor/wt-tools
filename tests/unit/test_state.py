"""Tests for wt_orch.state — Typed JSON state management."""

import json
import os
import sys
import tempfile

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "lib"))

from wt_orch.state import (
    Change,
    OrchestratorState,
    StateCorruptionError,
    TokenStats,
    WatchdogState,
    aggregate_tokens,
    init_state,
    load_state,
    query_changes,
    save_state,
)


SAMPLE_PLAN = {
    "plan_version": 2,
    "brief_hash": "abc123",
    "plan_phase": "initial",
    "plan_method": "api",
    "changes": [
        {
            "name": "add-auth",
            "scope": "Add authentication",
            "complexity": "L",
            "change_type": "feature",
            "depends_on": [],
            "roadmap_item": "Auth system",
            "requirements": ["REQ-AUTH-01"],
        },
        {
            "name": "fix-login",
            "scope": "Fix login bug",
            "complexity": "S",
            "change_type": "bugfix",
            "depends_on": ["add-auth"],
            "roadmap_item": "Login fixes",
        },
    ],
}


@pytest.fixture
def tmp_dir():
    d = tempfile.mkdtemp()
    yield d
    import shutil
    shutil.rmtree(d, ignore_errors=True)


@pytest.fixture
def plan_file(tmp_dir):
    path = os.path.join(tmp_dir, "plan.json")
    with open(path, "w") as f:
        json.dump(SAMPLE_PLAN, f)
    return path


@pytest.fixture
def state_file(tmp_dir, plan_file):
    path = os.path.join(tmp_dir, "state.json")
    init_state(plan_file, path)
    return path


class TestLoadState:
    def test_loads_valid_state(self, state_file):
        state = load_state(state_file)
        assert state.status == "running"
        assert len(state.changes) == 2
        assert state.plan_version == 2
        assert state.brief_hash == "abc123"

    def test_rejects_corrupt_json(self, tmp_dir):
        path = os.path.join(tmp_dir, "corrupt.json")
        with open(path, "w") as f:
            f.write("NOT VALID JSON {{{")
        with pytest.raises(StateCorruptionError, match="invalid JSON"):
            load_state(path)

    def test_rejects_empty_file(self, tmp_dir):
        path = os.path.join(tmp_dir, "empty.json")
        with open(path, "w") as f:
            f.write("")
        with pytest.raises(StateCorruptionError, match="empty"):
            load_state(path)

    def test_rejects_missing_changes(self, tmp_dir):
        path = os.path.join(tmp_dir, "nochanges.json")
        with open(path, "w") as f:
            json.dump({"status": "running"}, f)
        with pytest.raises(StateCorruptionError, match="missing required field: changes"):
            load_state(path)

    def test_rejects_nonexistent_file(self):
        with pytest.raises(StateCorruptionError, match="cannot read file"):
            load_state("/nonexistent/path/state.json")

    def test_preserves_unknown_fields(self, tmp_dir):
        path = os.path.join(tmp_dir, "extra.json")
        data = {
            "status": "running",
            "changes": [],
            "custom_field": "hello",
            "directives": {"test_command": "npm test"},
        }
        with open(path, "w") as f:
            json.dump(data, f)

        state = load_state(path)
        assert state.extras["custom_field"] == "hello"
        assert state.extras["directives"] == {"test_command": "npm test"}


class TestSaveState:
    def test_save_load_roundtrip(self, state_file):
        state = load_state(state_file)
        state.changes[0].status = "running"
        state.changes[0].tokens_used = 5000

        save_state(state, state_file)
        state2 = load_state(state_file)

        assert state2.changes[0].status == "running"
        assert state2.changes[0].tokens_used == 5000
        assert state2.changes[1].status == "pending"

    def test_atomic_write(self, tmp_dir):
        path = os.path.join(tmp_dir, "atomic.json")
        state = OrchestratorState(status="running", changes=[])
        save_state(state, path)
        assert os.path.exists(path)
        # No .tmp files left behind
        tmp_files = [f for f in os.listdir(tmp_dir) if f.endswith(".tmp")]
        assert tmp_files == []

    def test_preserves_extras_on_roundtrip(self, tmp_dir):
        path = os.path.join(tmp_dir, "extras.json")
        state = OrchestratorState(
            status="running",
            changes=[Change(name="test", extras={"smoke_status": "pass"})],
            extras={"directives": {"max_parallel": 3}},
        )
        save_state(state, path)
        state2 = load_state(path)
        assert state2.extras["directives"] == {"max_parallel": 3}
        assert state2.changes[0].extras["smoke_status"] == "pass"


class TestInitState:
    def test_creates_state_from_plan(self, plan_file, tmp_dir):
        out = os.path.join(tmp_dir, "out.json")
        init_state(plan_file, out)

        state = load_state(out)
        assert state.status == "running"
        assert state.plan_version == 2
        assert len(state.changes) == 2

        auth = state.changes[0]
        assert auth.name == "add-auth"
        assert auth.status == "pending"
        assert auth.tokens_used == 0
        assert auth.ralph_pid is None
        assert auth.requirements == ["REQ-AUTH-01"]

        fix = state.changes[1]
        assert fix.name == "fix-login"
        assert fix.depends_on == ["add-auth"]
        assert fix.requirements is None  # not in plan

    def test_plan_defaults(self, tmp_dir):
        plan = {"changes": [{"name": "minimal"}]}
        plan_path = os.path.join(tmp_dir, "minimal.json")
        with open(plan_path, "w") as f:
            json.dump(plan, f)

        out = os.path.join(tmp_dir, "out.json")
        init_state(plan_path, out)

        state = load_state(out)
        assert state.plan_version == 1
        assert state.plan_phase == "initial"
        c = state.changes[0]
        assert c.complexity == "M"
        assert c.change_type == "feature"


class TestQueryChanges:
    def test_filter_by_status(self, state_file):
        state = load_state(state_file)
        state.changes[0].status = "running"

        running = query_changes(state, status="running")
        assert len(running) == 1
        assert running[0].name == "add-auth"

        pending = query_changes(state, status="pending")
        assert len(pending) == 1
        assert pending[0].name == "fix-login"

    def test_no_filter_returns_all(self, state_file):
        state = load_state(state_file)
        all_changes = query_changes(state)
        assert len(all_changes) == 2

    def test_empty_result(self, state_file):
        state = load_state(state_file)
        result = query_changes(state, status="merged")
        assert result == []


class TestAggregateTokens:
    def test_aggregates_across_changes(self):
        state = OrchestratorState(changes=[
            Change(name="a", tokens_used=1000, input_tokens=500, output_tokens=300,
                   cache_read_tokens=100, cache_create_tokens=100),
            Change(name="b", tokens_used=2000, input_tokens=1000, output_tokens=600,
                   cache_read_tokens=200, cache_create_tokens=200),
        ])
        stats = aggregate_tokens(state)
        assert stats.total == 3000
        assert stats.input_total == 1500
        assert stats.output_total == 900
        assert stats.cache_read_total == 300
        assert stats.cache_create_total == 300

    def test_empty_changes(self):
        state = OrchestratorState(changes=[])
        stats = aggregate_tokens(state)
        assert stats.total == 0


class TestWatchdogState:
    def test_from_dict_roundtrip(self):
        data = {
            "last_activity_epoch": 1710000000,
            "action_hash_ring": ["abc", "def"],
            "consecutive_same_hash": 3,
            "escalation_level": 1,
            "progress_baseline": 5,
            "custom_field": "extra",
        }
        wd = WatchdogState.from_dict(data)
        assert wd.last_activity_epoch == 1710000000
        assert wd.action_hash_ring == ["abc", "def"]
        assert wd.extras["custom_field"] == "extra"

        d = wd.to_dict()
        assert d["custom_field"] == "extra"
        assert d["consecutive_same_hash"] == 3
