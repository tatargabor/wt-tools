"""
Ralph Loop Tests - Verify Ralph loop status detection and context menu items
"""

import json
import subprocess
from pathlib import Path

from PySide6.QtWidgets import QMenu


class _MenuCapture:
    """Context manager that intercepts QMenu.exec to prevent blocking."""

    def __init__(self):
        self.menus = []
        self._original_init = None

    def __enter__(self):
        self._original_init = QMenu.__init__
        capture = self
        original_init = self._original_init

        def patched_init(menu_self, *args, **kwargs):
            original_init(menu_self, *args, **kwargs)

            def non_blocking_exec(*a, **kw):
                all_actions = []
                for act in menu_self.actions():
                    if act.isSeparator():
                        continue
                    submenu = act.menu()
                    if submenu:
                        sub_actions = [sa.text() for sa in submenu.actions() if not sa.isSeparator()]
                        all_actions.append({"text": act.text(), "submenu": sub_actions})
                    else:
                        all_actions.append({"text": act.text(), "submenu": None})
                capture.menus.append(all_actions)
                return None

            menu_self.exec = non_blocking_exec

        QMenu.__init__ = patched_init
        return self

    def __exit__(self, *args):
        QMenu.__init__ = self._original_init

    def find_submenu(self, title):
        """Find a submenu by title in the last captured menu."""
        if not self.menus:
            return None
        for item in self.menus[-1]:
            if title in item["text"] and item["submenu"] is not None:
                return item["submenu"]
        return None


def _create_worktree_with_status(control_center, git_env, qtbot, change_id="ralph-test"):
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


def _cleanup_worktree(git_env, wt_path, change_id="ralph-test"):
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


def test_ralph_status_idle_when_no_loop(control_center, git_env, qtbot):
    """Without loop-state.json, ralph status should be empty/idle."""
    wt_path = _create_worktree_with_status(control_center, git_env, qtbot)
    try:
        status = control_center.get_ralph_status(wt_path)
        assert status == {} or status.get("active") is False
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_ralph_loop_context_menu_shows_start(control_center, git_env, qtbot):
    """When no loop is running, Ralph Loop submenu should show 'Start Loop...'."""
    wt_path = _create_worktree_with_status(control_center, git_env, qtbot)
    try:
        # Find the worktree row
        wt_row = None
        for row, wt in control_center.row_to_worktree.items():
            if wt.get("change_id") == "ralph-test":
                wt_row = row
                break
        assert wt_row is not None, "Worktree row not found"

        with _MenuCapture() as cap:
            row_rect = control_center.table.visualRect(
                control_center.table.model().index(wt_row, 0)
            )
            control_center.show_row_context_menu(row_rect.center())

        ralph_items = cap.find_submenu("Ralph Loop")
        assert ralph_items is not None, "Ralph Loop submenu not found"
        assert "Start Loop..." in ralph_items
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_ralph_loop_state_file_detected(control_center, git_env, qtbot):
    """With a loop-state.json, ralph status should be detected."""
    wt_path = _create_worktree_with_status(control_center, git_env, qtbot)
    try:
        # Create a fake loop-state.json
        claude_dir = Path(wt_path) / ".claude"
        claude_dir.mkdir(parents=True, exist_ok=True)
        loop_state = {
            "status": "done",
            "current_iteration": 5,
            "max_iterations": 10,
            "task": "Fix GUI bugs",
        }
        (claude_dir / "loop-state.json").write_text(json.dumps(loop_state))

        status = control_center.get_ralph_status(wt_path)
        assert status != {}, "Ralph status should not be empty"
        assert status["status"] == "done"
        assert status["iteration"] == 5
        assert status["max_iterations"] == 10
        assert status["active"] is False  # done is not active
    finally:
        _cleanup_worktree(git_env, wt_path)


def test_ralph_loop_context_menu_shows_stop_when_running(control_center, git_env, qtbot):
    """With an active loop, Ralph Loop submenu should show 'Stop Loop'."""
    import os

    wt_path = _create_worktree_with_status(control_center, git_env, qtbot)
    try:
        # Create loop-state.json with running status and our own PID (so os.kill check passes)
        claude_dir = Path(wt_path) / ".claude"
        claude_dir.mkdir(parents=True, exist_ok=True)
        loop_state = {
            "status": "running",
            "current_iteration": 3,
            "max_iterations": 10,
            "task": "Fix bugs",
            "terminal_pid": os.getpid(),  # Use our own PID so it passes the alive check
        }
        (claude_dir / "loop-state.json").write_text(json.dumps(loop_state))

        # Verify status detection
        status = control_center.get_ralph_status(wt_path)
        assert status.get("active") is True
        assert status["status"] == "running"

        # Find worktree row
        wt_row = None
        for row, wt in control_center.row_to_worktree.items():
            if wt.get("change_id") == "ralph-test":
                wt_row = row
                break
        assert wt_row is not None

        with _MenuCapture() as cap:
            row_rect = control_center.table.visualRect(
                control_center.table.model().index(wt_row, 0)
            )
            control_center.show_row_context_menu(row_rect.center())

        ralph_items = cap.find_submenu("Ralph Loop")
        assert ralph_items is not None, "Ralph Loop submenu not found"
        assert "Stop Loop" in ralph_items
        # Also should show status line
        has_status = any("Status:" in item for item in ralph_items)
        assert has_status, f"Expected status line in Ralph menu, got: {ralph_items}"
    finally:
        _cleanup_worktree(git_env, wt_path)
