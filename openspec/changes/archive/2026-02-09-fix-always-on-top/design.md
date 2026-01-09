## Context

The Control Center GUI uses a macOS always-on-top mechanism that sets the NSWindow level to 1000 (NSScreenSaverWindowLevel) and runs a 500ms timer calling `orderFrontRegardless()`. This is the highest window level in macOS, above everything including popup menus (level ~101).

When Qt opens a QMenu via `menu.exec()`, the menu popup appears *behind* the level-1000 window, making it invisible. Since `menu.exec()` is a blocking call that waits for user interaction, the main thread freezes permanently — the user sees a "frozen" UI. There are 34 `pause_always_on_top()` / `resume_always_on_top()` callsites throughout the codebase trying to work around this, but they only pause the timer — they don't lower the window level, so the fundamental problem remains.

## Goals / Non-Goals

**Goals:**
- Eliminate the UI freeze caused by menus/dialogs appearing behind the main window
- Use macOS-native window level that plays correctly with Qt popups and dialogs
- Remove the `orderFrontRegardless()` timer entirely
- Remove all 34 `pause/resume_always_on_top()` callsites and the methods themselves
- Keep the CC visible above normal application windows (Zed, Chrome, terminals)
- Keep the `CollectionBehavior` flags (all spaces, stationary, ignores cycle)

**Non-Goals:**
- Making the CC visible over fullscreen Spaces (macOS platform limitation, unchanged)
- Changing the `WindowStaysOnTopHint` on dialogs (they can keep it for extra safety, but it's no longer strictly required)
- Changing the dialog helpers module (keep helpers.py but simplify internals)

## Decisions

### Decision 1: Use NSStatusWindowLevel (25) instead of NSScreenSaverWindowLevel (1000)

**Choice**: Set NSWindow level to 25 (NSStatusWindowLevel)

**Rationale**: Level 25 is above normal windows (0), floating windows (3), and modal panels (8), but below popup menus (101) and Qt tooltips. This means:
- CC stays above Zed (level 0), Chrome, Terminal, etc.
- QMenu popups (level ~101) naturally appear ABOVE the CC
- QDialog with `WindowStaysOnTopHint` appears above CC
- No need for any timer or pause/resume mechanism

**Alternatives considered**:
- `NSFloatingWindowLevel (3)`: Would work but is at the same level as other floating panels. Some editors' floating panels could cover the CC.
- `NSPopUpMenuWindowLevel (101)`: Too high — same level as QMenu popups, would still cause ordering conflicts.
- `Qt::WindowStaysOnTopHint` only: Sets level to 3 (NSFloatingWindowLevel). Would work but slightly lower priority than level 25.

### Decision 2: Remove the `orderFrontRegardless()` timer entirely

**Choice**: Delete `_front_timer`, `_bring_to_front()`, and `setup_always_on_top_timer()` timer logic.

**Rationale**: With a proper window level, macOS handles window ordering natively. The timer was only needed because the window sometimes lost its ordering — which won't happen with NSStatusWindowLevel since macOS respects the level hierarchy. `orderFrontRegardless()` was also problematic because it could fire between `pause` and the actual dialog/menu appearance (race condition).

### Decision 3: Remove all `pause_always_on_top()` / `resume_always_on_top()` infrastructure

**Choice**: Remove the two methods from `MainWindow` and all 34 callsites across handlers.py, menus.py, and helpers.py.

**Rationale**: The pause/resume mechanism existed solely to prevent the timer from calling `orderFrontRegardless()` while a menu/dialog was open. With no timer, there's nothing to pause. This eliminates a whole class of bugs (forgetting to resume, race conditions, new dialogs forgetting to add pause/resume).

### Decision 4: Keep `_setup_macos_always_on_top()` for one-time level + behavior setup

**Choice**: Retain the method but simplify it — only set window level to 25 and configure `CollectionBehavior` flags. Remove `setHidesOnDeactivate_(False)` since it's the default.

### Decision 5: Keep dialog helpers.py but simplify

**Choice**: Keep the helper functions (`show_warning`, `show_question`, etc.) but remove the `pause_always_on_top` / `resume_always_on_top` calls from `_run_dialog`. The helpers still set `WindowStaysOnTopHint` on the dialog, which provides correct behavior.

**Rationale**: The helpers provide a convenient API and ensure dialogs get `WindowStaysOnTopHint`. The hint is redundant at level 25 (dialogs would appear above anyway) but harmless, and it's good defense-in-depth.

## Risks / Trade-offs

**[Risk] Level 25 window could be covered by other level-25 apps** → Very unlikely in practice. Status-level windows are rare in desktop apps. If it happens, the user can click on the CC in the tray to raise it.

**[Risk] Some edge case where CC drops behind normal windows** → macOS respects window levels strictly. A level-25 window cannot drop behind a level-0 window unless the level is changed programmatically. The `CollectionBehavior` flags ensure it stays across all Spaces.

**[Risk] Removing WindowStaysOnTopHint from CLAUDE.md rule** → We keep the hint on dialogs as defense-in-depth. Update CLAUDE.md to reflect the simpler rule but keep the `show_warning`/`show_question` helper recommendation.
