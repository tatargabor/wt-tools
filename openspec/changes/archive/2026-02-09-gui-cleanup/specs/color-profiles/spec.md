## MODIFIED Requirements

### Requirement: Preset Color Profiles
The system SHALL provide four preset color profiles: light, gray, dark, and high_contrast. Each profile SHALL define all semantic color keys used by the application, including `text_secondary` and `text_primary`.

#### Scenario: Light profile colors
Given the color profile is set to "light"
Then status_running color is green (#22c55e)
And status_waiting color is orange (#f59e0b)
And bar_background is light gray (#e5e7eb)
And text_secondary is blue (#60a5fa)
And text_primary is dark gray (#1f2937)

#### Scenario: Dark profile colors
Given the color profile is set to "dark"
Then status_running color is lighter green (#4ade80)
And status_waiting color is lighter orange (#fbbf24)
And bar_background is dark gray (#374151)
And text_secondary is blue (#60a5fa)
And text_primary is near-white (#f9fafb)

#### Scenario: High contrast profile colors
Given the color profile is set to "high_contrast"
Then text_primary is white (#ffffff)
And text_secondary is bright blue (#00aaff)
And bg_dialog is very dark (#222222)

## ADDED Requirements

### Requirement: Complete Color Key Coverage
Every color key referenced by `get_color()` in the application code SHALL be defined in all color profiles. The fallback value `#000000` SHALL NOT be relied upon for any production color key.

#### Scenario: text_secondary is defined in all profiles
- **WHEN** `get_color("text_secondary")` is called
- **THEN** a themed color value is returned for any active profile
- **AND** the value is never the `#000000` fallback

#### Scenario: text_primary is defined in all profiles
- **WHEN** `get_color("text_primary")` is called
- **THEN** a themed color value is returned for any active profile
- **AND** the high_contrast profile returns a light color suitable for dark backgrounds
