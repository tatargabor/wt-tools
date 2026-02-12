"""
Terminal Agent Display Tests - Verify dimmed display for terminal-based waiting agents
"""

from PySide6.QtGui import QColor


def _get_status_row_colors(control_center, status_data, qtbot):
    """Helper: update status and return (bg_color, text_color) for the first worktree row."""
    control_center.update_status(status_data)
    qtbot.wait(200)

    # Find first worktree row
    for row in sorted(control_center.row_to_worktree.keys()):
        status_item = control_center.table.item(row, 2)  # COL_STATUS
        if status_item and "waiting" in status_item.text():
            bg = control_center.table.item(row, 0).background().color()
            fg = status_item.foreground().color()
            return bg, fg
    return None, None


def test_terminal_waiting_agent_dimmed(control_center, git_env, qtbot):
    """Waiting agent in terminal (non-IDE editor_type) should use dimmed colors."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "term-test",
            "path": str(git_env["project"]),
            "branch": "change/term-test",
            "is_main_repo": False,
            "editor_open": True,
            "editor_type": "gnome-terminal-",
            "window_id": "12345",
            "agents": [{"pid": 5001, "status": "waiting"}],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 1, "idle": 0},
    }
    bg, fg = _get_status_row_colors(control_center, status_data, qtbot)
    assert bg is not None, "Should find a waiting row"

    # Dimmed text should use muted color (low saturation / grayish)
    # NOT the orange waiting color (#f59e0b → high red+green, low blue)
    assert fg.red() < 200 or fg.blue() > 100, (
        f"Terminal waiting should be dimmed, got fg=({fg.red()},{fg.green()},{fg.blue()})"
    )


def test_ide_waiting_agent_orange(control_center, git_env, qtbot):
    """Waiting agent in IDE (editor_type=zed) should use standard orange colors."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "ide-test",
            "path": str(git_env["project"]),
            "branch": "change/ide-test",
            "is_main_repo": False,
            "editor_open": True,
            "editor_type": "zed",
            "window_id": "67890",
            "agents": [{"pid": 5002, "status": "waiting"}],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 1, "idle": 0},
    }
    bg, fg = _get_status_row_colors(control_center, status_data, qtbot)
    assert bg is not None, "Should find a waiting row"

    # Standard waiting colors — orange-ish text
    # The waiting color is #f59e0b (245, 158, 11) or similar
    assert fg.red() > 150, (
        f"IDE waiting should be orange, got fg=({fg.red()},{fg.green()},{fg.blue()})"
    )


def test_no_editor_type_uses_standard_display(control_center, git_env, qtbot):
    """Waiting agent with no editor_type should use standard orange colors."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "null-test",
            "path": str(git_env["project"]),
            "branch": "change/null-test",
            "is_main_repo": False,
            "editor_open": False,
            "editor_type": None,
            "agents": [{"pid": 5003, "status": "waiting"}],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 1, "idle": 0},
    }
    bg, fg = _get_status_row_colors(control_center, status_data, qtbot)
    assert bg is not None, "Should find a waiting row"

    # Should use standard waiting display (not dimmed)
    assert fg.red() > 150, (
        f"No-editor waiting should be standard orange, got fg=({fg.red()},{fg.green()},{fg.blue()})"
    )
