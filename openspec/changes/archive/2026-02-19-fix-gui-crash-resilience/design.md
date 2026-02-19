## Context

The Control Center GUI runs 5 background QThread workers (StatusWorker, FeatureWorker, TeamWorker, UsageWorker, ChatWorker) that emit signals processed by the UI thread. A NameError in `_create_project_header()` (`os_status` undefined) crashes every table rebuild after FeatureWorker returns its first poll (~15s). Additionally, alpha-transparent row backgrounds cause rendering artifacts on Linux X11 frameless windows. There is no error handling in signal handlers, so any exception kills the rendering pipeline silently.

## Goals / Non-Goals

**Goals:**
- Fix the `os_status` NameError crash
- Eliminate alpha-transparent colors that cause Linux X11 rendering artifacts
- Add error boundaries so a single exception can't kill the UI
- Add structured logging to all workers and signal handlers

**Non-Goals:**
- Refactoring worker architecture (they work fine as QThreads)
- Adding retry logic for failed worker polls
- Changing the FeatureWorker poll interval or caching strategy

## Decisions

### 1. Error boundary pattern: try/except in signal handler slots

All Qt signal handler methods that process worker results (`update_status`, `on_features_updated`, `update_team`, `update_usage`, `update_chat_badge`) will be wrapped with try/except that logs the exception and continues. This prevents a single bad data payload from killing the UI.

**Alternative considered**: Decorator-based `@safe_slot` — rejected because the existing `@log_exceptions` pattern in handlers.py already does this for user-triggered handlers, and we should reuse the same pattern rather than introduce a new one.

**Decision**: Use the existing `@log_exceptions` pattern from `gui/control_center/mixins/handlers.py` and apply it to worker signal handlers too.

### 2. Opaque colors only — no alpha transparency in table rendering

Replace all alpha-transparent colors (`"transparent"`, `setAlphaF()`) with opaque pre-blended colors using `bg_dialog` as the base. The `_set_row_background` method already has a guard (added in this session), and `update_pulse` already pre-blends.

**Why not keep transparent?** On Linux X11, `Qt.FramelessWindowHint | Qt.Tool` windows can't reliably render alpha-transparent table cell backgrounds. The compositor "punches through" to the desktop.

### 3. Worker logging via existing wt-control logger hierarchy

All workers already have access to the `logging` module. StatusWorker and TeamWorker already use loggers. FeatureWorker, ChatWorker, and UsageWorker need loggers added. Each poll cycle logs at DEBUG, errors at ERROR.

## Risks / Trade-offs

- **[Error swallowing]** → Error boundaries log at ERROR level and continue. The UI may show stale data but won't crash. The log file is the diagnostic tool.
- **[Opaque colors visual difference]** → Transparent idle rows previously inherited the table background naturally. Opaque bg_dialog should look identical since that's what the table background already is.
