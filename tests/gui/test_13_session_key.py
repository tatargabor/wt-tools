"""
Multi-Account Usage Tests - Verify account management and multi-account usage display.

Tests load_accounts/save_accounts helpers, menu integration, and dynamic usage rows.
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


# --- load_accounts / save_accounts tests ---


def test_load_accounts_new_format(tmp_path, monkeypatch):
    """New format with accounts list loads correctly."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    session_file.write_text(json.dumps({
        "accounts": [
            {"name": "Personal", "sessionKey": "sk-ant-1"},
            {"name": "Work", "sessionKey": "sk-ant-2"},
        ]
    }))
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)

    accounts = usage_mod.load_accounts()
    assert len(accounts) == 2
    assert accounts[0]["name"] == "Personal"
    assert accounts[1]["sessionKey"] == "sk-ant-2"


def test_load_accounts_old_format_migration(tmp_path, monkeypatch):
    """Old single-key format auto-wraps into accounts list."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    session_file.write_text(json.dumps({"sessionKey": "sk-ant-old"}))
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)

    accounts = usage_mod.load_accounts()
    assert len(accounts) == 1
    assert accounts[0]["name"] == "Default"
    assert accounts[0]["sessionKey"] == "sk-ant-old"


def test_load_accounts_missing_file(tmp_path, monkeypatch):
    """Missing file returns empty list."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "nonexistent.json"
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)

    accounts = usage_mod.load_accounts()
    assert accounts == []


def test_load_accounts_empty_accounts(tmp_path, monkeypatch):
    """Empty accounts list returns empty."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    session_file.write_text(json.dumps({"accounts": []}))
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)

    accounts = usage_mod.load_accounts()
    assert accounts == []


def test_load_accounts_filters_invalid(tmp_path, monkeypatch):
    """Accounts without sessionKey are filtered out."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    session_file.write_text(json.dumps({
        "accounts": [
            {"name": "Valid", "sessionKey": "sk-ant-1"},
            {"name": "Invalid"},
            {"name": "Empty", "sessionKey": ""},
        ]
    }))
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)

    accounts = usage_mod.load_accounts()
    assert len(accounts) == 1
    assert accounts[0]["name"] == "Valid"


def test_save_accounts_writes_new_format(tmp_path, monkeypatch):
    """save_accounts always writes the new format."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)
    monkeypatch.setattr(usage_mod, "CONFIG_DIR", tmp_path)

    usage_mod.save_accounts([
        {"name": "A", "sessionKey": "sk-1"},
        {"name": "B", "sessionKey": "sk-2"},
    ])

    data = json.loads(session_file.read_text())
    assert "accounts" in data
    assert len(data["accounts"]) == 2
    assert "sessionKey" not in data  # no top-level key


def test_save_accounts_atomic(tmp_path, monkeypatch):
    """save_accounts uses atomic rename (no .tmp left behind)."""
    import gui.workers.usage as usage_mod

    session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)
    monkeypatch.setattr(usage_mod, "CONFIG_DIR", tmp_path)

    usage_mod.save_accounts([{"name": "X", "sessionKey": "sk-x"}])

    assert session_file.exists()
    assert not session_file.with_suffix(".tmp").exists()


# --- Menu tests ---


def test_main_menu_has_add_account_item(control_center, qtbot):
    """Main menu should contain 'Add Account...' item."""
    with _MenuCapture() as cap:
        control_center.show_main_menu()

    assert cap.menu is not None
    assert "Add Account..." in cap.actions


def test_main_menu_has_usage_browser_item(control_center, qtbot):
    """Main menu should contain 'Usage (Browser)' item."""
    with _MenuCapture() as cap:
        control_center.show_main_menu()

    assert "Usage (Browser)" in cap.actions


def test_add_account_saves_to_file(control_center, qtbot, tmp_path, monkeypatch):
    """Adding an account should save it to claude-session.json."""
    import gui.workers.usage as usage_mod
    import gui.control_center.mixins.handlers as handlers_mod

    session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)
    monkeypatch.setattr(usage_mod, "CONFIG_DIR", tmp_path)

    # Mock get_text: first call returns name, second returns key
    call_count = [0]
    def mock_get_text(*args, **kwargs):
        call_count[0] += 1
        if call_count[0] == 1:
            return ("Personal", True)
        return ("sk-ant-sid01-test-key", True)

    monkeypatch.setattr(handlers_mod, "get_text", mock_get_text)
    monkeypatch.setattr(control_center, "_restart_usage_worker", lambda: None)

    control_center.show_add_account()

    assert session_file.exists()
    data = json.loads(session_file.read_text())
    assert len(data["accounts"]) == 1
    assert data["accounts"][0]["name"] == "Personal"
    assert data["accounts"][0]["sessionKey"] == "sk-ant-sid01-test-key"


def test_add_account_cancelled(control_center, qtbot, tmp_path, monkeypatch):
    """Cancelling the name dialog should not create a session file."""
    import gui.workers.usage as usage_mod
    import gui.control_center.mixins.handlers as handlers_mod

    session_file = tmp_path / "claude-session.json"
    monkeypatch.setattr(usage_mod, "CLAUDE_SESSION_FILE", session_file)
    monkeypatch.setattr(usage_mod, "CONFIG_DIR", tmp_path)

    monkeypatch.setattr(
        handlers_mod, "get_text",
        lambda *args, **kwargs: ("", False),
    )

    control_center.show_add_account()

    assert not session_file.exists()


# --- Dynamic usage row tests ---


def test_rebuild_usage_rows_single_account(control_center, qtbot):
    """Single account should have 1 row with no name label."""
    control_center._rebuild_usage_rows(1)
    assert len(control_center.account_widgets) == 1
    assert control_center.account_widgets[0]["name_label"] is None


def test_rebuild_usage_rows_multi_account(control_center, qtbot):
    """Multiple accounts should have rows with name labels."""
    control_center._rebuild_usage_rows(3)
    assert len(control_center.account_widgets) == 3
    for w in control_center.account_widgets:
        assert w["name_label"] is not None
        assert w["bar_5h"] is not None
        assert w["bar_7d"] is not None


def test_update_usage_bars_multi_account(control_center, qtbot):
    """update_usage_bars with multi-account data should update all rows."""
    control_center.usage_data = [
        {"name": "Personal", "available": True, "is_estimated": False,
         "session_pct": 50, "weekly_pct": 25,
         "session_reset": None, "weekly_reset": None},
        {"name": "Work", "available": False},
    ]
    control_center.update_usage_bars()

    assert len(control_center.account_widgets) == 2
    assert control_center.account_widgets[0]["name_label"].text() == "Personal"
    assert "50%" in control_center.account_widgets[0]["label_5h"].text()
    assert control_center.account_widgets[1]["name_label"].text() == "Work"
    assert "--" in control_center.account_widgets[1]["label_5h"].text()


def test_update_usage_bars_single_account_no_name(control_center, qtbot):
    """Single account update should not show name label."""
    control_center.usage_data = [
        {"available": True, "is_estimated": False,
         "session_pct": 72, "weekly_pct": 30,
         "session_reset": None, "weekly_reset": None},
    ]
    control_center.update_usage_bars()

    assert len(control_center.account_widgets) == 1
    assert control_center.account_widgets[0]["name_label"] is None
    assert "72%" in control_center.account_widgets[0]["label_5h"].text()
