"""
Test dialog helpers - verify always-on-top wrappers set WindowStaysOnTopHint.
"""

from unittest.mock import patch

import pytest
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QMessageBox, QInputDialog, QFileDialog

from gui.dialogs.helpers import (
    show_warning, show_information, show_question,
    get_text, get_item, get_existing_directory, get_open_filename,
)


class TestShowWarning:
    def test_sets_window_stays_on_top(self):
        with patch.object(QMessageBox, 'exec', return_value=QMessageBox.Ok):
            with patch.object(QMessageBox, 'setWindowFlags') as mock_flags:
                show_warning(None, "Title", "Text")

        assert mock_flags.called
        flags_arg = mock_flags.call_args[0][0]
        assert flags_arg & Qt.WindowStaysOnTopHint

    def test_returns_exec_result(self):
        with patch.object(QMessageBox, 'exec', return_value=QMessageBox.Ok):
            result = show_warning(None, "Title", "Text")
        assert result == QMessageBox.Ok


class TestShowInformation:
    def test_sets_window_stays_on_top(self):
        with patch.object(QMessageBox, 'exec', return_value=QMessageBox.Ok):
            with patch.object(QMessageBox, 'setWindowFlags') as mock_flags:
                show_information(None, "Title", "Text")

        assert mock_flags.called
        flags_arg = mock_flags.call_args[0][0]
        assert flags_arg & Qt.WindowStaysOnTopHint


class TestShowQuestion:
    def test_sets_window_stays_on_top(self):
        with patch.object(QMessageBox, 'exec', return_value=QMessageBox.Yes):
            with patch.object(QMessageBox, 'setWindowFlags') as mock_flags:
                show_question(None, "Title", "Question?")

        assert mock_flags.called
        flags_arg = mock_flags.call_args[0][0]
        assert flags_arg & Qt.WindowStaysOnTopHint

    def test_passes_buttons_and_default(self):
        with patch.object(QMessageBox, 'exec', return_value=QMessageBox.No):
            with patch.object(QMessageBox, 'setDefaultButton') as mock_default:
                show_question(
                    None, "Title", "Q?",
                    QMessageBox.Yes | QMessageBox.No,
                    QMessageBox.No,
                )
        assert mock_default.called


class TestGetText:
    def test_returns_tuple(self):
        with patch.object(QInputDialog, 'exec', return_value=QInputDialog.Accepted):
            with patch.object(QInputDialog, 'textValue', return_value="hello"):
                text, ok = get_text(None, "Title", "Label")
        assert ok is True
        assert text == "hello"

    def test_sets_window_stays_on_top(self):
        with patch.object(QInputDialog, 'exec', return_value=QInputDialog.Accepted):
            with patch.object(QInputDialog, 'textValue', return_value=""):
                with patch.object(QInputDialog, 'setWindowFlags') as mock_flags:
                    get_text(None, "Title", "Label")

        assert mock_flags.called
        flags_arg = mock_flags.call_args[0][0]
        assert flags_arg & Qt.WindowStaysOnTopHint


class TestGetItem:
    def test_returns_tuple(self):
        with patch.object(QInputDialog, 'exec', return_value=QInputDialog.Rejected):
            with patch.object(QInputDialog, 'textValue', return_value=""):
                item, ok = get_item(None, "Title", "Label", ["a", "b"])
        assert ok is False

    def test_sets_window_stays_on_top(self):
        with patch.object(QInputDialog, 'exec', return_value=QInputDialog.Accepted):
            with patch.object(QInputDialog, 'textValue', return_value="item1"):
                with patch.object(QInputDialog, 'setWindowFlags') as mock_flags:
                    get_item(None, "Title", "Label", ["item1", "item2"])

        assert mock_flags.called
        flags_arg = mock_flags.call_args[0][0]
        assert flags_arg & Qt.WindowStaysOnTopHint


class TestGetExistingDirectory:
    def test_returns_empty_on_reject(self):
        with patch.object(QFileDialog, 'exec', return_value=QFileDialog.Rejected):
            result = get_existing_directory(None, "Select")
        assert result == ""


class TestGetOpenFilename:
    def test_returns_empty_on_reject(self):
        with patch.object(QFileDialog, 'exec', return_value=QFileDialog.Rejected):
            filename, filter_ = get_open_filename(None, "Open")
        assert filename == ""
        assert filter_ == ""
