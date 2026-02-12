"""
Memory Dialogs - Browse and remember memories via shodh-memory
"""

import json
import subprocess
from datetime import datetime

from PySide6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel, QPushButton,
    QLineEdit, QTextEdit, QComboBox, QScrollArea, QWidget, QFrame
)
from PySide6.QtCore import Qt

from ..constants import SCRIPT_DIR

__all__ = ["MemoryBrowseDialog", "RememberNoteDialog"]


def _run_wt_memory(*args):
    """Run wt-memory CLI and return stdout. Returns empty string on error."""
    try:
        result = subprocess.run(
            [str(SCRIPT_DIR / "wt-memory")] + list(args),
            capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception:
        return ""


class MemoryBrowseDialog(QDialog):
    """Dialog to browse and search project memories"""

    def __init__(self, parent, project: str):
        super().__init__(parent)
        self.project = project
        self.setWindowTitle(f"Memory: {project}")
        self.setWindowFlags(self.windowFlags() | Qt.WindowStaysOnTopHint)
        self.setMinimumSize(500, 400)
        self.resize(550, 500)
        self._setup_ui()
        self._load_all()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        # Search bar
        search_layout = QHBoxLayout()
        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search memories (semantic)...")
        self.search_input.returnPressed.connect(self._on_search)
        search_layout.addWidget(self.search_input)

        clear_btn = QPushButton("Clear")
        clear_btn.setFixedWidth(60)
        clear_btn.clicked.connect(self._on_clear)
        search_layout.addWidget(clear_btn)
        layout.addLayout(search_layout)

        # Scrollable memory list
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.list_widget = QWidget()
        self.list_layout = QVBoxLayout(self.list_widget)
        self.list_layout.setAlignment(Qt.AlignTop)
        self.scroll_area.setWidget(self.list_widget)
        layout.addWidget(self.scroll_area)

        # Status bar
        self.status_label = QLabel("")
        self.status_label.setStyleSheet("color: #6b7280; font-size: 11px;")
        layout.addWidget(self.status_label)

        # Close button
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.close)
        layout.addWidget(close_btn)

    def _load_all(self):
        """Load all memories via wt-memory list"""
        output = _run_wt_memory("--project", self.project, "list")
        self._display_memories(output, mode="list")

    def _on_search(self):
        query = self.search_input.text().strip()
        if not query:
            self._load_all()
            return
        output = _run_wt_memory("--project", self.project, "recall", query, "--limit", "20")
        self._display_memories(output, mode="search")

    def _on_clear(self):
        self.search_input.clear()
        self._load_all()

    def _display_memories(self, json_str: str, mode: str = "list"):
        """Parse JSON and populate list"""
        # Clear existing
        while self.list_layout.count():
            child = self.list_layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()

        try:
            memories = json.loads(json_str) if json_str else []
        except json.JSONDecodeError:
            memories = []

        if not memories:
            empty_label = QLabel("No memories yet." if mode == "list" else "No results found.")
            empty_label.setStyleSheet("color: #6b7280; padding: 20px;")
            empty_label.setAlignment(Qt.AlignCenter)
            self.list_layout.addWidget(empty_label)
            self.status_label.setText("0 memories")
            return

        for mem in memories:
            card = self._create_memory_card(mem)
            self.list_layout.addWidget(card)

        label = f"{len(memories)} memories" if mode == "list" else f"{len(memories)} results"
        self.status_label.setText(label)

    def _create_memory_card(self, mem: dict) -> QFrame:
        """Create a card widget for a single memory"""
        card = QFrame()
        card.setFrameStyle(QFrame.StyledPanel)
        card.setStyleSheet("QFrame { border: 1px solid #e5e7eb; border-radius: 4px; padding: 6px; margin: 2px 0; }")

        card_layout = QVBoxLayout(card)
        card_layout.setContentsMargins(8, 6, 8, 6)
        card_layout.setSpacing(3)

        # Header: type badge + date
        header = QHBoxLayout()
        mem_type = mem.get("experience_type", mem.get("type", "?"))
        type_label = QLabel(mem_type)
        type_colors = {
            "Learning": "#22c55e", "Decision": "#3b82f6",
            "Observation": "#f59e0b", "Event": "#a855f7"
        }
        color = type_colors.get(mem_type, "#6b7280")
        type_label.setStyleSheet(f"color: white; background-color: {color}; border-radius: 3px; padding: 1px 6px; font-size: 10px; font-weight: bold;")
        header.addWidget(type_label)
        header.addStretch()

        created = mem.get("created_at", "")
        if created:
            try:
                dt = datetime.fromisoformat(created.replace("Z", "+00:00"))
                date_str = dt.strftime("%Y-%m-%d %H:%M")
            except Exception:
                date_str = created[:16]
            date_label = QLabel(date_str)
            date_label.setStyleSheet("color: #9ca3af; font-size: 10px;")
            header.addWidget(date_label)
        card_layout.addLayout(header)

        # Content
        content = mem.get("content", "")
        content_label = QLabel(content[:200] + ("..." if len(content) > 200 else ""))
        content_label.setWordWrap(True)
        content_label.setStyleSheet("font-size: 12px;")
        card_layout.addWidget(content_label)

        # Tags
        tags = mem.get("tags", [])
        if tags:
            tags_str = " ".join(f"#{t}" for t in tags)
            tags_label = QLabel(tags_str)
            tags_label.setStyleSheet("color: #6b7280; font-size: 10px;")
            card_layout.addWidget(tags_label)

        return card


class RememberNoteDialog(QDialog):
    """Dialog to save a manual memory note"""

    def __init__(self, parent, project: str):
        super().__init__(parent)
        self.project = project
        self.setWindowTitle(f"Remember Note: {project}")
        self.setWindowFlags(self.windowFlags() | Qt.WindowStaysOnTopHint)
        self.setMinimumSize(400, 300)
        self.resize(450, 350)
        self._setup_ui()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        # Type selector
        type_layout = QHBoxLayout()
        type_layout.addWidget(QLabel("Type:"))
        self.type_combo = QComboBox()
        self.type_combo.addItems(["Learning", "Decision", "Observation", "Event"])
        type_layout.addWidget(self.type_combo)
        type_layout.addStretch()
        layout.addLayout(type_layout)

        # Content
        layout.addWidget(QLabel("Content:"))
        self.content_edit = QTextEdit()
        self.content_edit.setPlaceholderText("What did you learn, decide, or observe?")
        layout.addWidget(self.content_edit)

        # Tags
        tags_layout = QHBoxLayout()
        tags_layout.addWidget(QLabel("Tags:"))
        self.tags_input = QLineEdit()
        self.tags_input.setPlaceholderText("comma-separated (optional)")
        tags_layout.addWidget(self.tags_input)
        layout.addLayout(tags_layout)

        # Buttons
        btn_layout = QHBoxLayout()
        btn_layout.addStretch()
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        btn_layout.addWidget(cancel_btn)
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self._on_save)
        save_btn.setDefault(True)
        btn_layout.addWidget(save_btn)
        layout.addLayout(btn_layout)

    def _on_save(self):
        content = self.content_edit.toPlainText().strip()
        if not content:
            return

        mem_type = self.type_combo.currentText()
        tags = self.tags_input.text().strip()

        args = ["--project", self.project, "remember", "--type", mem_type]
        if tags:
            args.extend(["--tags", tags])

        try:
            subprocess.run(
                [str(SCRIPT_DIR / "wt-memory")] + args,
                input=content, text=True, timeout=10,
                capture_output=True
            )
        except Exception:
            pass

        self.accept()
