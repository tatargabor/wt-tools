## MODIFIED Requirements

### Requirement: Editor Window Presence Detection
The system SHALL detect whether an editor window is open for each worktree during status collection, taking the configured editor type into account.

#### Scenario: IDE editor configured, window found via PPID chain
- **WHEN** `wt-status` checks a worktree
- **AND** the configured editor type is `ide` (zed, vscode, cursor, windsurf)
- **AND** a Claude agent's PPID chain leads to a process owning an X11/macOS window
- **THEN** `is_editor_open()` SHALL return true

#### Scenario: IDE editor configured, no window found but TTY present
- **WHEN** `wt-status` checks a worktree
- **AND** the configured editor type is `ide`
- **AND** no PPID chain leads to a window
- **AND** the Claude agent has a valid TTY
- **THEN** `is_editor_open()` SHALL NOT use the TTY as evidence of an editor
- **AND** SHALL fall through to title-based window search

#### Scenario: IDE editor configured, window found via title search
- **WHEN** `wt-status` checks a worktree
- **AND** the configured editor type is `ide`
- **AND** no PPID chain leads to a window
- **AND** xdotool/AppleScript title search finds a matching window
- **THEN** `is_editor_open()` SHALL return true

#### Scenario: IDE editor configured, no window found at all
- **WHEN** `wt-status` checks a worktree
- **AND** the configured editor type is `ide`
- **AND** no PPID chain leads to a window
- **AND** no title-based search finds a matching window
- **THEN** `is_editor_open()` SHALL return false

#### Scenario: Terminal editor configured, TTY present
- **WHEN** `wt-status` checks a worktree
- **AND** the configured editor type is `terminal` (kitty, alacritty, wezterm, etc.)
- **AND** a Claude agent has a valid TTY (not `?` or `??`)
- **THEN** `is_editor_open()` SHALL return true with `editor_type="terminal"`

#### Scenario: Auto editor mode resolves to actual type
- **WHEN** the configured editor is `auto`
- **THEN** the system SHALL resolve to the detected editor name using `get_active_editor()`
- **AND** look up its type (`ide` or `terminal`)
- **AND** apply the detection rules for that type
- **AND** if no editor is detected, SHALL default to `ide` behavior (require a window)

#### Scenario: Editor window open on Linux with xdotool
- **WHEN** `wt-status` checks a worktree on Linux
- **AND** xdotool is available
- **THEN** `is_editor_open()` SHALL search for windows matching the worktree basename
- **AND** return true if at least one matching window exists

#### Scenario: No editor window found
- **WHEN** `wt-status` checks a worktree
- **AND** no editor window matches the worktree basename
- **AND** no editor process has CWD in the worktree
- **AND** the configured editor type is not `terminal` or the agent has no TTY
- **THEN** `is_editor_open()` SHALL return false

#### Scenario: Editor window detection on macOS
- **WHEN** `wt-status` checks a worktree on macOS
- **THEN** `is_editor_open()` SHALL use osascript to query editor windows
- **AND** return true if a window title contains the worktree basename
