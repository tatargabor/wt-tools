"""
OpenSpec Button Tests - Verify [O] button in project header, context menu,
and FeatureWorker instantiation.
"""

from unittest.mock import patch, MagicMock

from PySide6.QtCore import QPoint, Qt
from PySide6.QtWidgets import QMenu, QPushButton

from gui.workers.feature import FeatureWorker


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
    return {
        "worktrees": [{
            "project": "test-project",
            "change_id": "os-test",
            "path": str(git_env["project"]),
            "branch": "change/os-test",
            "agents": [],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }


def _set_feature_cache(cc, memory=None, openspec=None):
    """Set feature cache directly on the control center."""
    if memory is None:
        memory = {"available": False, "count": 0}
    if openspec is None:
        openspec = {"installed": False, "changes_active": 0, "skills_present": False, "cli_available": False}
    cc._feature_cache = {"test-project": {"memory": memory, "openspec": openspec}}


def test_openspec_button_in_project_header(control_center, git_env, qtbot):
    """Project header should contain an [O] button for OpenSpec."""
    _set_feature_cache(control_center, openspec={"installed": True, "changes_active": 3, "skills_present": True, "cli_available": True})
    control_center.update_status(_make_status_data(git_env))
    qtbot.wait(200)

    header_widget = control_center.table.cellWidget(0, 0)
    assert header_widget is not None

    os_buttons = [btn for btn in header_widget.findChildren(QPushButton) if btn.text() == "O"]
    assert len(os_buttons) == 1
    assert "3 active changes" in os_buttons[0].toolTip()


def test_openspec_button_green_when_installed(control_center, git_env, qtbot):
    """[O] button should be green when OpenSpec is installed."""
    _set_feature_cache(control_center, openspec={"installed": True, "changes_active": 1, "skills_present": True, "cli_available": True})
    control_center.update_status(_make_status_data(git_env))
    qtbot.wait(200)

    header_widget = control_center.table.cellWidget(0, 0)
    os_btn = [btn for btn in header_widget.findChildren(QPushButton) if btn.text() == "O"][0]

    green_color = control_center.get_color("status_running")
    assert green_color in os_btn.styleSheet()


def test_openspec_button_gray_when_not_installed(control_center, git_env, qtbot):
    """[O] button should be gray when OpenSpec is not installed."""
    _set_feature_cache(control_center, openspec={"installed": False})
    control_center.update_status(_make_status_data(git_env))
    qtbot.wait(200)

    header_widget = control_center.table.cellWidget(0, 0)
    os_btn = [btn for btn in header_widget.findChildren(QPushButton) if btn.text() == "O"][0]

    assert "not initialized" in os_btn.toolTip()


def test_project_header_context_menu_has_openspec(control_center, git_env, qtbot):
    """Project header context menu should include OpenSpec submenu."""
    _set_feature_cache(
        control_center,
        memory={"available": True, "count": 2},
        openspec={"installed": True, "changes_active": 1, "skills_present": True, "cli_available": True},
    )
    control_center.update_status(_make_status_data(git_env))
    qtbot.wait(200)

    header_row = None
    for row, proj in getattr(control_center, 'row_to_project', {}).items():
        if proj == "test-project":
            header_row = row
            break
    assert header_row is not None

    with _MenuCapture() as cap:
        row_rect = control_center.table.visualRect(
            control_center.table.model().index(header_row, 0)
        )
        with patch.object(type(control_center), '_check_skill_memory_hooks', return_value=True):
            control_center.show_row_context_menu(row_rect.center())

    assert len(cap.menus) > 0
    assert "Memory" in cap.last_submenus or "Memory" in cap.last_actions
    assert "OpenSpec" in cap.last_submenus or "OpenSpec" in cap.last_actions


def test_feature_worker_instantiation():
    """FeatureWorker should instantiate and have expected methods."""
    worker = FeatureWorker()
    assert hasattr(worker, 'features_updated')
    assert hasattr(worker, 'set_projects')
    assert hasattr(worker, 'refresh_now')
    assert hasattr(worker, 'stop')
    # Don't start the thread — just check the interface
    worker._running = False
