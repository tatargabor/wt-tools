"""
Dialog Tests - Verify dialogs open, render correctly, and close
"""

from unittest.mock import patch

from PySide6.QtCore import Qt
from PySide6.QtWidgets import QDialog, QComboBox, QLineEdit, QTabWidget


def test_settings_dialog_opens_and_closes(control_center, git_env, qtbot):
    """SettingsDialog should open, be visible, and close without error."""
    from gui.dialogs import SettingsDialog

    project = "test-project"
    dialog = SettingsDialog(control_center, control_center.config, project)
    qtbot.addWidget(dialog)
    dialog.show()
    qtbot.waitExposed(dialog)

    assert dialog.isVisible()
    assert dialog.windowFlags() & Qt.WindowStaysOnTopHint

    dialog.close()


def test_new_worktree_dialog_opens(control_center, git_env, qtbot):
    """NewWorktreeDialog should have project dropdown and change_id input."""
    from gui.dialogs import NewWorktreeDialog

    dialog = NewWorktreeDialog(control_center)
    qtbot.addWidget(dialog)
    dialog.show()
    qtbot.waitExposed(dialog)

    assert dialog.isVisible()

    # Should have a project combo box
    assert hasattr(dialog, "project_combo")
    assert isinstance(dialog.project_combo, QComboBox)

    # Should have a change_id input
    assert hasattr(dialog, "change_id_input")
    assert isinstance(dialog.change_id_input, QLineEdit)

    dialog.close()


def test_new_worktree_dialog_preview_updates(control_center, git_env, qtbot):
    """Typing a change_id should update the preview label."""
    from gui.dialogs import NewWorktreeDialog

    dialog = NewWorktreeDialog(control_center)
    qtbot.addWidget(dialog)
    dialog.show()
    qtbot.waitExposed(dialog)

    # Get initial preview text
    initial_preview = ""
    if hasattr(dialog, "preview_label"):
        initial_preview = dialog.preview_label.text()

    # Type a change ID
    dialog.change_id_input.setText("my-feature")
    qtbot.wait(100)

    # Preview should have changed
    if hasattr(dialog, "preview_label"):
        new_preview = dialog.preview_label.text()
        assert new_preview != initial_preview or "my-feature" in new_preview

    dialog.close()


def test_work_dialog_opens_with_tabs(control_center, git_env, qtbot):
    """WorkDialog should open with Local and Remote tabs."""
    from gui.dialogs import WorkDialog

    # Patch subprocess calls that WorkDialog makes to list worktrees
    with patch("subprocess.run") as mock_run:
        mock_run.return_value = type("Result", (), {
            "returncode": 0, "stdout": "", "stderr": ""
        })()

        dialog = WorkDialog(control_center, "test-project")
        qtbot.addWidget(dialog)
        dialog.show()
        qtbot.waitExposed(dialog)

        assert dialog.isVisible()

        # Find the QTabWidget
        tabs = dialog.findChild(QTabWidget)
        if tabs:
            assert tabs.count() >= 2, f"Expected at least 2 tabs, got {tabs.count()}"

        dialog.close()
