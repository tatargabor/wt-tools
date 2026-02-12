"""
Memory Tests - Verify [M] button in project header, project header context menu,
and MemoryBrowseDialog instantiation.
"""

from unittest.mock import patch

from PySide6.QtCore import QPoint, Qt
from PySide6.QtWidgets import QMenu, QPushButton

from gui.dialogs.memory_dialog import MemoryBrowseDialog


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


def _make_status_data(git_env):
    """Build a minimal status_data dict with one worktree."""
    return {
        "worktrees": [{
            "project": "test-project",
            "change_id": "mem-test",
            "path": str(git_env["project"]),
            "branch": "change/mem-test",
            "agents": [],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }


def test_memory_button_in_project_header(control_center, git_env, qtbot):
    """Project header should contain an [M] button for memory."""
    with patch.object(type(control_center), 'get_memory_status', return_value={"available": False, "count": 0}):
        control_center.update_status(_make_status_data(git_env))
        qtbot.wait(200)

    # Find the project header row (row 0 should be header, spanning columns)
    assert control_center.table.rowCount() >= 2
    header_widget = control_center.table.cellWidget(0, 0)
    assert header_widget is not None, "Project header widget not found"

    # Find the [M] button inside the header widget
    mem_buttons = [btn for btn in header_widget.findChildren(QPushButton) if btn.text() == "M"]
    assert len(mem_buttons) == 1, f"Expected one [M] button, found {len(mem_buttons)}"

    mem_btn = mem_buttons[0]
    assert mem_btn.toolTip().startswith("Memory:")


def test_memory_button_purple_when_memories_exist(control_center, git_env, qtbot):
    """[M] button should be purple (status_compacting color) when memories exist."""
    with patch.object(type(control_center), 'get_memory_status', return_value={"available": True, "count": 5}):
        control_center.update_status(_make_status_data(git_env))
        qtbot.wait(200)

    header_widget = control_center.table.cellWidget(0, 0)
    mem_btn = [btn for btn in header_widget.findChildren(QPushButton) if btn.text() == "M"][0]

    purple_color = control_center.get_color("status_compacting")
    assert purple_color in mem_btn.styleSheet()
    assert "5 memories" in mem_btn.toolTip()


def test_project_header_context_menu(control_center, git_env, qtbot):
    """Right-click on project header row should show project header context menu with Memory submenu."""
    with patch.object(type(control_center), 'get_memory_status', return_value={"available": True, "count": 3}):
        control_center.update_status(_make_status_data(git_env))
        qtbot.wait(200)

    # Find the project header row
    header_row = None
    for row, proj in getattr(control_center, 'row_to_project', {}).items():
        if proj == "test-project":
            header_row = row
            break
    assert header_row is not None, "Project header row not found in row_to_project"

    with _MenuCapture() as cap:
        row_rect = control_center.table.visualRect(
            control_center.table.model().index(header_row, 0)
        )
        with patch.object(type(control_center), '_check_skill_memory_hooks', return_value=True):
            control_center.show_row_context_menu(row_rect.center())

    assert len(cap.menus) > 0, "Project header context menu was not created"
    actions = cap.last_actions
    # Memory submenu should appear
    assert "Memory" in cap.last_submenus or "Memory" in actions
    # Standard project actions
    assert "+ New Worktree..." in actions


def test_memory_browse_dialog_empty_state(control_center, qtbot):
    """MemoryBrowseDialog should show empty state when no memories exist."""
    with patch("gui.dialogs.memory_dialog._run_wt_memory", return_value="[]"):
        dialog = MemoryBrowseDialog(control_center, "test-project")

    assert dialog.windowTitle() == "Memory: test-project"
    assert dialog.windowFlags() & Qt.WindowStaysOnTopHint

    # Status should show 0 memories
    assert "0 memories" in dialog.status_label.text()

    dialog.close()
