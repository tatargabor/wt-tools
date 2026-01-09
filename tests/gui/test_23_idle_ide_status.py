"""
Idle IDE Status Tests - Verify editor-open worktrees show "idle (IDE)" status
"""


def test_idle_ide_status_when_editor_open(control_center, git_env, qtbot):
    """Worktree with editor_open=true and no agents should show ◇ idle (IDE)."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "ide-open-test",
            "path": str(git_env["project"]),
            "branch": "change/ide-open-test",
            "is_main_repo": False,
            "editor_open": True,
            "agents": [],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    # Find the worktree row
    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "ide-open-test":
            wt_row = row
            break

    assert wt_row is not None, "IDE-open worktree row not found"

    # Status column should show "idle (IDE)" with ◇ icon
    status_item = control_center.table.item(wt_row, 2)
    assert status_item is not None
    assert "idle (IDE)" in status_item.text(), f"Expected 'idle (IDE)', got: {status_item.text()}"
    assert "\u25c7" in status_item.text(), f"Expected ◇ icon, got: {status_item.text()}"


def test_plain_idle_when_editor_closed(control_center, git_env, qtbot):
    """Worktree with editor_open=false and no agents should show ○ idle."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "no-editor-test",
            "path": str(git_env["project"]),
            "branch": "change/no-editor-test",
            "is_main_repo": False,
            "editor_open": False,
            "agents": [],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    # Find the worktree row
    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "no-editor-test":
            wt_row = row
            break

    assert wt_row is not None, "No-editor worktree row not found"

    # Status column should show plain "idle" with ○ icon, NOT "idle (IDE)"
    status_item = control_center.table.item(wt_row, 2)
    assert status_item is not None
    assert "idle (IDE)" not in status_item.text(), f"Should NOT show 'idle (IDE)', got: {status_item.text()}"
    assert "idle" in status_item.text(), f"Expected 'idle', got: {status_item.text()}"
    assert "\u25cb" in status_item.text(), f"Expected ○ icon, got: {status_item.text()}"


def test_orphan_ide_status_when_editor_open(control_center, git_env, qtbot):
    """Orphan agent with editor_open=true should show 'orphan (IDE)'."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "orphan-ide-test",
            "path": str(git_env["project"]),
            "branch": "change/orphan-ide-test",
            "is_main_repo": False,
            "editor_open": True,
            "agents": [{"pid": 99999, "status": "orphan", "skill": None}],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "orphan-ide-test":
            wt_row = row
            break

    assert wt_row is not None, "Orphan IDE worktree row not found"

    status_item = control_center.table.item(wt_row, 2)
    assert status_item is not None
    assert "orphan (IDE)" in status_item.text(), f"Expected 'orphan (IDE)', got: {status_item.text()}"


def test_orphan_no_ide_status(control_center, git_env, qtbot):
    """Orphan agent with editor_open=false should show plain 'orphan'."""
    status_data = {
        "worktrees": [{
            "project": "test-project",
            "change_id": "orphan-no-ide-test",
            "path": str(git_env["project"]),
            "branch": "change/orphan-no-ide-test",
            "is_main_repo": False,
            "editor_open": False,
            "agents": [{"pid": 99999, "status": "orphan", "skill": None}],
            "git": {"last_commit": 0, "uncommitted_changes": False},
        }],
        "summary": {"total": 1, "running": 0, "compacting": 0, "waiting": 0, "idle": 1},
    }
    control_center.update_status(status_data)
    qtbot.wait(200)

    wt_row = None
    for row, wt in control_center.row_to_worktree.items():
        if wt.get("change_id") == "orphan-no-ide-test":
            wt_row = row
            break

    assert wt_row is not None, "Orphan no-IDE worktree row not found"

    status_item = control_center.table.item(wt_row, 2)
    assert status_item is not None
    assert "orphan" in status_item.text(), f"Expected 'orphan', got: {status_item.text()}"
    assert "(IDE)" not in status_item.text(), f"Should NOT show '(IDE)', got: {status_item.text()}"
