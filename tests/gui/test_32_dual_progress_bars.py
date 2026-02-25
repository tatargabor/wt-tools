"""
Dual Progress Bars Tests - Verify time-elapsed + usage dual bars
"""

from datetime import datetime, timezone, timedelta

from PySide6.QtWidgets import QLabel


def test_dual_bars_exist(control_center):
    """All 4 progress bars (2 time + 2 usage) should exist."""
    assert hasattr(control_center, 'usage_5h_time_bar')
    assert hasattr(control_center, 'usage_7d_time_bar')
    assert hasattr(control_center, 'usage_5h_bar')
    assert hasattr(control_center, 'usage_7d_bar')
    assert isinstance(control_center.usage_5h_time_bar, QLabel)
    assert isinstance(control_center.usage_7d_time_bar, QLabel)


def test_dual_labels_exist(control_center):
    """All 4 labels (2 time + 2 usage) should exist."""
    assert hasattr(control_center, 'usage_5h_time_label')
    assert hasattr(control_center, 'usage_7d_time_label')
    assert hasattr(control_center, 'usage_5h_label')
    assert hasattr(control_center, 'usage_7d_label')


def test_bar_height_is_6px(control_center):
    """All bars should be 6px height (not the old 8px)."""
    for bar in (control_center.usage_5h_bar, control_center.usage_7d_bar,
                control_center.usage_5h_time_bar, control_center.usage_7d_time_bar):
        assert bar.maximumHeight() == 6


def test_time_elapsed_pct_midpoint(control_center):
    """calc_time_elapsed_pct should return ~50% when halfway through window."""
    now = datetime.now(timezone.utc)
    # Reset is 2.5h from now in a 5h window → 50% elapsed
    reset = (now + timedelta(hours=2.5)).isoformat()
    pct = control_center.calc_time_elapsed_pct(reset, 5)
    assert 45 <= pct <= 55, f"Expected ~50%, got {pct}"


def test_time_elapsed_pct_near_start(control_center):
    """calc_time_elapsed_pct should return ~0% right after reset."""
    now = datetime.now(timezone.utc)
    # Reset is almost 5h away → just started
    reset = (now + timedelta(hours=4, minutes=59)).isoformat()
    pct = control_center.calc_time_elapsed_pct(reset, 5)
    assert pct < 5, f"Expected ~0%, got {pct}"


def test_time_elapsed_pct_near_end(control_center):
    """calc_time_elapsed_pct should return ~100% just before reset."""
    now = datetime.now(timezone.utc)
    # Reset is 1 minute away → almost done
    reset = (now + timedelta(minutes=1)).isoformat()
    pct = control_center.calc_time_elapsed_pct(reset, 5)
    assert pct > 95, f"Expected ~100%, got {pct}"


def test_time_elapsed_pct_clamped(control_center):
    """calc_time_elapsed_pct should clamp to 0-100."""
    # Past reset → should clamp to 100
    past = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
    assert control_center.calc_time_elapsed_pct(past, 5) == 100

    # None → should return 0
    assert control_center.calc_time_elapsed_pct(None, 5) == 0


def test_burn_rate_color_under_pace(control_center):
    """Usage bar should be green when usage < time - 5."""
    # usage=30%, time=60% → well under pace → green (burn_low)
    control_center.update_usage_bar(control_center.usage_5h_bar, 30, 60)
    style = control_center.usage_5h_bar.styleSheet()
    green = control_center.get_color("burn_low")
    assert green in style, f"Expected green ({green}) in style, got: {style}"


def test_burn_rate_color_on_pace(control_center):
    """Usage bar should be yellow when usage ≈ time."""
    # usage=58%, time=60% → within 5 points → yellow (burn_medium)
    control_center.update_usage_bar(control_center.usage_5h_bar, 58, 60)
    style = control_center.usage_5h_bar.styleSheet()
    yellow = control_center.get_color("burn_medium")
    assert yellow in style, f"Expected yellow ({yellow}) in style, got: {style}"


def test_burn_rate_color_over_pace(control_center):
    """Usage bar should be red when usage > time + 5."""
    # usage=80%, time=60% → over pace → red (burn_high)
    control_center.update_usage_bar(control_center.usage_5h_bar, 80, 60)
    style = control_center.usage_5h_bar.styleSheet()
    red = control_center.get_color("burn_high")
    assert red in style, f"Expected red ({red}) in style, got: {style}"


def test_fallback_no_api_data(control_center):
    """When no API data, labels show -- and --/5h, --/7d."""
    control_center.update_usage({"available": False})
    assert control_center.usage_5h_time_label.text() == "--"
    assert control_center.usage_7d_time_label.text() == "--"
    assert control_center.usage_5h_label.text() == "--/5h"
    assert control_center.usage_7d_label.text() == "--/7d"


def test_fallback_estimated(control_center):
    """When estimated (no session key), labels show -- with tooltips."""
    control_center.update_usage({
        "available": True,
        "is_estimated": True,
        "session_tokens": 150000,
        "weekly_tokens": 1000000,
    })
    assert control_center.usage_5h_time_label.text() == "--"
    assert control_center.usage_5h_label.text() == "--/5h"
    assert "150k" in control_center.usage_5h_label.toolTip()
    assert "1000k" in control_center.usage_7d_label.toolTip()


def test_api_data_labels_format(control_center):
    """With API data, time label shows 'X%, Yh' and usage label shows 'Z%'."""
    now = datetime.now(timezone.utc)
    control_center.update_usage({
        "available": True,
        "session_pct": 42,
        "weekly_pct": 55,
        "session_reset": (now + timedelta(hours=2)).isoformat(),
        "weekly_reset": (now + timedelta(days=2)).isoformat(),
    })
    # Usage labels should be just percentage
    assert control_center.usage_5h_label.text() == "42%"
    assert control_center.usage_7d_label.text() == "55%"
    # Time labels should show just remaining time (bar shows the %)
    time_5h = control_center.usage_5h_time_label.text()
    assert "h" in time_5h or "m" in time_5h, f"Expected time like '2h 0m', got: {time_5h}"


def test_bar_time_color_in_all_profiles(control_center):
    """bar_time color should exist in all theme profiles."""
    from gui.constants import COLOR_PROFILES
    for profile_name, profile in COLOR_PROFILES.items():
        assert "bar_time" in profile, f"bar_time missing from {profile_name} profile"
