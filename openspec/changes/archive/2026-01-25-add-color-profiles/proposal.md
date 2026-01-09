# Proposal: Add Color Profiles

JIRA Key: EXAMPLE-565
Story: EXAMPLE-466

## Summary

Extract hardcoded colors from the Control Center GUI into named color profiles (themes). Users can select from preset profiles; custom editing is out of scope for now.

## Motivation

Currently ~20 color values are hardcoded throughout `gui/main.py`. This makes it difficult to:
- Support dark mode
- Maintain consistent styling
- Allow future customization

## Proposed Solution

### Color Profile Structure

Define color profiles in the Config class with semantic color names:

```python
COLOR_PROFILES = {
    "light": {
        # Status colors
        "status_running": "#22c55e",      # green
        "status_waiting": "#f59e0b",      # orange
        "status_idle": "#6b7280",         # gray
        "status_done": "#3b82f6",         # blue

        # Burn rate colors
        "burn_low": "#22c55e",            # green (<90%)
        "burn_medium": "#f59e0b",         # yellow (90-110%)
        "burn_high": "#ef4444",           # red (>110%)

        # UI element colors
        "bar_background": "#e5e7eb",
        "bar_border": "#cccccc",
        "blink_attention": "#fecaca",     # pale red

        # Text colors
        "text_muted": "#6b7280",
        "text_warning": "#b45309",

        # Button colors
        "button_primary": "#3b82f6",
        "button_primary_text": "#ffffff",

        # Context usage colors
        "ctx_high": "#ef4444",            # >80%
        "ctx_medium": "#f59e0b",          # >60%

        # Background
        "bg_dialog": "#f0f0f0",

        # Row background colors by status
        "row_running": "#f3f4f6",         # light gray - still working
        "row_waiting": "#fef3c7",         # yellow - needs attention (not blinking)
        "row_waiting_blink": "#fecaca",   # pale red - blinking state
        "row_idle": "transparent",        # no background
    },
    "dark": {
        # Status colors (brighter for dark bg)
        "status_running": "#4ade80",      # lighter green
        "status_waiting": "#fbbf24",      # lighter orange
        "status_idle": "#9ca3af",         # lighter gray
        "status_done": "#60a5fa",         # lighter blue

        # Burn rate colors
        "burn_low": "#4ade80",
        "burn_medium": "#fbbf24",
        "burn_high": "#f87171",

        # UI element colors
        "bar_background": "#374151",
        "bar_border": "#4b5563",
        "blink_attention": "#7f1d1d",     # dark red

        # Text colors
        "text_muted": "#9ca3af",
        "text_warning": "#fbbf24",

        # Button colors
        "button_primary": "#3b82f6",
        "button_primary_text": "#ffffff",

        # Context usage colors
        "ctx_high": "#f87171",
        "ctx_medium": "#fbbf24",

        # Background
        "bg_dialog": "#1f2937",

        # Row background colors by status
        "row_running": "#374151",         # dark gray
        "row_waiting": "#78350f",         # dark yellow/brown
        "row_waiting_blink": "#7f1d1d",   # dark red
        "row_idle": "transparent",
    },
    "high_contrast": {
        # Maximum visibility
        "status_running": "#00ff00",
        "status_waiting": "#ffff00",
        "status_idle": "#888888",
        "status_done": "#00aaff",

        "burn_low": "#00ff00",
        "burn_medium": "#ffff00",
        "burn_high": "#ff0000",

        "bar_background": "#333333",
        "bar_border": "#ffffff",
        "blink_attention": "#ff6666",

        "text_muted": "#aaaaaa",
        "text_warning": "#ffaa00",

        "button_primary": "#0066cc",
        "button_primary_text": "#ffffff",

        "ctx_high": "#ff0000",
        "ctx_medium": "#ffaa00",

        "bg_dialog": "#222222",

        # Row background colors by status
        "row_running": "#444444",
        "row_waiting": "#666600",
        "row_waiting_blink": "#660000",
        "row_idle": "transparent",
    }
}
```

### Config Integration

Add `color_profile` setting to control_center config:

```python
"control_center": {
    ...
    "color_profile": "light",  # light | dark | high_contrast
}
```

### Helper Method

Add `get_color(name)` method to ControlCenter class:

```python
def get_color(self, name: str) -> str:
    profile = self.config.control_center.get("color_profile", "light")
    return COLOR_PROFILES[profile].get(name, "#000000")
```

### Usage Example

Before:
```python
color = "#22c55e"  # green
```

After:
```python
color = self.get_color("status_running")
```

## Scope

### In Scope
- Define 3 preset profiles: light, dark, high_contrast
- Extract all hardcoded colors to use profile
- Add profile selector to config dialog
- Persist profile selection

### Out of Scope
- Custom color editing UI
- Per-color overrides
- Auto dark mode detection (OS integration)

## Alternatives Considered

1. **Qt stylesheets file**: More complex, harder to maintain dynamic changes
2. **Full theme engine**: Overkill for current needs
3. **OS dark mode detection**: Can be added later on top of profiles
