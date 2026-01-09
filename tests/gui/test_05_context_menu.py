"""
Context Menu Tests - Verify right-click menus on window and rows
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
            original_exec = menu_self.exec

            def non_blocking_exec(*a, **kw):
                actions = [act.text() for act in menu_self.actions() if not act.isSeparator()]
                submenus = [act.text() for act in menu_self.actions() if act.menu()]
                capture.menus.append({
                    "menu": menu_self,
                    "actions": actions,
                    "submenus": submenus,
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

    @property
    def last_submenus(self):
        return self.menus[-1]["submenus"] if self.menus else []


def test_window_right_click_menu(control_center, qtbot):
    """Right-clicking on the window should show context menu with expected items."""
    with _MenuCapture() as cap:
        control_center.show_context_menu(QPoint(50, 50))

    assert len(cap.menus) > 0, "Context menu was not created"
    actions = cap.last_actions
    assert "+ New Worktree" in actions
    assert "Work..." in actions
    assert "↻ Refresh" in actions
    assert "Minimize to Tray" in actions
    assert "Restart" in actions
    assert "Quit" in actions


def test_row_right_click_menu_on_empty(control_center, qtbot):
    """Right-click on empty table area should not crash."""
    # With no worktrees, clicking in the table area should be harmless
    with _MenuCapture() as cap:
        control_center.show_row_context_menu(QPoint(50, 50))
    # No assertion needed - just verifying no crash


def test_row_right_click_menu_with_worktree(control_center, git_env, qtbot):
    """Right-click on a worktree row should show row context menu."""
    project_path = str(git_env["project"])
    wt_path = str(git_env["base"] / "test-project-wt-ctx-test")

    # Create a worktree directly with git
    subprocess.run(
        ["git", "-C", project_path, "worktree", "add", "-b", "change/ctx-test", wt_path],
        capture_output=True, check=True,
    )

    try:
        # Feed status data to GUI
        status_data = {
            "worktrees": [{
                "project": "test-project",
                "change_id": "ctx-test",
                "path": wt_path,
                "branch": "change/ctx-test",
                "agents": [],
                "git": {"last_commit": 0, "uncommitted_changes": False},
            }],
            "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
        }
        control_center.update_status(status_data)
        qtbot.wait(200)

        # Find the worktree row
        wt_row = None
        for row, wt in control_center.row_to_worktree.items():
            if wt.get("change_id") == "ctx-test":
                wt_row = row
                break

        assert wt_row is not None, "Worktree row not found in table"

        with _MenuCapture() as cap:
            row_rect = control_center.table.visualRect(
                control_center.table.model().index(wt_row, 0)
            )
            control_center.show_row_context_menu(row_rect.center())

        assert len(cap.menus) > 0, "Row context menu was not created"
        actions = cap.last_actions
        assert "Focus Window" in actions
        assert "Close Editor" in actions
        assert "Open in Terminal" in actions
        assert "Copy Path" in actions
        # Submenus show their title in actions list
        assert "Git" in actions or any("Git" in a for a in actions)
        assert "Ralph Loop" in actions or any("Ralph" in a for a in actions)
    finally:
        subprocess.run(
            ["git", "-C", project_path, "worktree", "remove", "--force", wt_path],
            capture_output=True,
        )
        subprocess.run(
            ["git", "-C", project_path, "branch", "-D", "change/ctx-test"],
            capture_output=True,
        )
