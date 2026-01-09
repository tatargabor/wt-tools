## Context

The Control Center sets NSWindow level to 25 (NSStatusWindowLevel) via PyObjC during initialization. However, Qt6 internally maps `WindowStaysOnTopHint | Tool` to NSModalPanelWindowLevel (8) and may reassert this level during window state changes — particularly when the application is deactivated (user clicks another app) or when `setWindowFlags()` is called (which destroys and recreates the NSWindow). This causes the CC to drop from level 25 to level 8, making it appear behind other applications.

The previous approach used level 1000 + `orderFrontRegardless()` timer, which caused GUI freezes because QMenu popups (level 101) appeared behind the level-1000 window. The current level 25 is correct — the problem is solely that Qt6 resets it.

## Goals / Non-Goals

**Goals:**
- Ensure the CC stays at NSStatusWindowLevel (25) across all app activation/deactivation cycles
- Detect and correct Qt6 level resets promptly
- Prevent macOS `hidesOnDeactivate` behavior for Tool windows

**Non-Goals:**
- Changing the window level from 25 (it's the right level)
- Adding `orderFrontRegardless()` back (that caused the original freeze)
- Making CC visible over fullscreen Spaces (macOS platform limitation)

## Decisions

### Decision 1: Event-driven level enforcement via applicationStateChanged

**Choice**: Connect to `QApplication.applicationStateChanged` signal and re-enforce level 25 with a 50ms delay when the activation state changes.

**Rationale**: App deactivation is the primary trigger for Qt6 resetting the native level. By listening for this specific event and correcting immediately after, we catch the most common case. The 50ms delay ensures Qt6 has finished its internal state update before we override it.

**Alternatives considered**:
- Install a native `NSNotificationCenter` observer for `NSApplicationDidResignActiveNotification` — more complex, same effect
- Override `changeEvent` for `QEvent.ApplicationStateChange` — less clean than signal connection

### Decision 2: Lightweight periodic backup timer (5 seconds)

**Choice**: Run a QTimer every 5 seconds that checks the current NSWindow level and corrects it if it drifted from 25.

**Rationale**: Defense-in-depth against Qt6 level resets from sources other than app deactivation (e.g., screen changes, window recreation from Qt internals). This is NOT the same as the old `orderFrontRegardless()` timer — `setLevel_()` is a simple level setter that doesn't force window ordering or block the event loop.

**Why this is safe (unlike the old timer)**:
- The old timer called `orderFrontRegardless()` at level 1000 → menus appeared behind → `menu.exec()` blocked forever
- The new timer calls `setLevel_(25)` → menus at level 101 remain above → no blocking possible
- 5s interval (vs old 500ms) means minimal overhead

### Decision 3: Set hidesOnDeactivate to False

**Choice**: Add `ns_window.setHidesOnDeactivate_(False)` to the native setup.

**Rationale**: macOS default for NSPanel-like windows (which Qt's `Tool` flag creates) is `hidesOnDeactivate = True`. While this is already `False` by default for NSWindow (which Qt uses), explicitly setting it provides defense-in-depth against Qt6 changing the window type.

### Decision 4: Simplify show_window() re-setup

**Choice**: In `show_window()`, call `_enforce_native_level()` instead of the full `_setup_macos_always_on_top()` after `setWindowFlags()`.

**Rationale**: `setWindowFlags()` recreates the NSWindow, so we need to re-set the level. But the collection behavior flags only need to be set once (they survive less destructive updates). Using `_enforce_native_level()` is lighter and the collection behavior will be re-set by the full setup if needed.

Actually — since `setWindowFlags()` recreates the NSWindow entirely, we DO need to re-run the full setup. Keep `_setup_macos_always_on_top()` in `show_window()` but ensure `_enforce_native_level()` is the fast path for the timer and state change listener.

## Risks / Trade-offs

**[Risk] Timer fires during menu/dialog interaction** → Safe because `setLevel_(25)` only sets the level, it does NOT call `orderFrontRegardless()`. Menus at level 101 remain above level 25.

**[Risk] 5s timer is too slow to catch fast level resets** → The `applicationStateChanged` listener is the primary defense and fires within 50ms. The timer is only backup for edge cases.

**[Risk] `_get_ns_window()` returns different NSWindow after `setWindowFlags()`** → Yes, this happens because Qt recreates the NSWindow. The method gets the current NSWindow from `winId()` each time, so it always returns the current one.
