"""
Button Tests - Verify all buttons exist, have correct labels, and are functional
"""

from PySide6.QtCore import Qt


def test_btn_new_exists(control_center):
    """New button should exist with correct text and be enabled."""
    btn = control_center.btn_new
    assert btn.text() == "+ New"
    assert btn.isEnabled()


def test_btn_work_exists(control_center):
    """Work button should exist with correct text and be enabled."""
    btn = control_center.btn_work
    assert btn.text() == "Work"
    assert btn.isEnabled()


def test_btn_add_exists(control_center):
    """Add button should exist with correct text and tooltip."""
    btn = control_center.btn_add
    assert btn.text() == "Add"
    assert btn.toolTip() == "Add existing repository or worktree"
    assert btn.isEnabled()


def test_btn_filter_is_toggle(control_center, qtbot):
    """Filter button should be checkable and toggle on click."""
    btn = control_center.btn_filter
    assert btn.isCheckable()
    assert not btn.isChecked()

    qtbot.mouseClick(btn, Qt.LeftButton)
    assert btn.isChecked()

    qtbot.mouseClick(btn, Qt.LeftButton)
    assert not btn.isChecked()


def test_btn_minimize_hides_window(control_center, qtbot):
    """Clicking minimize button should hide the window."""
    assert control_center.isVisible()
    qtbot.mouseClick(control_center.btn_minimize, Qt.LeftButton)
    assert not control_center.isVisible()
    # Restore visibility for subsequent tests (module-scoped fixture)
    control_center.show()


def test_btn_menu_exists(control_center):
    """Menu button should exist with correct text."""
    btn = control_center.btn_menu
    assert btn.text() == "≡"
    assert btn.isEnabled()
