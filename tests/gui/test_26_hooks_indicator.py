"""
Hooks Indicator Tests - Verify hook warning tooltip and Install Hooks context menu
"""

import subprocess

from PySide6.QtCore import QPoint
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
                actions = [act.text() for act in menu_self.actions() if not act.isSeparator()]
                capture.menus.append({
                    "menu": menu_self,
                    "actions": actions,
                })
                return None

            menu_self.exec = non_blocking_exec

        QMenu.__init__ = patched_init
        return self

    def __exit__(self, *args):
        QMenu.__init__ = self._original_init

    @property
    def last_actions(self):
        return self.menus[-1]["actions"] if self.menus else []


def _feed_status(control_center, qtbot, wt_path, hooks_installed):
    """Feed worktree status data with specific hooks_installed value."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "hooks-test",
            "path": wt_path,
            "branch": "change/hooks-test",
            "agents": [],
            "hooks_installed": hooks_installed,
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)


def _find_worktree_row(control_center, change_id="hooks-test"):
    """Find the table row for a worktree by change_id."""
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == change_id:
            return row
    return None


def test_hooks_warning_tooltip_when_missing(control_center, git_env, qtbot):
    """When hooks_installed is false, status cell should have warning tooltip."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / "test-project-wt-hooks-test")

    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", "change/hooks-test", wt_path],
        capture_output=True, check=True,
    )

    try:
        _feed_status(control_center, qtbot, wt_path, hooks_installed=False)

        wt_row = _find_worktree_row(control_center)
        assert wt_row is not None, "Worktree row not found"

        # Check status cell has visible warning indicator and tooltip
        from gui.control_center.mixins.table import COL_STATUS
        status_item = control_center.table.item(wt_row, COL_STATUS)
        assert status_item is not None
        assert "\u26a0" in status_item.text(), f"Expected ⚠ in status text, got: {status_item.text()!r}"
        tooltip = status_item.toolTip()
        assert "hooks" in tooltip.lower(), f"Expected hooks warning in tooltip, got: {tooltip!r}"
    finally:
        subprocess.run(
            ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", project_path, "branch", "-D", "change/hooks-test"],
            capture_output=True,
        )


def test_no_hooks_tooltip_when_installed(control_center, git_env, qtbot):
    """When hooks_installed is true, status cell should NOT have hooks warning tooltip."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / "test-project-wt-hooks-test")

    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", "change/hooks-test", wt_path],
        capture_output=True, check=True,
    )

    try:
        _feed_status(control_center, qtbot, wt_path, hooks_installed=True)

        wt_row = _find_worktree_row(control_center)
        assert wt_row is not None, "Worktree row not found"

        from gui.control_center.mixins.table import COL_STATUS
        status_item = control_center.table.item(wt_row, COL_STATUS)
        assert status_item is not None
        assert "\u26a0" not in status_item.text(), f"Should not have ⚠ in status text, got: {status_item.text()!r}"
        tooltip = status_item.toolTip()
        assert "hooks" not in tooltip.lower(), f"Should not have hooks warning, got: {tooltip!r}"
    finally:
        subprocess.run(
            ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", project_path, "branch", "-D", "change/hooks-test"],
            capture_output=True,
        )


def test_install_hooks_in_context_menu_when_missing(control_center, git_env, qtbot):
    """Context menu should show 'Install Hooks' when hooks_installed is false."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / "test-project-wt-hooks-test")

    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", "change/hooks-test", wt_path],
        capture_output=True, check=True,
    )

    try:
        _feed_status(control_center, qtbot, wt_path, hooks_installed=False)

        wt_row = _find_worktree_row(control_center)
        assert wt_row is not None, "Worktree row not found"

        with _MenuCapture() as cap:
            row_rect = control_center.table.visualRect(
                control_center.table.model().index(wt_row, 0)
            )
            control_center.show_row_context_menu(row_rect.center())

        assert len(cap.menus) > 0, "Context menu was not created"
        assert "Install Hooks" in cap.last_actions, f"Expected 'Install Hooks' in menu, got: {cap.last_actions}"
    finally:
        subprocess.run(
            ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", project_path, "branch", "-D", "change/hooks-test"],
            capture_output=True,
        )


def test_no_install_hooks_in_context_menu_when_installed(control_center, git_env, qtbot):
    """Context menu should NOT show 'Install Hooks' when hooks_installed is true."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / "test-project-wt-hooks-test")

    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", "change/hooks-test", wt_path],
        capture_output=True, check=True,
    )

    try:
        _feed_status(control_center, qtbot, wt_path, hooks_installed=True)

        wt_row = _find_worktree_row(control_center)
        assert wt_row is not None, "Worktree row not found"

        with _MenuCapture() as cap:
            row_rect = control_center.table.visualRect(
                control_center.table.model().index(wt_row, 0)
            )
            control_center.show_row_context_menu(row_rect.center())

        assert len(cap.menus) > 0, "Context menu was not created"
        assert "Install Hooks" not in cap.last_actions, f"'Install Hooks' should NOT be in menu when hooks installed, got: {cap.last_actions}"
    finally:
        subprocess.run(
            ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", project_path, "branch", "-D", "change/hooks-test"],
            capture_output=True,
        )
