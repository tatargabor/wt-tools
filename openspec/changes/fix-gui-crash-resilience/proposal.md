## Why

The GUI crashes ~15 seconds after startup due to an undefined `os_status` variable in `_create_project_header()`. When the FeatureWorker returns its first poll result, every subsequent table rebuild throws a NameError, leaving the table half-rendered. Additionally, alpha-transparent colors in `update_pulse` cause rendering artifacts on Linux X11 frameless windows. The UI has no error handling in signal handlers, so any single exception kills the entire rendering pipeline.

## What Changes

- Fix the undefined `os_status` variable in `_create_project_header()` (root cause of 15-second crash)
- Replace alpha-transparent colors with opaque pre-blended colors in `update_pulse` and `_set_row_background` (already partially fixed)
- Add try/except error boundaries in Qt signal handlers to prevent single errors from killing the UI
- Add logging to all workers and signal handlers via the existing `wt-control` logger (to `/tmp/wt-control.log`)
- Add GUI test covering the FeatureWorker → table rebuild path

## Capabilities

### New Capabilities

### Modified Capabilities
- `control-center`: Add error boundary pattern for signal handlers
- `gui-logging`: Extend logging to cover all workers and signal handler exceptions
- `gui-testing`: Add test for FeatureWorker cache → project header rendering
- `feature-worker`: Fix undefined variable, ensure poll errors don't propagate to UI

## Impact

- `gui/control_center/mixins/table.py`: Fix `os_status` bug, opaque colors, error boundaries
- `gui/control_center/main_window.py`: Error boundaries on signal handlers, `WA_StyledBackground`
- `gui/workers/*.py`: Add logging to all workers
- `tests/gui/test_XX_feature_header.py`: New test file
