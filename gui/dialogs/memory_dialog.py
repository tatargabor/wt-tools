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

# Badge colors for memory types
_TYPE_COLORS = {
    "Learning": "#22c55e",
    "Decision": "#3b82f6",
    "Context": "#f59e0b",
}

# Page size for list pagination
_PAGE_SIZE = 50


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
    """Dialog to browse and search project memories.

    Two view modes:
    - Summary (default): grouped context summary from wt-memory context
    - List: paginated card list from wt-memory list (50 at a time)

    Search overrides both views with recall results.
    """

    # View modes
    MODE_SUMMARY = "summary"
    MODE_LIST = "list"
    MODE_SEARCH = "search"

    def __init__(self, parent, project: str):
        super().__init__(parent)
        self.project = project
        self.setWindowTitle(f"Memory: {project}")
        self.setWindowFlags(self.windowFlags() | Qt.WindowStaysOnTopHint)
        self.setMinimumSize(500, 400)
        self.resize(550, 500)

        # State
        self._mode = self.MODE_SUMMARY
        self._pre_search_mode = self.MODE_SUMMARY  # mode to return to after clearing search
        self._cached_memories = []  # full list cache for pagination
        self._rendered_count = 0  # how many cards rendered in list mode

        self._setup_ui()
        self._load_summary()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        # Top bar: search + toggle button
        top_layout = QHBoxLayout()

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Search memories (semantic)...")
        self.search_input.returnPressed.connect(self._on_search)
        top_layout.addWidget(self.search_input)

        clear_btn = QPushButton("Clear")
        clear_btn.setFixedWidth(60)
        clear_btn.clicked.connect(self._on_clear)
        top_layout.addWidget(clear_btn)

        self.toggle_btn = QPushButton("Show All")
        self.toggle_btn.setFixedWidth(80)
        self.toggle_btn.clicked.connect(self._on_toggle)
        top_layout.addWidget(self.toggle_btn)

        layout.addLayout(top_layout)

        # Scrollable content area
        self.scroll_area = QScrollArea()
        self.scroll_area.setWidgetResizable(True)
        self.scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.content_widget = QWidget()
        self.content_layout = QVBoxLayout(self.content_widget)
        self.content_layout.setAlignment(Qt.AlignTop)
        self.scroll_area.setWidget(self.content_widget)
        layout.addWidget(self.scroll_area)

        # Status bar
        self.status_label = QLabel("")
        self.status_label.setStyleSheet("color: #6b7280; font-size: 11px;")
        layout.addWidget(self.status_label)

        # Close button
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.close)
        layout.addWidget(close_btn)

    # ── View switching ──────────────────────────────────────────────

    def _on_toggle(self):
        """Toggle between summary and list views."""
        if self._mode == self.MODE_SUMMARY:
            self._load_list()
        else:
            self._load_summary()

    def _update_toggle_button(self):
        """Update toggle button text based on current mode."""
        if self._mode == self.MODE_SUMMARY:
            self.toggle_btn.setText("Show All")
        else:
            self.toggle_btn.setText("Summary")

    # ── Summary view (default) ──────────────────────────────────────

    def _load_summary(self):
        """Load context summary via wt-memory context."""
        self._mode = self.MODE_SUMMARY
        self._update_toggle_button()
        self._clear_content()

        output = _run_wt_memory("--project", self.project, "context")
        try:
            data = json.loads(output) if output else {}
        except json.JSONDecodeError:
            data = {}

        if data.get("error"):
            # context_summary not available — fall back to list
            self._load_list()
            return

        total = data.get("total_memories", 0)

        # Category display order and labels
        categories = [
            ("decisions", "Decisions", _TYPE_COLORS["Decision"]),
            ("learnings", "Learnings", _TYPE_COLORS["Learning"]),
            ("context", "Context", _TYPE_COLORS["Context"]),
        ]

        has_content = False
        for key, label, color in categories:
            items = data.get(key, [])
            if not items:
                continue
            has_content = True
            self._add_section_header(label, color)
            for item in items:
                card = self._create_memory_card(item, type_override=label.rstrip("s"))
                self.content_layout.addWidget(card)

        if not has_content:
            empty_label = QLabel("No memories yet.")
            empty_label.setStyleSheet("color: #6b7280; padding: 20px;")
            empty_label.setAlignment(Qt.AlignCenter)
            self.content_layout.addWidget(empty_label)

        self.status_label.setText(f"Summary — {total} total memories")

    def _add_section_header(self, label: str, color: str):
        """Add a colored section header to the content area."""
        header = QLabel(label)
        header.setStyleSheet(
            f"color: {color}; font-size: 13px; font-weight: bold; "
            f"padding: 8px 4px 2px 4px; border-bottom: 2px solid {color};"
        )
        self.content_layout.addWidget(header)

    # ── List view (paginated) ───────────────────────────────────────

    def _load_list(self):
        """Load all memories and show first page."""
        self._mode = self.MODE_LIST
        self._update_toggle_button()
        self._clear_content()

        # Fetch all if not cached
        if not self._cached_memories:
            output = _run_wt_memory("--project", self.project, "list")
            try:
                self._cached_memories = json.loads(output) if output else []
            except json.JSONDecodeError:
                self._cached_memories = []

        self._rendered_count = 0

        if not self._cached_memories:
            empty_label = QLabel("No memories yet.")
            empty_label.setStyleSheet("color: #6b7280; padding: 20px;")
            empty_label.setAlignment(Qt.AlignCenter)
            self.content_layout.addWidget(empty_label)
            self.status_label.setText("0 memories")
            return

        self._render_next_page()

    def _render_next_page(self):
        """Render next batch of cards from cached memories."""
        total = len(self._cached_memories)
        end = min(self._rendered_count + _PAGE_SIZE, total)
        batch = self._cached_memories[self._rendered_count:end]

        # Remove existing "Load More" button if present
        self._remove_load_more()

        for mem in batch:
            card = self._create_memory_card(mem)
            self.content_layout.addWidget(card)

        self._rendered_count = end

        # Add "Load More" button if more remain
        if self._rendered_count < total:
            load_more = QPushButton(f"Load More (showing {self._rendered_count} of {total})")
            load_more.setObjectName("load_more_btn")
            load_more.clicked.connect(self._render_next_page)
            load_more.setStyleSheet("padding: 8px; margin: 8px 0;")
            self.content_layout.addWidget(load_more)

        self.status_label.setText(f"{self._rendered_count} of {total} memories")

    def _remove_load_more(self):
        """Remove the Load More button if it exists."""
        for i in range(self.content_layout.count()):
            item = self.content_layout.itemAt(i)
            if item and item.widget() and item.widget().objectName() == "load_more_btn":
                item.widget().deleteLater()
                self.content_layout.removeItem(item)
                break

    # ── Search ──────────────────────────────────────────────────────

    def _on_search(self):
        query = self.search_input.text().strip()
        if not query:
            self._on_clear()
            return

        # Remember which mode we were in before search
        if self._mode != self.MODE_SEARCH:
            self._pre_search_mode = self._mode

        self._mode = self.MODE_SEARCH
        self._update_toggle_button()
        self._clear_content()

        output = _run_wt_memory("--project", self.project, "recall", query, "--limit", "20")
        try:
            results = json.loads(output) if output else []
        except json.JSONDecodeError:
            results = []

        if not results:
            empty_label = QLabel("No results found.")
            empty_label.setStyleSheet("color: #6b7280; padding: 20px;")
            empty_label.setAlignment(Qt.AlignCenter)
            self.content_layout.addWidget(empty_label)
            self.status_label.setText("0 results")
            return

        for mem in results:
            card = self._create_memory_card(mem)
            self.content_layout.addWidget(card)

        self.status_label.setText(f"{len(results)} results")

    def _on_clear(self):
        self.search_input.clear()
        # Return to whichever mode we were in before searching
        if self._pre_search_mode == self.MODE_LIST:
            self._cached_memories = []  # refresh on return
            self._load_list()
        else:
            self._load_summary()

    # ── Shared helpers ──────────────────────────────────────────────

    def _clear_content(self):
        """Remove all widgets from the content area."""
        while self.content_layout.count():
            child = self.content_layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()

    def _create_memory_card(self, mem: dict, type_override: str = None) -> QFrame:
        """Create a card widget for a single memory."""
        card = QFrame()
        card.setFrameStyle(QFrame.StyledPanel)
        card.setStyleSheet(
            "QFrame { border: 1px solid #e5e7eb; border-radius: 4px; "
            "padding: 6px; margin: 2px 0; }"
        )

        card_layout = QVBoxLayout(card)
        card_layout.setContentsMargins(8, 6, 8, 6)
        card_layout.setSpacing(3)

        # Header: type badge + date
        header = QHBoxLayout()
        mem_type = type_override or mem.get("experience_type", mem.get("type", "?"))
        type_label = QLabel(mem_type)
        color = _TYPE_COLORS.get(mem_type, "#6b7280")
        type_label.setStyleSheet(
            f"color: white; background-color: {color}; border-radius: 3px; "
            f"padding: 1px 6px; font-size: 10px; font-weight: bold;"
        )
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
        self.resize(450, 350)
        self.setMinimumSize(400, 300)
        self._setup_ui()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        # Type selector
        type_layout = QHBoxLayout()
        type_layout.addWidget(QLabel("Type:"))
        self.type_combo = QComboBox()
        self.type_combo.addItems(["Learning", "Decision", "Context"])
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
