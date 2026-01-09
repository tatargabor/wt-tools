"""
Orphan Agent Tests - Verify orphan detection display and context menu
"""

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


def test_orphan_row_display(control_center, git_env, qtbot):
    """Orphan agent should show ⚠ in PID column and 'orphan' in status."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "orphan-test",
            "path": str(git_env["project"]),
            "branch": "change/orphan-test",
            "is_main_repo": False,
            "agents": [
                {"pid": 99999, "status": "orphan", "skill": None, "skill_fresh": None},
            ],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 0},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    # Find the worktree row
    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "orphan-test":
            wt_row = row
            break

    assert wt_row is not None, "Orphan worktree row not found"

    # PID column should have ⚠ prefix
    pid_item = control_center.table.item(wt_row, 1)
    assert pid_item is not None
    assert "\u26a0" in pid_item.text(), f"PID should have ⚠ prefix, got: {pid_item.text()}"
    assert "99999" in pid_item.text()

    # Status column should say "orphan"
    status_item = control_center.table.item(wt_row, 2)
    assert status_item is not None
    assert "orphan" in status_item.text()


def test_orphan_context_menu_has_kill(control_center, git_env, qtbot):
    """Right-click on orphan row should show 'Kill Orphan Process' action."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "orphan-kill-test",
            "path": str(git_env["project"]),
            "branch": "change/orphan-kill-test",
            "is_main_repo": False,
            "agents": [
                {"pid": 88888, "status": "orphan", "skill": None, "skill_fresh": None},
            ],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 0},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "orphan-kill-test":
            wt_row = row
            break

    assert wt_row is not None

    with _MenuCapture() as cap:
        row_rect = control_center.table.visualRect(
            control_center.table.model().index(wt_row, 0)
        )
        control_center.show_row_context_menu(row_rect.center())

    assert len(cap.menus) > 0, "Context menu was not created"
    actions = cap.last_actions
    assert any("Kill Orphan" in a for a in actions), f"Kill Orphan action missing, got: {actions}"


def test_normal_context_menu_no_kill(control_center, git_env, qtbot):
    """Right-click on normal (non-orphan) row should NOT show kill action."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "normal-test",
            "path": str(git_env["project"]),
            "branch": "change/normal-test",
            "is_main_repo": False,
            "agents": [
                {"pid": 77777, "status": "waiting", "skill": None, "skill_fresh": None},
            ],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 1, "idle": 0},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "normal-test":
            wt_row = row
            break

    assert wt_row is not None

    with _MenuCapture() as cap:
        row_rect = control_center.table.visualRect(
            control_center.table.model().index(wt_row, 0)
        )
        control_center.show_row_context_menu(row_rect.center())

    assert len(cap.menus) > 0, "Context menu was not created"
    actions = cap.last_actions
    assert not any("Kill Orphan" in a for a in actions), f"Kill Orphan should NOT appear for normal agents, got: {actions}"
