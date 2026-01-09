## 1. Add macOS support to wt-work Claude auto-launch

- [x] 1.1 Refactor the `keystroke)` case in `bin/wt-work` to branch on `$PLATFORM` (linux: existing xdotool path, macos: new osascript path, *: info message fallback)
- [x] 1.2 Implement the macOS osascript keystroke path: sleep, then send Ctrl+Shift+L via `osascript -e 'tell application "System Events" to keystroke "l" using {control down, shift down}'`
- [x] 1.3 Refactor the `terminal)` case in `bin/wt-work` with the same platform branching (linux: xdotool, macos: osascript, *: info message)
- [x] 1.4 Add fallback info message to the `keystroke)` case for unsupported platforms (match existing `terminal)` fallback style)

## 2. Test on macOS

- [x] 2.1 Verify `wt-work` with Zed on macOS: editor opens and Claude Code terminal starts via osascript
- [x] 2.2 Verify fallback message appears when automation is unavailable
