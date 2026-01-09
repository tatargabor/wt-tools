## Why

`wt-work` and `wt-new` auto-launch Claude Code in the editor after opening a worktree, but the keystroke-sending mechanism only works on Linux (xdotool). On macOS, nothing happens — the editor opens but Claude Code terminal is never started. This affects Zed users on macOS.

## What Changes

- Add macOS support for auto-launching Claude Code terminal in Zed via `osascript` (AppleScript)
- Add a fallback info message when neither xdotool nor osascript is available
- Update the `terminal` claude_launch path with the same macOS support for future VS Code/Cursor use

## Capabilities

### New Capabilities

(none)

### Modified Capabilities
- `editor-integration`: Add macOS platform support for Claude Code auto-launch via osascript alongside existing xdotool (Linux) support

## Impact

- `bin/wt-work`: The `keystroke)` and `terminal)` case branches in the Claude auto-launch section
- `openspec/specs/editor-integration/spec.md`: Scenarios need macOS platform coverage
