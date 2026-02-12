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
            "agents": [{"pid": 5001, "status": "waiting", "editor_type": "gnome-terminal-", "window_id": "12345"}],
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
            "agents": [{"pid": 5002, "status": "waiting", "editor_type": "zed", "window_id": "67890"}],
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
            "agents": [{"pid": 5003, "status": "waiting", "editor_type": None, "window_id": None}],
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


def test_mixed_agents_per_agent_display(control_center, git_env, qtbot):
    """Mixed worktree: IDE agent shows orange, terminal agent shows dimmed."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "mixed-test",
            "path": str(git_env["project"]),
            "branch": "change/mixed-test",
            "is_main_repo": False,
            "editor_open": True,
            "editor_type": "zed",
            "window_id": "11111",
            "agents": [
                {"pid": 6001, "status": "waiting", "editor_type": "zed", "window_id": "11111"},
                {"pid": 6002, "status": "waiting", "editor_type": "gnome-terminal-", "window_id": "22222"},
            ],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 2, "idle": 0},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    # Find all waiting rows
    rows = sorted(control_center.row_to_worktree.keys())
    waiting_rows = []
    for row in rows:
        status_item = control_center.table.item(row, 2)
        if status_item and "waiting" in status_item.text():
            fg = status_item.foreground().color()
            agent = control_center.row_to_agent.get(row, {})
            waiting_rows.append((row, fg, agent))

    assert len(waiting_rows) == 2, f"Expected 2 waiting rows, got {len(waiting_rows)}"

    # First agent (IDE/zed) should be orange
    _, fg_ide, agent_ide = waiting_rows[0]
    assert agent_ide.get("editor_type") == "zed"
    assert fg_ide.red() > 150, (
        f"IDE agent should be orange, got fg=({fg_ide.red()},{fg_ide.green()},{fg_ide.blue()})"
    )

    # Second agent (terminal) should be dimmed
    _, fg_term, agent_term = waiting_rows[1]
    assert agent_term.get("editor_type") == "gnome-terminal-"
    assert fg_term.red() < 200 or fg_term.blue() > 100, (
        f"Terminal agent should be dimmed, got fg=({fg_term.red()},{fg_term.green()},{fg_term.blue()})"
    )
