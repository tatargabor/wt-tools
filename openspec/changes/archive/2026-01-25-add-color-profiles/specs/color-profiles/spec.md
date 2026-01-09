# Color Profiles

## ADDED Requirements

### Requirement: Color Profile Selection
The Control Center SHALL support multiple color profiles (themes) that can be selected from the config dialog.

#### Scenario: User selects dark profile
Given the Control Center is running with light profile
When the user opens config dialog and selects "dark" profile
Then all UI colors change to dark theme variants
And the selection is persisted for next launch

### Requirement: Preset Color Profiles
The system SHALL provide three preset color profiles: light (default), dark, and high_contrast.

#### Scenario: Light profile colors
Given the color profile is set to "light"
Then status_running color is green (#22c55e)
And status_waiting color is orange (#f59e0b)
And bar_background is light gray (#e5e7eb)

#### Scenario: Dark profile colors
Given the color profile is set to "dark"
Then status_running color is lighter green (#4ade80)
And status_waiting color is lighter orange (#fbbf24)
And bar_background is dark gray (#374151)

### Requirement: Semantic Color Names
All colors SHALL be referenced by semantic names (e.g., "status_running", "burn_high") rather than hardcoded hex values.

#### Scenario: Color lookup
Given a component needs the running status color
When it calls get_color("status_running")
Then it receives the hex color for the active profile

### Requirement: Row Background Colors by Status
Table rows SHALL have background colors based on worktree status.

#### Scenario: Running worktree row
Given a worktree has status "running"
Then its row background is gray (row_running color)

#### Scenario: Waiting worktree row not blinking
Given a worktree has status "waiting"
And it is not in the needs_attention set
Then its row background is yellow (row_waiting color)

#### Scenario: Waiting worktree row blinking
Given a worktree has status "waiting"
And it is in the needs_attention set
When blink state is on
Then its row background is red (row_waiting_blink color)
When blink state is off
Then its row background is transparent

#### Scenario: Idle worktree row
Given a worktree has status "idle"
Then its row background is transparent (row_idle color)
