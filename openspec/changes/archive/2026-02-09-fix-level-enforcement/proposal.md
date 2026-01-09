## Why

The Control Center disappears behind normal application windows (e.g., Zed) when the user clicks on them. The previous fix (commit 4047e157) correctly replaced level 1000 with NSStatusWindowLevel (25) and removed the freeze-causing `orderFrontRegardless()` timer, but Qt6 internally resets the native NSWindow level during app deactivation and `setWindowFlags()` calls, causing the CC to drop from level 25 back to level 8 (NSModalPanelWindowLevel).

## What Changes

- Add `applicationStateChanged` signal listener that re-enforces NSWindow level 25 when the app activation state changes (primary defense)
- Add lightweight periodic level-check timer (every 5s) as backup defense against any other Qt6 level resets
- Add `_enforce_native_level()` method that checks current level and only calls `setLevel_(25)` if it drifted
- Update `show_window()` to call `_enforce_native_level()` directly instead of full `_setup_macos_always_on_top()` re-setup
- Add `hidesOnDeactivate_(False)` to the native setup to prevent macOS from hiding Tool windows on app deactivation

## Capabilities

### New Capabilities

(none — this is a fix to existing always-on-top behavior)

### Modified Capabilities

- `control-center`: The Dialog Always-On-Top requirement needs updating — replace the timer pause/resume scenarios with the new level enforcement approach. The CC must maintain NSStatusWindowLevel (25) across app activation changes.

## Impact

- `gui/control_center/main_window.py` — add level enforcement logic
- `openspec/specs/control-center/spec.md` — update always-on-top requirements
- `tests/gui/test_02_window.py` — add tests for level enforcement
