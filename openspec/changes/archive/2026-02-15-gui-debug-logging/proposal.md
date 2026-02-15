## Why

The GUI (Control Center) has zero logging across 123 action functions in 16 files. When something fails silently — like the double-click-to-open-editor not working — there's no way to diagnose the issue without live debugging. Users encounter problems, can't reproduce them in front of a developer, and the root cause is lost. A persistent log file would let users simply share the log next time something goes wrong.

## What Changes

- Add Python standard `logging` module to all GUI modules
- Write rotating log files to `/tmp/wt-control.log` (macOS/Linux) or `%TEMP%\wt-control.log` (Windows)
- Log all user-triggered actions (double-click, context menu, buttons) with key parameters
- Log all platform calls (AppleScript, xdotool) with inputs and results
- Log all subprocess calls with command, return code, and errors
- Log worker errors (status polling, team sync, usage fetch)

## Capabilities

### New Capabilities
- `gui-logging`: Debug logging infrastructure for the Control Center GUI — log setup, rotation, per-module loggers, and log statements at critical points

### Modified Capabilities

## Impact

- All files under `gui/` gain a module-level logger and log statements
- New file: `gui/logging_setup.py` for centralized log configuration
- `gui/main.py` calls logging setup at startup
- No new dependencies (Python `logging` is stdlib)
- No user-visible behavior changes — logging is silent background activity
