"""
System Tray Tests - Verify tray icon, menu, and tooltip
"""

from PySide6.QtWidgets import QSystemTrayIcon


def test_tray_icon_exists(control_center):
    """Tray icon should be created."""
    assert control_center.tray is not None
    assert isinstance(control_center.tray, QSystemTrayIcon)


def test_tray_icon_visible(control_center):
    """Tray icon should be visible."""
    assert control_center.tray.isVisible()


def test_tray_tooltip(control_center):
    """Tray tooltip should contain status info (updates after first status fetch)."""
    tooltip = control_center.tray.toolTip()
    # Tooltip is either the initial string or updated with status summary
    assert tooltip and len(tooltip) > 0, "Tray tooltip should not be empty"


def test_tray_has_menu(control_center):
    """Tray should have a context menu with expected actions."""
    menu = control_center.tray.contextMenu()
    assert menu is not None

    action_texts = [a.text() for a in menu.actions() if not a.isSeparator()]
    assert "Show" in action_texts
    # Check for key actions (text may include emoji prefixes)
    has_new = any("New Worktree" in t for t in action_texts)
    has_settings = any("Settings" in t for t in action_texts)
    has_quit = any("Quit" in t for t in action_texts)

    assert has_new, f"'New Worktree' not found in tray menu: {action_texts}"
    assert has_settings, f"'Settings' not found in tray menu: {action_texts}"
    assert has_quit, f"'Quit' not found in tray menu: {action_texts}"
