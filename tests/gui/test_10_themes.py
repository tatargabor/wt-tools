"""
Theme Tests - Verify all 4 color profiles apply correctly
"""

from gui.constants import COLOR_PROFILES


def test_light_theme_applies(control_center, qtbot):
    """Light theme should apply without error and set correct background."""
    control_center.config.control_center["color_profile"] = "light"
    control_center.apply_theme()
    qtbot.wait(50)

    bg = COLOR_PROFILES["light"]["bg_dialog"]
    assert bg in control_center.styleSheet()


def test_dark_theme_applies(control_center, qtbot):
    """Dark theme should apply without error and set correct background."""
    control_center.config.control_center["color_profile"] = "dark"
    control_center.apply_theme()
    qtbot.wait(50)

    bg = COLOR_PROFILES["dark"]["bg_dialog"]
    assert bg in control_center.styleSheet()


def test_gray_theme_applies(control_center, qtbot):
    """Gray theme should apply without error and set correct background."""
    control_center.config.control_center["color_profile"] = "gray"
    control_center.apply_theme()
    qtbot.wait(50)

    bg = COLOR_PROFILES["gray"]["bg_dialog"]
    assert bg in control_center.styleSheet()


def test_high_contrast_theme_applies(control_center, qtbot):
    """High contrast theme should apply without error and set correct background."""
    control_center.config.control_center["color_profile"] = "high_contrast"
    control_center.apply_theme()
    qtbot.wait(50)

    bg = COLOR_PROFILES["high_contrast"]["bg_dialog"]
    assert bg in control_center.styleSheet()


def test_theme_switch_at_runtime(control_center, qtbot):
    """Switching from light to dark at runtime should change the stylesheet."""
    control_center.config.control_center["color_profile"] = "light"
    control_center.apply_theme()
    qtbot.wait(50)
    light_style = control_center.styleSheet()

    control_center.config.control_center["color_profile"] = "dark"
    control_center.apply_theme()
    qtbot.wait(50)
    dark_style = control_center.styleSheet()

    assert light_style != dark_style, "Stylesheet should change when switching themes"
