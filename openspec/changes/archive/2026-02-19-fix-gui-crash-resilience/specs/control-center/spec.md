## ADDED Requirements

### Requirement: Signal handler error boundaries
All Qt signal handler methods that process background worker results SHALL be wrapped with try/except error handling that logs the exception at ERROR level and continues execution. The UI SHALL NOT crash or freeze due to a single malformed worker result.

#### Scenario: Worker emits bad data
- **WHEN** a background worker emits a signal with unexpected or malformed data
- **THEN** the signal handler logs the exception at ERROR level to the wt-control logger
- **AND** the UI continues operating with the last known good state

#### Scenario: Table rebuild exception
- **WHEN** `refresh_table_display()` throws an exception during rendering
- **THEN** the exception is caught and logged
- **AND** the table retains its previous state rather than being left half-rendered

### Requirement: Opaque table cell backgrounds
All table cell backgrounds SHALL use fully opaque colors (alpha=255). No alpha-transparent colors SHALL be used for QTableWidgetItem backgrounds. When a transparent background is requested, it SHALL be replaced with the current theme's `bg_dialog` color.

#### Scenario: Idle row background on Linux X11
- **WHEN** an idle worktree row is rendered on a frameless window
- **THEN** the row background is the opaque `bg_dialog` color, not transparent

#### Scenario: Pulse animation on running rows
- **WHEN** a running row's pulse animation updates
- **THEN** the pulse color is pre-blended with `bg_dialog` to produce an opaque color
- **AND** no `setAlphaF()` is used on the color

### Requirement: Styled background attribute
The QMainWindow SHALL set `WA_StyledBackground` attribute to ensure the stylesheet background is always painted, preventing compositor transparency on Linux X11.

#### Scenario: Window background rendering
- **WHEN** the Control Center window is displayed on Linux X11
- **THEN** the window background is fully opaque regardless of compositor settings
