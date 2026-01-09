"""
Always-on-top dialog helpers for macOS compatibility.

The Control Center uses NSStatusWindowLevel (25) via native API.
Qt's WindowStaysOnTopHint only sets NSFloatingWindowLevel (~3-8),
which is BELOW the CC. Dialogs must be raised to level 26 via
native NSWindow API so they appear above the CC and receive input.

Usage:
    from gui.dialogs.helpers import show_warning, show_question, get_text
    show_warning(self, "Error", "Something went wrong")
"""

import sys
from PySide6.QtWidgets import QMessageBox, QInputDialog, QFileDialog
from PySide6.QtCore import Qt


def _raise_above_cc(widget):
    """Set native NSWindow level to 26 (above CC's 25) on macOS."""
    if sys.platform != "darwin":
        return
    try:
        from objc import objc_object  # noqa: F401
        ns_view = int(widget.winId())
        from AppKit import NSApp
        for win in NSApp.windows():
            if win.windowNumber() == ns_view:
                win.setLevel_(26)
                return
    except Exception:
        pass


def _exec_above_cc(widget):
    """Show widget, raise above CC, then exec modally."""
    widget.setWindowFlags(widget.windowFlags() | Qt.WindowStaysOnTopHint)
    widget.show()
    _raise_above_cc(widget)
    return widget.exec()


def show_warning(parent, title, text):
    """QMessageBox.warning() above Control Center."""
    box = QMessageBox(QMessageBox.Warning, title, text, QMessageBox.Ok, parent)
    return _exec_above_cc(box)


def show_information(parent, title, text):
    """QMessageBox.information() above Control Center."""
    box = QMessageBox(QMessageBox.Information, title, text, QMessageBox.Ok, parent)
    return _exec_above_cc(box)


def show_question(parent, title, text, buttons=None, default=None):
    """QMessageBox.question() above Control Center."""
    if buttons is None:
        buttons = QMessageBox.Yes | QMessageBox.No
    box = QMessageBox(QMessageBox.Question, title, text, buttons, parent)
    if default is not None:
        box.setDefaultButton(default)
    return _exec_above_cc(box)


def get_text(parent, title, label, **kwargs):
    """QInputDialog.getText() above Control Center.

    Returns (text, ok) tuple like the original.
    """
    dlg = QInputDialog(parent)
    dlg.setWindowTitle(title)
    dlg.setLabelText(label)
    if kwargs.get('text'):
        dlg.setTextValue(kwargs['text'])
    if kwargs.get('echo'):
        dlg.setTextEchoMode(kwargs['echo'])
    ok = _exec_above_cc(dlg) == QInputDialog.Accepted
    return dlg.textValue(), ok


def get_item(parent, title, label, items, current=0, editable=False):
    """QInputDialog.getItem() above Control Center.

    Returns (item, ok) tuple like the original.
    """
    dlg = QInputDialog(parent)
    dlg.setWindowTitle(title)
    dlg.setLabelText(label)
    dlg.setComboBoxItems(items)
    dlg.setComboBoxEditable(editable)
    if 0 <= current < len(items):
        dlg.setTextValue(items[current])
    ok = _exec_above_cc(dlg) == QInputDialog.Accepted
    return dlg.textValue(), ok


def get_existing_directory(parent, caption="", directory="", options=None):
    """QFileDialog.getExistingDirectory() above Control Center."""
    dlg = QFileDialog(parent, caption, directory)
    dlg.setFileMode(QFileDialog.Directory)
    if options is not None:
        dlg.setOptions(options)
    if _exec_above_cc(dlg) == QFileDialog.Accepted:
        dirs = dlg.selectedFiles()
        return dirs[0] if dirs else ""
    return ""


def get_open_filename(parent, caption="", directory="", filter=""):
    """QFileDialog.getOpenFileName() above Control Center.

    Returns (filename, selected_filter) tuple like the original.
    """
    dlg = QFileDialog(parent, caption, directory, filter)
    dlg.setFileMode(QFileDialog.ExistingFile)
    if _exec_above_cc(dlg) == QFileDialog.Accepted:
        files = dlg.selectedFiles()
        return (files[0] if files else "", dlg.selectedNameFilter())
    return ("", "")
