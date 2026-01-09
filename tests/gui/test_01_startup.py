"""
Startup Tests - Verify the application starts correctly
"""

from PySide6.QtWidgets import QTableWidget, QLabel


def test_app_starts_without_error(control_center):
    """ControlCenter() instantiation should not raise."""
    assert control_center is not None


def test_window_is_visible(control_center):
    """Window should be visible after show()."""
    assert control_center.isVisible()


def test_initial_status_label(control_center):
    """Status label should have some text content."""
    assert control_center.status_label is not None
    assert isinstance(control_center.status_label, QLabel)
    # May be "Loading..." or actual status text
    assert len(control_center.status_label.text()) > 0


def test_table_exists_with_correct_columns(control_center):
    """Table should exist with 6 columns and correct headers."""
    table = control_center.table
    assert isinstance(table, QTableWidget)
    assert table.columnCount() == 6

    expected_headers = ["Branch", "PID", "Status", "Skill", "Ctx%", "Extra"]
    for i, expected in enumerate(expected_headers):
        item = table.horizontalHeaderItem(i)
        assert item is not None, f"Header item {i} is None"
        assert item.text() == expected, f"Header {i}: expected '{expected}', got '{item.text()}'"
