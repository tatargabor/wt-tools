"""
Session Key Tests - Verify session key dialog and menu integration.

Tests the "Set Session Key..." menu item added as replacement for WebEngine login dialog.
"""

import json

from PySide6.QtWidgets import QMenu


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


def test_main_menu_has_session_key_item(control_center, qtbot):
    """Main menu should contain 'Set Session Key...' item."""
    with _MenuCapture() as cap:
        control_center.show_main_menu()

    assert cap.menu is not None, "Menu was not created"
    assert "Set Session Key..." in cap.actions


def test_main_menu_has_usage_browser_item(control_center, qtbot):
    """Main menu should contain 'Usage (Browser)' item."""
    with _MenuCapture() as cap:
        control_center.show_main_menu()

    assert "Usage (Browser)" in cap.actions


def test_set_session_key_saves_to_file(control_center, qtbot, tmp_path, monkeypatch):
    """Setting a session key should save it to claude-session.json."""
    import gui.constants as constants
    import gui.control_center.mixins.handlers as handlers_mod

    test_session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(constants, "CLAUDE_SESSION_FILE", test_session_file)
    monkeypatch.setattr(constants, "CONFIG_DIR", tmp_path)

    # Mock get_text helper (used instead of QInputDialog.getText)
    monkeypatch.setattr(
        handlers_mod, "get_text",
        lambda *args, **kwargs: ("sk-ant-sid01-test-key", True),
    )

    # Mock _restart_usage_worker to avoid thread issues
    monkeypatch.setattr(control_center, "_restart_usage_worker", lambda: None)

    control_center.show_set_session_key()

    assert test_session_file.exists()
    with open(test_session_file) as f:
        data = json.load(f)
    assert data["sessionKey"] == "sk-ant-sid01-test-key"


def test_set_session_key_cancelled(control_center, qtbot, tmp_path, monkeypatch):
    """Cancelling the dialog should not create a session file."""
    import gui.constants as constants
    import gui.control_center.mixins.handlers as handlers_mod

    test_session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(constants, "CLAUDE_SESSION_FILE", test_session_file)
    monkeypatch.setattr(constants, "CONFIG_DIR", tmp_path)

    # Mock get_text helper to return cancelled
    monkeypatch.setattr(
        handlers_mod, "get_text",
        lambda *args, **kwargs: ("", False),
    )

    control_center.show_set_session_key()

    assert not test_session_file.exists()
