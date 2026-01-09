"""
Merge Dialog - Options for merging branches
"""

from PySide6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel, QCheckBox,
    QComboBox, QDialogButtonBox
)
from PySide6.QtCore import Qt

__all__ = ["MergeDialog"]


class MergeDialog(QDialog):
    """Dialog for merge options"""

    def __init__(self, parent, source_branch: str, target_branches: list, has_changes: bool):
        super().__init__(parent)
        self.setWindowTitle("Merge Branch")
        self.setMinimumWidth(350)
        self.setWindowFlags(
            Qt.Window | Qt.WindowTitleHint | Qt.WindowCloseButtonHint |
            Qt.WindowStaysOnTopHint
        )

        layout = QVBoxLayout(self)

        # Source info
        layout.addWidget(QLabel(f"<b>Source:</b> {source_branch}"))

        # Target branch dropdown
        target_layout = QHBoxLayout()
        target_layout.addWidget(QLabel("Merge into:"))
        self.target_combo = QComboBox()
        self.target_combo.addItems(target_branches)
        target_layout.addWidget(self.target_combo, 1)
        layout.addLayout(target_layout)

        # Stash checkbox (only if there are changes)
        self.stash_check = QCheckBox("Stash uncommitted changes before merge")
        if has_changes:
            self.stash_check.setChecked(True)
            self.stash_check.setStyleSheet("color: #b45309;")  # Warning color
            layout.addWidget(QLabel("<i style='color: #b45309;'>⚠ Uncommitted changes detected</i>"))
        else:
            self.stash_check.setEnabled(False)
        layout.addWidget(self.stash_check)

        # Keep branch checkbox
        self.keep_branch_check = QCheckBox("Keep source branch (don't delete after merge)")
        self.keep_branch_check.setChecked(True)  # Default to keeping the branch
        layout.addWidget(self.keep_branch_check)

        # Push checkbox
        self.push_check = QCheckBox("Push to origin after merge")
        self.push_check.setChecked(True)  # Default to push
        layout.addWidget(self.push_check)

        # Buttons
        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.button(QDialogButtonBox.Ok).setText("Merge")
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def get_target(self) -> str:
        return self.target_combo.currentText()

    def should_stash(self) -> bool:
        return self.stash_check.isChecked()

    def should_keep_branch(self) -> bool:
        return self.keep_branch_check.isChecked()

    def should_push(self) -> bool:
        return self.push_check.isChecked()
