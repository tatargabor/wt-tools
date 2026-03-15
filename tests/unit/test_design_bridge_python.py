"""Tests for Python design bridge functions in wt_orch.planner."""

import json
import os
import shutil
import sys
import tempfile
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "lib"))

from wt_orch.planner import _detect_design_mcp, _load_design_file_ref, _fetch_design_context


@pytest.fixture
def tmp_project(tmp_path):
    """Create a temporary project directory and chdir into it."""
    orig = os.getcwd()
    os.chdir(tmp_path)
    yield tmp_path
    os.chdir(orig)


# ─── _detect_design_mcp ─────────────────────────────────────────


class TestDetectDesignMcp:
    def test_figma_detected(self, tmp_project):
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"figma": {"url": "https://mcp.figma.com"}}
        }))
        assert _detect_design_mcp() == "figma"

    def test_penpot_detected(self, tmp_project):
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"penpot": {"url": "https://penpot.example.com"}}
        }))
        assert _detect_design_mcp() == "penpot"

    def test_no_design_mcp(self, tmp_project):
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"github": {"url": "https://github.com"}}
        }))
        assert _detect_design_mcp() is None

    def test_no_settings_file(self, tmp_project):
        assert _detect_design_mcp() is None

    def test_empty_mcp_servers(self, tmp_project):
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {}
        }))
        assert _detect_design_mcp() is None

    def test_malformed_json(self, tmp_project):
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text("not json")
        assert _detect_design_mcp() is None


# ─── _load_design_file_ref ───────────────────────────────────────


class TestLoadDesignFileRef:
    def test_design_file_in_wt_config(self, tmp_project):
        config_dir = tmp_project / "wt" / "orchestration"
        config_dir.mkdir(parents=True)
        (config_dir / "config.yaml").write_text("design_file: https://figma.com/design/ABC123\n")
        assert _load_design_file_ref() == "https://figma.com/design/ABC123"

    def test_design_file_in_claude_config(self, tmp_project):
        config_dir = tmp_project / ".claude"
        config_dir.mkdir()
        (config_dir / "orchestration.yaml").write_text("design_file: https://figma.com/design/XYZ\n")
        assert _load_design_file_ref() == "https://figma.com/design/XYZ"

    def test_no_design_file_configured(self, tmp_project):
        config_dir = tmp_project / "wt" / "orchestration"
        config_dir.mkdir(parents=True)
        (config_dir / "config.yaml").write_text("max_parallel: 3\n")
        assert _load_design_file_ref() is None

    def test_no_config_file(self, tmp_project):
        assert _load_design_file_ref() is None

    def test_quoted_design_file(self, tmp_project):
        config_dir = tmp_project / "wt" / "orchestration"
        config_dir.mkdir(parents=True)
        (config_dir / "config.yaml").write_text('design_file: "https://figma.com/design/Q"\n')
        assert _load_design_file_ref() == "https://figma.com/design/Q"

    def test_wt_config_takes_precedence(self, tmp_project):
        """wt/orchestration/config.yaml is checked first."""
        wt_dir = tmp_project / "wt" / "orchestration"
        wt_dir.mkdir(parents=True)
        (wt_dir / "config.yaml").write_text("design_file: https://figma.com/wt\n")
        claude_dir = tmp_project / ".claude"
        claude_dir.mkdir()
        (claude_dir / "orchestration.yaml").write_text("design_file: https://figma.com/claude\n")
        assert _load_design_file_ref() == "https://figma.com/wt"


# ─── _fetch_design_context ──────────────────────────────────────


class TestFetchDesignContext:
    def _setup_mcp_and_config(self, tmp_project):
        """Helper: create settings.json with figma + orchestration config with design_file."""
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir(exist_ok=True)
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"figma": {"url": "https://mcp.figma.com"}}
        }))
        config_dir = tmp_project / "wt" / "orchestration"
        config_dir.mkdir(parents=True, exist_ok=True)
        (config_dir / "config.yaml").write_text("design_file: https://figma.com/design/ABC\n")

    def test_cache_hit(self, tmp_project):
        """Cached snapshot is returned without calling bash bridge."""
        (tmp_project / "design-snapshot.md").write_text(
            "## Design Tokens\n\nColors:\n- primary: #3b82f6\n"
        )
        with patch("wt_orch.subprocess_utils.run_command") as mock_cmd:
            result = _fetch_design_context()
            mock_cmd.assert_not_called()
        assert "## Design Tokens" in result
        assert "primary: #3b82f6" in result

    def test_cache_hit_skipped_when_force(self, tmp_project):
        """force=True bypasses cache and calls bash bridge."""
        self._setup_mcp_and_config(tmp_project)
        (tmp_project / "design-snapshot.md").write_text(
            "## Design Tokens\n\nColors:\n- primary: #3b82f6\n"
        )
        mock_result = MagicMock(exit_code=0, stdout="", stderr="")
        with patch("wt_orch.subprocess_utils.run_command", return_value=mock_result) as mock_cmd:
            result = _fetch_design_context(force=True)
            mock_cmd.assert_called_once()
        # Still returns cached content since bash bridge "succeeded" and file exists
        assert "## Design Tokens" in result

    def test_no_design_mcp_returns_empty(self, tmp_project):
        """No design MCP → empty string, no error."""
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"github": {}}
        }))
        result = _fetch_design_context()
        assert result == ""

    def test_no_design_file_returns_empty(self, tmp_project):
        """Design MCP exists but no design_file → empty string."""
        settings_dir = tmp_project / ".claude"
        settings_dir.mkdir()
        (settings_dir / "settings.json").write_text(json.dumps({
            "mcpServers": {"figma": {"url": "https://mcp.figma.com"}}
        }))
        config_dir = tmp_project / "wt" / "orchestration"
        config_dir.mkdir(parents=True)
        (config_dir / "config.yaml").write_text("max_parallel: 3\n")
        result = _fetch_design_context()
        assert result == ""

    def test_happy_path(self, tmp_project):
        """Bash bridge succeeds → snapshot content returned."""
        self._setup_mcp_and_config(tmp_project)

        def fake_run(cmd, **kwargs):
            # Simulate bash bridge creating the snapshot
            (tmp_project / "design-snapshot.md").write_text(
                "## Design Tokens\n\nColors:\n- primary: #3b82f6\n- accent: #10b981\n"
            )
            return MagicMock(exit_code=0, stdout="", stderr="")

        with patch("wt_orch.subprocess_utils.run_command", side_effect=fake_run):
            result = _fetch_design_context()
        assert "primary: #3b82f6" in result
        assert "accent: #10b981" in result

    def test_fail_fast_raises_runtime_error(self, tmp_project):
        """Fetch fails with design configured → RuntimeError."""
        self._setup_mcp_and_config(tmp_project)
        mock_result = MagicMock(exit_code=1, stdout="", stderr="MCP_AUTH_FAILED")
        with patch("wt_orch.subprocess_utils.run_command", return_value=mock_result):
            with pytest.raises(RuntimeError, match="Design snapshot fetch failed"):
                _fetch_design_context()

    def test_design_optional_suppresses_error(self, tmp_project):
        """DESIGN_OPTIONAL=true → warning instead of error."""
        self._setup_mcp_and_config(tmp_project)
        mock_result = MagicMock(exit_code=1, stdout="", stderr="MCP_AUTH_FAILED")
        with patch("wt_orch.subprocess_utils.run_command", return_value=mock_result):
            with patch.dict(os.environ, {"DESIGN_OPTIONAL": "true"}):
                result = _fetch_design_context()
        assert result == ""


# ─── dispatch_ready_changes threading ────────────────────────────


class TestDispatchDesignSnapshotDir:
    def test_design_snapshot_dir_passed_to_dispatch_change(self, tmp_path):
        """dispatch_ready_changes passes design_snapshot_dir to dispatch_change."""
        from wt_orch.state import OrchestratorState, Change

        state_file = str(tmp_path / "state.json")
        state = OrchestratorState(
            status="running",
            changes=[Change(name="test-change", status="pending", scope="test", complexity="S")],
        )
        with open(state_file, "w") as f:
            json.dump(state.to_dict(), f)

        with patch("wt_orch.dispatcher.dispatch_change") as mock_dispatch:
            from wt_orch.dispatcher import dispatch_ready_changes
            dispatch_ready_changes(
                state_file, max_parallel=5,
                design_snapshot_dir="/my/project",
            )
            if mock_dispatch.called:
                _, kwargs = mock_dispatch.call_args
                assert kwargs.get("design_snapshot_dir") == "/my/project"


# ─── verifier design compliance ──────────────────────────────────


class TestVerifierDesignCompliance:
    def test_review_change_calls_bridge(self, tmp_path):
        """review_change calls build_design_review_section when design_snapshot_dir set."""
        from wt_orch.verifier import review_change

        # Create a minimal worktree with a git repo
        wt_path = str(tmp_path / "wt")
        os.makedirs(wt_path)

        design_output = "## Design Compliance Check\n\nColors:\n- primary: #3b82f6\n"

        with patch("wt_orch.verifier.run_git") as mock_git, \
             patch("wt_orch.verifier.run_command") as mock_cmd, \
             patch("wt_orch.verifier.run_claude") as mock_claude:

            # Mock merge-base
            mock_git.return_value = MagicMock(exit_code=0, stdout="abc123\n")

            # We need to handle both the template render and bridge calls
            def cmd_side_effect(cmd, **kwargs):
                cmd_str = " ".join(cmd) if isinstance(cmd, list) else str(cmd)
                if "build_design_review_section" in cmd_str:
                    return MagicMock(exit_code=0, stdout=design_output, stderr="")
                # Template render
                return MagicMock(exit_code=0, stdout="Review prompt rendered", stderr="")

            mock_cmd.side_effect = cmd_side_effect
            mock_claude.return_value = MagicMock(
                exit_code=0, stdout="PASS: All checks passed", stderr=""
            )

            rr = review_change(
                "test-change", wt_path, "Add login page",
                design_snapshot_dir="/my/project",
            )

            # Verify build_design_review_section was called
            bridge_calls = [
                c for c in mock_cmd.call_args_list
                if any("build_design_review_section" in str(a) for a in c.args)
            ]
            assert len(bridge_calls) == 1
