"""
Main Menu Tests - Verify the hamburger menu content and actions.

Strategy: We monkey-patch QMenu at the class level to intercept exec() calls,
since PySide6's QMenu.exec is a C++ slot that blocks the event loop.
"""

from PySide6.QtWidgets import QMenu

from gui.dialogs import SettingsDialog


class _MenuCapture:
    """Context manager that intercepts QMenu.exec to prevent blocking."""

    def __init__(self, on_exec=None):
        self.menu = None
        self.actions = []
        self._on_exec = on_exec
        self._original_init = None

    def __enter__(self):
        self._original_init = QMenu.__init__

        capture = self

        original_init = self._original_init

        def patched_init(menu_self, *args, **kwargs):
            original_init(menu_self, *args, **kwargs)
            # Replace exec on this instance
            original_exec = menu_self.exec

            def non_blocking_exec(*a, **kw):
                capture.menu = menu_self
                capture.actions = [
                    act.text() for act in menu_self.actions() if not act.isSeparator()
                ]
                if capture._on_exec:
                    capture._on_exec(menu_self)
                return None

            menu_self.exec = non_blocking_exec

        QMenu.__init__ = patched_init
        return self

    def __exit__(self, *args):
        QMenu.__init__ = self._original_init


def test_main_menu_has_all_items(control_center, qtbot):
    """Main menu should contain Settings, Session Key, Usage, Minimize, Restart, Quit."""
    with _MenuCapture() as cap:
        control_center.show_main_menu()

    assert cap.menu is not None, "Menu was not created"
    assert "Settings..." in cap.actions
    assert "Set Session Key..." in cap.actions
    assert "Usage (Browser)" in cap.actions
    assert "Minimize to Tray" in cap.actions
    assert "Restart" in cap.actions
    assert "Quit" in cap.actions


def test_main_menu_minimize_hides(control_center, qtbot):
    """Triggering 'Minimize to Tray' action should hide window."""

    def trigger_minimize(menu):
        for action in menu.actions():
            if action.text() == "Minimize to Tray":
                action.trigger()
                break

    with _MenuCapture(on_exec=trigger_minimize):
        control_center.show_main_menu()

    assert not control_center.isVisible()
    # Restore visibility for subsequent tests (module-scoped fixture)
    control_center.show()


def test_main_menu_settings_opens_dialog(control_center, qtbot):
    """Triggering Settings action should open SettingsDialog."""
    dialog_opened = {"value": False}

    original_dialog_exec = SettingsDialog.exec

    def mock_dialog_exec(self):
        dialog_opened["value"] = True
        return 0  # Rejected

    def trigger_settings(menu):
        for action in menu.actions():
            if action.text() == "Settings...":
                action.trigger()
                break

    SettingsDialog.exec = mock_dialog_exec
    try:
        with _MenuCapture(on_exec=trigger_settings):
            control_center.show_main_menu()
    finally:
        SettingsDialog.exec = original_dialog_exec

    assert dialog_opened["value"], "SettingsDialog was not opened"
