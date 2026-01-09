# usage-display Specification

## Purpose
Display Claude usage statistics in the Control Center GUI, showing session (5h) and weekly capacity percentages with time remaining until reset.

## Requirements

### Requirement: Display Claude Capacity Statistics
The Control Center GUI SHALL display Claude Code capacity statistics via progress bars.

#### Scenario: Capacity displayed via progress bars
Given the Control Center is running
And usage data is available from the API
When the GUI refreshes
Then it displays 5h session capacity as a progress bar with percentage and time remaining
And it displays weekly capacity as a progress bar with percentage and time remaining

#### Scenario: Display format matches claude.ai
Given usage data is available from the API
When displaying session usage
Then it shows format like "17% | 1h 37m" (percentage and time until reset)
And weekly shows format like "3% | 6d 16h"

#### Scenario: Local-only data shows unknown state
Given usage data comes from local JSONL parsing (no session key)
When displaying capacity
Then labels show "--/5h" and "--/7d" (percentages are unreliable from local data)
And progress bars remain empty
And tooltips show token counts and suggest setting session key

#### Scenario: Capacity color coding
Given usage data is available from the API
When capacity is below 90%
Then the progress bar is displayed in green
When capacity is between 90% and 110%
Then the progress bar is displayed in yellow
When capacity is above 110%
Then the progress bar is displayed in red

#### Scenario: Graceful fallback when data unavailable
Given usage data cannot be fetched from any source
When the GUI attempts to display capacity
Then it displays "--/5h" and "--/7d"
And does not show errors to the user

### Requirement: Usage Data Sources
Usage data SHALL be fetched from multiple sources with automatic fallback.

#### Scenario: Primary - Claude.ai API via curl-cffi
Given a saved session key exists in `~/.config/wt-tools/claude-session.json`
And `curl-cffi` Python package is installed
When fetching usage data
Then the worker calls the claude.ai organizations API using `curl-cffi` with `impersonate='chrome'`
And retrieves exact utilization percentages and reset times

#### Scenario: Fallback chain
Given a saved session key exists
When fetching usage data
Then the worker tries sources in this order:
1. `curl-cffi` (Chrome TLS fingerprint, bypasses Cloudflare)
2. Plain `curl` subprocess
3. `urllib.request` (stdlib)
4. Local JSONL parsing (no auth needed)
And uses the first source that returns valid data

#### Scenario: Graceful degradation without curl-cffi
Given `curl-cffi` is not installed
When the worker first attempts an API call
Then it logs a one-time warning suggesting `pip install curl-cffi`
And falls back to curl subprocess and urllib

#### Scenario: Fallback - Local JSONL Parsing
Given no session key is available or all API call methods fail
When fetching usage data
Then the worker parses `~/.claude/projects/*/*.jsonl` files
And calculates token usage for 5h and 7d windows

#### Scenario: Configurable estimation limits
Given local JSONL parsing is used
When calculating percentages
Then `usage.estimated_5h_limit` config (default 500000) is used for 5h percentage
And `usage.estimated_weekly_limit` config (default 5000000) is used for weekly percentage

### Requirement: GUI session key input dialog
The GUI SHALL provide a menu option to set the Claude session key via a simple input dialog.

#### Scenario: Set session key via menu
- **WHEN** user selects "Set Session Key..." from the menu
- **THEN** the main window hides to prevent always-on-top conflicts
- **AND** a `QInputDialog` appears prompting for the session key
- **AND** the entered key is saved to `~/.config/wt-tools/claude-session.json`
- **AND** the main window reappears after the dialog closes

### Requirement: Cost estimation support
The `UsageCalculator` SHALL support estimated USD cost calculation.

#### Scenario: Cost calculated per model
- **WHEN** usage data includes model names
- **THEN** cost is calculated using per-model token prices
- **AND** unknown models use a conservative default price

#### Scenario: Cost available in summary
- **WHEN** `get_usage_summary()` is called
- **THEN** the returned dict includes `estimated_cost_usd` field

### Requirement: Background Usage Data Fetching
Usage data SHALL be fetched periodically in a background thread to avoid blocking the UI.

#### Scenario: Periodic data refresh
Given the Control Center is running
When 30 seconds have elapsed since the last fetch
Then the usage worker fetches fresh data
And updates the progress bars

### Requirement: Cross-Platform Support
Usage tracking SHALL work on Linux, macOS, and Windows.

#### Scenario: Cross-platform paths
Given the application runs on any supported OS
When accessing Claude data
Then it uses `pathlib.Path.home() / ".claude"` for the Claude directory
And handles missing directories gracefully

## Implementation Notes

### Files
- `gui/usage_calculator.py` - Local JSONL token usage calculator
- `gui/workers/usage.py` - Background worker for usage fetching (curl-cffi primary, curl/urllib fallback)
- `gui/constants.py` - Default usage limits configuration

### Removed
- `cloudscraper` - Replaced by `curl-cffi` (Chrome TLS fingerprint impersonation)
- `browser_cookie3` - Removed due to cross-platform unreliability
- WebEngine Login Dialog - Replaced by simple QInputDialog paste flow

### Requirement: Clean worker shutdown

All background worker threads (StatusWorker, UsageWorker, TeamWorker, ChatWorker) SHALL be stopped before application exit.

The `quit_app()` and `restart_app()` methods SHALL use centralized `_stop_all_workers()` and `_wait_all_workers()` helpers that handle all workers uniformly.

#### Scenario: All workers stopped on quit

- **WHEN** user quits the application via tray menu
- **THEN** all worker threads SHALL be signaled to stop
- **AND** the application SHALL wait up to 2 seconds for each worker to finish
- **AND** workers that don't finish in time SHALL be terminated

#### Scenario: UsageWorker responds to stop within 500ms

- **WHEN** `usage_worker.stop()` is called
- **THEN** the UsageWorker thread SHALL exit its sleep loop within 500ms
- **AND** the thread SHALL terminate cleanly without requiring `QThread.terminate()`

### Requirement: Interruptible worker sleep

The UsageWorker SHALL use interruptible sleep (small chunks checking `_running` flag) instead of a single 30-second `msleep()` call. This ensures `stop()` takes effect promptly.

#### Scenario: Sleep interrupted by stop

- **WHEN** UsageWorker is sleeping between fetch cycles
- **AND** `stop()` is called
- **THEN** the worker SHALL wake and exit within 500ms
