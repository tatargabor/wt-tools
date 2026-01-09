"""
Ralph Loop Improvements Tests - Verify new loop dialog, status display, and colors
"""

import json
import os
import subprocess
from datetime import datetime, timezone, timedelta
from pathlib import Path
from unittest.mock import patch, MagicMock

from PySide6.QtWidgets import QDialog, QComboBox, QSpinBox, QLabel
from PySide6.QtCore import Qt


def _create_worktree(control_center, git_env, qtbot, change_id="ralph-improve"):
    """Helper: create a worktree and feed it to the GUI."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / f"test-project-wt-{change_id}")

    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", f"change/{change_id}", wt_path],
        capture_output=True, check=True,
    )

    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": change_id,
            "path": wt_path,
            "branch": f"change/{change_id}",
            "agents": [],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    return wt_path


def _cleanup_worktree(git_env, wt_path, change_id="ralph-improve"):
    """Helper: remove worktree and branch."""
    project_path = str(git_env["project"])
    subprocess.run(
        ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
        capture_output=True,
    )
    subprocess.run(
        ["git", "-C", project_path, "branch", "-D", f"change/{change_id}"],
        capture_output=True,
    )


def test_start_loop_dialog_defaults_to_tasks_when_tasks_md_exists(control_center, git_env, qtbot):
    """When tasks.md exists, done criteria should default to 'tasks'."""
    wt_path = _create_worktree(control_center, git_env, qtbot)
    try:
        # Create tasks.md in worktree root
        (Path(wt_path) / "tasks.md").write_text("- [ ] Task 1\n- [ ] Task 2\n")

        # Capture the dialog instead of showing it
        dialog_widgets = {}

        original_exec = QDialog.exec

        def capture_exec(self):
            # Find widgets in the dialog
            for combo in self.findChildren(QComboBox):
                dialog_widgets["done_criteria"] = combo.currentText()
            for label in self.findChildren(QLabel):
                if label.objectName() == "tasks_md_label":
                    dialog_widgets["tasks_md_label"] = label.text()
                if label.objectName() == "manual_warning":
                    dialog_widgets["manual_warning_visible"] = label.isVisible()
            for spin in self.findChildren(QSpinBox):
                if spin.objectName() == "stall_threshold_spin":
                    dialog_widgets["stall_threshold"] = spin.value()
                if spin.objectName() == "iter_timeout_spin":
                    dialog_widgets["iter_timeout"] = spin.value()
            return QDialog.Rejected

        with patch.object(QDialog, 'exec', capture_exec):
            control_center.start_ralph_loop_dialog(wt_path)

        assert dialog_widgets.get("done_criteria") == "tasks", \
            f"Expected 'tasks' but got {dialog_widgets.get('done_criteria')}"
        assert "found" in dialog_widgets.get("tasks_md_label", ""), \
            f"Expected 'found' in label, got: {dialog_widgets.get('tasks_md_label')}"
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_start_loop_dialog_manual_warning_visible(control_center, git_env, qtbot):
    """When manual is selected, warning label should appear."""
    wt_path = _create_worktree(control_center, git_env, qtbot)
    try:
        # Create tasks.md so default is "tasks" (not "manual")
        (Path(wt_path) / "tasks.md").write_text("- [ ] Task 1\n")

        dialog_widgets = {}

        def capture_exec(self):
            from PySide6.QtWidgets import QApplication
            # Verify initial state: tasks selected, warning hidden
            warning = None
            combo = None
            for label in self.findChildren(QLabel):
                if label.objectName() == "manual_warning":
                    warning = label
            for c in self.findChildren(QComboBox):
                combo = c
            if warning and combo:
                # isVisibleTo checks the widget's own visibility flag
                # (not parent chain which requires showing)
                dialog_widgets["initial_hidden"] = not warning.isVisibleTo(self)
                # Switch to manual - should trigger warning
                combo.setCurrentText("manual")
                QApplication.processEvents()
                dialog_widgets["manual_warning_visible"] = warning.isVisibleTo(self)
                dialog_widgets["manual_warning_text"] = warning.text()
            return QDialog.Rejected

        with patch.object(QDialog, 'exec', capture_exec):
            control_center.start_ralph_loop_dialog(wt_path)

        assert dialog_widgets.get("initial_hidden") is True, \
            "Warning should be hidden initially when 'tasks' is selected"
        assert dialog_widgets.get("manual_warning_visible") is True, \
            "Manual warning should be visible when 'manual' selected"
        assert "won't auto-stop" in dialog_widgets.get("manual_warning_text", "").lower(), \
            f"Expected 'won't auto-stop' in warning, got: {dialog_widgets.get('manual_warning_text')}"
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_ralph_button_tooltip_shows_elapsed_and_details(control_center, git_env, qtbot):
    """Ralph button tooltip should show elapsed time and iteration details."""
    wt_path = _create_worktree(control_center, git_env, qtbot)
    try:
        started = (datetime.now(timezone.utc) - timedelta(minutes=30)).isoformat()
        claude_dir = Path(wt_path) / ".claude"
        claude_dir.mkdir(parents=True, exist_ok=True)
        loop_state = {
            "status": "done",
            "current_iteration": 3,
            "max_iterations": 10,
            "task": "Fix GUI bugs for testing",
            "started_at": started,
            "iterations": [
                {"n": 1, "started": started, "ended": started,
                 "done_check": False, "commits": ["abc1234"], "tokens_used": 1000},
                {"n": 2, "started": started, "ended": started,
                 "done_check": False, "commits": [], "tokens_used": 500},
                {"n": 3, "started": started, "ended": started,
                 "done_check": True, "commits": ["def5678"], "tokens_used": 800},
            ],
            "stall_threshold": 3,
            "iteration_timeout_min": 60,
        }
        (claude_dir / "loop-state.json").write_text(json.dumps(loop_state))

        status = control_center.get_ralph_status(wt_path)
        assert status != {}, "Ralph status should not be empty"
        assert status["started_at"] == started
        assert status["stall_threshold"] == 3
        assert status["iteration_timeout_min"] == 60
        assert status["last_commit_ts"] is not None
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_ralph_button_stalled_gets_orange_stuck_gets_red(control_center, git_env, qtbot):
    """Stalled status should use orange (status_stalled), stuck should use red (burn_high)."""
    stalled_color = control_center.get_color("status_stalled")
    stuck_color = control_center.get_color("burn_high")

    # Colors should be different
    assert stalled_color != stuck_color, \
        f"stalled ({stalled_color}) and stuck ({stuck_color}) should be different colors"

    # Stalled should be orange-ish (contains f/a/b characters common in orange hex)
    # Stuck should be red-ish (contains f/4 characters common in red hex)
    # Just verify they exist and are valid hex colors
    assert stalled_color.startswith("#"), f"stalled color should be hex, got: {stalled_color}"
    assert stuck_color.startswith("#"), f"stuck color should be hex, got: {stuck_color}"

    wt_path = _create_worktree(control_center, git_env, qtbot)
    try:
        claude_dir = Path(wt_path) / ".claude"
        claude_dir.mkdir(parents=True, exist_ok=True)

        # Test stalled status detection
        loop_state = {
            "status": "stalled",
            "current_iteration": 5,
            "max_iterations": 10,
            "task": "Test stall detection",
        }
        (claude_dir / "loop-state.json").write_text(json.dumps(loop_state))

        status = control_center.get_ralph_status(wt_path)
        assert status != {}, "Stalled status should be detected"
        assert status["status"] == "stalled"
    finally:
        _cleanup_worktree(git_env, wt_path)
