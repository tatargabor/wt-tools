"""
Color Coverage Tests - Verify all get_color() keys exist in all profiles
"""

import re
from pathlib import Path

from gui.constants import COLOR_PROFILES


# All color keys referenced by get_color() in the codebase (extracted by grep)
USED_COLOR_KEYS = {
    # Status colors
    "status_running", "status_waiting", "status_compacting",
    "status_idle", "status_done", "status_stalled",
    "status_idle_ide", "status_orphan",
    # Burn rate
    "burn_low", "burn_medium", "burn_high",
    # UI elements
    "bar_background", "bar_border", "border",
    "button_primary", "button_primary_text",
    # Text
    "text_primary", "text_muted", "text_secondary", "text_warning",
    # Context usage
    "ctx_high", "ctx_medium",
    # Background
    "bg_dialog",
    # Row backgrounds
    "row_running", "row_running_text",
    "row_waiting", "row_waiting_text", "row_waiting_blink",
    "row_compacting", "row_compacting_text",
    "row_idle", "row_idle_text",
    "row_idle_ide", "row_idle_ide_text",
    "row_orphan", "row_orphan_text",
}


def test_all_profiles_have_all_used_keys():
    """Every color key used in code must exist in every profile."""
    for profile_name, profile in COLOR_PROFILES.items():
        missing = USED_COLOR_KEYS - set(profile.keys())
        assert not missing, (
            f"Profile '{profile_name}' is missing color keys: {sorted(missing)}"
        )


def test_no_fallback_to_black():
    """No profile should return #000000 for any used key (the fallback color)."""
    for profile_name, profile in COLOR_PROFILES.items():
        black_keys = [k for k in USED_COLOR_KEYS if profile.get(k) == "#000000"]
        assert not black_keys, (
            f"Profile '{profile_name}' has #000000 (fallback) for: {black_keys}"
        )


def test_color_keys_in_code_match_expected():
    """Scan GUI source for get_color() calls and verify they're all in USED_COLOR_KEYS.

    This catches newly added get_color() calls that aren't in the test's key set.
    """
    gui_dir = Path(__file__).parent.parent.parent / "gui"
    pattern = re.compile(r'get_color\(["\']([^"\']+)["\']\)')

    found_keys = set()
    for py_file in gui_dir.rglob("*.py"):
        if "main_old" in py_file.name:
            continue
        content = py_file.read_text()
        found_keys.update(pattern.findall(content))

    uncovered = found_keys - USED_COLOR_KEYS
    assert not uncovered, (
        f"get_color() keys found in code but not in test coverage: {sorted(uncovered)}"
    )
