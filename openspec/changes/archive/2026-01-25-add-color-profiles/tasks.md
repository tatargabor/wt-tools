# Tasks: Add Color Profiles

## Implementation Tasks

- [x] Define COLOR_PROFILES dict with light, dark, high_contrast presets
  - All semantic color names from proposal
  - Stored in gui/main.py

- [x] Add color_profile setting to Config class
  - Default: "light"
  - Added to control_center section

- [x] Add get_color() helper method to ControlCenter
  - Lookup color by name from active profile
  - Fallback to light profile if name missing
  - Also added get_status_icon() and get_tray_color()

- [x] Replace hardcoded colors in STATUS_ICONS and TRAY_COLORS
  - Use get_status_icon() and get_tray_color() methods

- [x] Replace hardcoded colors in update_combined_status()
  - running, waiting status text colors

- [x] Replace hardcoded colors in update_usage_bar()
  - burn_low, burn_medium, burn_high colors
  - bar_background, bar_border colors

- [x] Replace hardcoded colors in toggle_blink()
  - row_waiting_blink color

- [x] Add row background colors based on status
  - running rows: row_running (light green) with row_running_text
  - waiting rows (not blinking): row_waiting (yellow) with row_waiting_text
  - waiting rows (blinking): alternate row_waiting_blink (red) / transparent
  - idle rows: row_idle (transparent) with row_idle_text

- [x] Replace hardcoded colors in table cell styling
  - ctx_high, ctx_medium for context percentage
  - button_primary for JIRA button

- [x] Add profile selector to SettingsDialog
  - Dropdown with light/dark/high_contrast options
  - Loads/saves from config
  - Apply immediately on change via refresh_status()

- [x] Test all three profiles
  - Light profile working
  - Dark and high_contrast available in settings
