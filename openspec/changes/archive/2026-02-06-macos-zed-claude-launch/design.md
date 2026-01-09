## Context

`wt-work` auto-launches Claude Code after opening a worktree in the editor. On Linux, this uses `xdotool` to send a Ctrl+Shift+L keystroke to the editor window. On macOS, `xdotool` doesn't exist — it's an X11-only tool. The result: macOS users get the editor opened but Claude Code never starts.

The `wt-work` script has two launch methods:
- `keystroke` (Zed): sends Ctrl+Shift+L via xdotool to trigger a Zed task
- `terminal` (VS Code/Cursor/Windsurf): sends Ctrl+Shift+L via xdotool to open Claude Code panel

Both paths are Linux-only. The `terminal` path has a fallback info message; the `keystroke` path has none.

## Goals / Non-Goals

**Goals:**
- macOS Zed users get Claude Code auto-launched when `wt-work` opens a worktree
- Use `osascript` (AppleScript) to send keystrokes on macOS — native, no extra dependencies
- Add fallback info messages when no automation tool is available

**Non-Goals:**
- Windows support (no current users)
- Removing or changing the Linux xdotool path (still works fine)
- Handling Accessibility permission prompts automatically (macOS will prompt the user on first use)

## Decisions

### Use osascript with System Events for keystroke sending

**Decision**: Use `osascript -e 'tell application "System Events" to keystroke "l" using {control down, shift down}'` to send Ctrl+Shift+L to the frontmost application.

**Alternatives considered**:
- **Zed CLI args**: Zed doesn't support running tasks from CLI
- **Zed URL scheme**: No task-running URL scheme exists
- **cliclick**: Third-party tool, requires homebrew install — adds dependency

**Rationale**: osascript is built into every macOS installation. System Events keystroke sending is the standard macOS approach. It requires Accessibility permission, but macOS prompts the user automatically on first use.

### Simplify macOS path — no window search needed

**Decision**: On macOS, after opening the editor, simply wait and send the keystroke to the frontmost app. Don't try to find specific windows by name.

**Rationale**: Unlike Linux where xdotool needs to find the right window among many, on macOS `zed <path>` brings the correct window to front. The keystroke goes to the frontmost app, which is already the right one. This is simpler and more reliable than trying to use AppleScript to search for windows by name.

### Platform branching structure

**Decision**: Use `$PLATFORM` variable (already available from `wt-common.sh`) to branch:

```
case "$claude_launch" in
    keystroke)
        case "$PLATFORM" in
            linux)  → xdotool path (existing)
            macos)  → osascript path (new)
            *)      → info message
        esac
        ;;
    terminal)
        case "$PLATFORM" in
            linux)  → xdotool path (existing)
            macos)  → osascript path (new)
            *)      → info message
        esac
        ;;
esac
```

## Risks / Trade-offs

- **Accessibility permission required** → macOS prompts automatically on first use. If denied, the keystroke silently fails — not harmful, just doesn't auto-launch Claude. The fallback is manual Ctrl+Shift+L.
- **Race condition: editor not ready** → Use `sleep` delay (1.5s for Zed) before sending keystroke, same as Linux path. May need tuning.
- **osascript sends to frontmost app** → If user switches apps during the delay, keystroke goes to wrong app. Acceptable trade-off — same risk exists with xdotool on Linux.
