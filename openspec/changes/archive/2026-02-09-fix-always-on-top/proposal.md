## Why

The Control Center's always-on-top mechanism uses NSWindow level 1000 (NSScreenSaverWindowLevel) with a 500ms `orderFrontRegardless()` timer. This causes the GUI to freeze completely because QMenu popups (level ~101) appear *behind* the level-1000 main window — `menu.exec()` blocks the main thread waiting for interaction with an invisible menu. This is a recurring, hard-to-diagnose UI freeze that makes the CC unreliable.

## What Changes

- **Replace NSScreenSaverWindowLevel (1000) with NSStatusWindowLevel (25)**: High enough to stay above all normal and floating windows (Zed, Chrome, etc.), but low enough that Qt menus (level 101) and dialogs naturally appear above it.
- **Remove the 500ms `orderFrontRegardless()` timer**: macOS window level system handles ordering natively — no periodic polling needed.
- **Remove the `pause_always_on_top()` / `resume_always_on_top()` infrastructure**: With proper window levels, menus and dialogs are inherently above the CC window. No need to pause/resume anything.
- **Simplify all dialog/menu callsites**: Remove `pause_always_on_top()` / `resume_always_on_top()` wrapping from context menus, dialog helpers, and custom dialogs throughout the codebase.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `control-center`: The "Dialog Always-On-Top" requirement changes — the timer pause/resume mechanism is removed in favor of correct window levels. The always-on-top behavior is achieved through native macOS window levels instead of aggressive polling.

## Impact

- `gui/control_center/main_window.py`: Remove timer setup, `_bring_to_front()`, `pause_always_on_top()`, `resume_always_on_top()`, simplify `_setup_macos_always_on_top()`
- `gui/control_center/mixins/menus.py`: Remove `pause/resume_always_on_top()` calls around `menu.exec()`
- `gui/control_center/mixins/handlers.py`: Remove `pause/resume` calls if present
- `gui/dialogs/helpers.py`: Simplify dialog helpers — remove timer pause/resume wrapping
- `gui/dialogs/*.py`: Remove `pause/resume` calls from custom dialog `.exec()` callsites
- `CLAUDE.md`: Update the "macOS Always-On-Top Dialog Rule" to reflect the simpler approach
