"""
New Worktree Dialog - Create a new worktree
"""

import json
from pathlib import Path

from PySide6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel, QPushButton,
    QLineEdit, QComboBox, QGroupBox, QDialogButtonBox, QFileDialog, QMessageBox
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QGuiApplication

from ..constants import CONFIG_DIR
from .helpers import show_warning

__all__ = ["NewWorktreeDialog"]


class NewWorktreeDialog(QDialog):
    """Dialog for creating a new worktree with project and branch selection"""

    def __init__(self, parent, preset_project: str = None):
        super().__init__(parent)
        self.setWindowTitle("New Worktree")
        self.setMinimumWidth(450)
        self.setWindowFlags(
            Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint |
            Qt.WindowStaysOnTopHint
        )

        # Center on screen
        screen = QGuiApplication.primaryScreen().geometry()
        self.move(
            (screen.width() - 450) // 2,
            (screen.height() - 300) // 2
        )

        self.local_path = None  # Store local path if browsed

        layout = QVBoxLayout(self)

        # Form layout for inputs
        form = QFormLayout()

        # Project dropdown with Browse button
        project_row = QHBoxLayout()
        self.project_combo = QComboBox()
        self.project_combo.setMinimumWidth(250)
        self.load_projects()
        if preset_project:
            idx = self.project_combo.findText(preset_project)
            if idx >= 0:
                self.project_combo.setCurrentIndex(idx)
        self.project_combo.currentTextChanged.connect(self.update_preview)
        project_row.addWidget(self.project_combo)

        browse_btn = QPushButton("Browse...")
        browse_btn.setToolTip("Select a local git repository")
        browse_btn.clicked.connect(self.browse_local)
        project_row.addWidget(browse_btn)
        form.addRow("Project:", project_row)

        # Change ID input
        self.change_id_input = QLineEdit()
        self.change_id_input.setPlaceholderText("e.g., add-feature, fix-bug-123")
        self.change_id_input.textChanged.connect(self.update_preview)
        form.addRow("Change ID:", self.change_id_input)

        layout.addLayout(form)

        # Preview section
        preview_group = QGroupBox("Preview")
        preview_layout = QVBoxLayout(preview_group)
        self.preview_path = QLabel("")
        self.preview_branch = QLabel("")
        preview_layout.addWidget(self.preview_path)
        preview_layout.addWidget(self.preview_branch)
        layout.addWidget(preview_group)

        # Buttons
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.button(QDialogButtonBox.Ok).setText("Create")
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        self.update_preview()

    def browse_local(self):
        """Browse for a local git repository"""
        path = QFileDialog.getExistingDirectory(
            self, "Select Git Repository",
            str(Path.home() / "code2"),
            QFileDialog.ShowDirsOnly
        )
        if path:
            # Verify it's a git repo
            git_dir = Path(path) / ".git"
            if not git_dir.exists():
                show_warning(self, "Not a Git Repository",
                    f"{path} is not a git repository (no .git folder)")
                return

            # Use directory name as project name
            project_name = Path(path).name
            self.local_path = path

            # Add to combo if not present
            idx = self.project_combo.findText(project_name)
            if idx < 0:
                self.project_combo.addItem(project_name)
                idx = self.project_combo.findText(project_name)
            self.project_combo.setCurrentIndex(idx)

    def load_projects(self):
        """Load registered projects from config"""
        self.project_combo.clear()
        try:
            config_path = CONFIG_DIR / "projects.json"
            if config_path.exists():
                with open(config_path) as f:
                    data = json.load(f)
                    projects = data.get("projects", {})
                    default = data.get("default")
                    for name in sorted(projects.keys()):
                        self.project_combo.addItem(name)
                    if default and self.project_combo.findText(default) >= 0:
                        self.project_combo.setCurrentText(default)
        except Exception:
            pass

    def update_preview(self):
        """Update preview labels"""
        project = self.project_combo.currentText()
        change_id = self.change_id_input.text().strip()

        if project and change_id:
            # Get actual project path to compute worktree path
            wt_path = f".../{project}-wt-{change_id}"
            project_path = self.local_path  # Use local path if set

            if not project_path:
                # Try to get from config
                try:
                    config_path = CONFIG_DIR / "projects.json"
                    if config_path.exists():
                        with open(config_path) as f:
                            data = json.load(f)
                            project_path = data.get("projects", {}).get(project, {}).get("path")
                except Exception:
                    pass

            if project_path:
                base_dir = Path(project_path).parent
                wt_path = str(base_dir / f"{project}-wt-{change_id}")

            self.preview_path.setText(f"Path: {wt_path}")
            self.preview_branch.setText(f"Branch: change/{change_id}")
        else:
            self.preview_path.setText("Path: ...")
            self.preview_branch.setText("Branch: ...")

    def get_values(self):
        """Get dialog values"""
        return {
            "project": self.project_combo.currentText(),
            "change_id": self.change_id_input.text().strip(),
            "local_path": self.local_path
        }
