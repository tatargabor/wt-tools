"""
Window Property Tests - Verify window flags, size, position persistence
"""

import json
import sys

import pytest
from PySide6.QtCore import Qt


def test_always_on_top(control_center):
    """Window should have WindowStaysOnTopHint flag."""
    assert control_center.windowFlags() & Qt.WindowStaysOnTopHint


def test_frameless(control_center):
    """Window should have FramelessWindowHint flag."""
    assert control_center.windowFlags() & Qt.FramelessWindowHint


def test_tool_window(control_center):
    """Window should have Tool flag."""
    assert control_center.windowFlags() & Qt.Tool


def test_fixed_width(control_center):
    """Window width should match config window_width."""
    expected_width = control_center.config.control_center["window_width"]
    assert control_center.width() == expected_width


def test_window_title_contains_version(control_center):
    """Window title should contain 'Worktree Control Center'."""
    title = control_center.windowTitle()
    assert "Worktree Control Center" in title


def test_opacity_set(control_center):
    """Window opacity should match config opacity_default."""
    expected = control_center.config.control_center["opacity_default"]
    assert abs(control_center.windowOpacity() - expected) < 0.01


def test_position_saved_and_restored(control_center):
    """Position should persist: move -> save -> verify file contents.

    We verify the file is written correctly. The actual window position
    on restore may differ due to window manager constraints (macOS menu bar,
    screen bounds), so we only check the file was saved correctly.
    """
    original_pos = (control_center.x(), control_center.y())

    control_center.move(142, 253)
    control_center.save_position()

    # Verify position file was written with correct values
    pos_file = control_center.POSITION_FILE
    assert pos_file.exists(), f"Position file not found at {pos_file}"
    data = json.loads(pos_file.read_text())
    assert data["x"] == 142
    assert data["y"] == 253

    # Restore original position (module-scoped fixture)
    control_center.move(*original_pos)


def test_no_pause_resume_methods(control_center):
    """pause/resume_always_on_top methods should not exist (removed in favor of window levels)."""
    assert not hasattr(control_center, 'pause_always_on_top'), \
        "pause_always_on_top should have been removed"
    assert not hasattr(control_center, 'resume_always_on_top'), \
        "resume_always_on_top should have been removed"


def test_no_front_timer(control_center):
    """The orderFrontRegardless timer should not exist."""
    assert not hasattr(control_center, '_front_timer'), \
        "_front_timer should have been removed"


def test_enforce_native_level_method(control_center):
    """_enforce_native_level method should exist for level drift correction."""
    assert hasattr(control_center, '_enforce_native_level')
    assert callable(control_center._enforce_native_level)


def test_on_app_state_changed_method(control_center):
    """_on_app_state_changed method should exist for activation state handling."""
    assert hasattr(control_center, '_on_app_state_changed')
    assert callable(control_center._on_app_state_changed)


@pytest.mark.skipif(sys.platform != "darwin", reason="macOS-only test")
def test_level_enforce_timer_running(control_center):
    """Periodic level enforcement timer should be active on macOS."""
    assert hasattr(control_center, '_level_enforce_timer'), \
        "_level_enforce_timer should exist"
    assert control_center._level_enforce_timer.isActive(), \
        "_level_enforce_timer should be running"
    assert control_center._level_enforce_timer.interval() == 5000, \
        "Timer interval should be 5000ms"


@pytest.mark.skipif(sys.platform != "darwin", reason="macOS-only test")
def test_ns_window_level_is_status(control_center):
    """On macOS, NSWindow level should be 25 (NSStatusWindowLevel)."""
    ns_window = control_center._get_ns_window()
    if ns_window is None:
        pytest.skip("pyobjc not available")
    assert ns_window.level() == 25, \
        f"Expected NSStatusWindowLevel (25), got {ns_window.level()}"

    # Simulate Qt6 resetting the level, then verify enforcement corrects it
    ns_window.setLevel_(8)  # Qt6's default for WindowStaysOnTopHint
    assert ns_window.level() == 8
    control_center._enforce_native_level()
    assert ns_window.level() == 25, \
        "enforce_native_level should restore level to 25 after drift"
