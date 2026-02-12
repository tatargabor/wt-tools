## Why

The Control Center GUI currently has no visibility into whether OpenSpec is set up in a project. Users cannot initialize or update OpenSpec from the GUI, and the existing memory status (`get_memory_status`) and future openspec status checks run as synchronous subprocess calls on the UI thread during every 2-second refresh, which will cause UI freezes with multiple projects.

## What Changes

- Add `bin/wt-openspec` CLI wrapper: `init` (runs `openspec init --tools claude`), `update` (runs `openspec update`), and `status --json` (returns install status, version, active change count)
- Add [O] button to the project header row indicating OpenSpec presence (green when detected, gray when absent)
- Add OpenSpec section to the project header context menu: status line, Initialize/Update actions
- Replace synchronous subprocess calls in `_create_project_header` with a background `FeatureWorker` that polls memory and openspec status every 10-15 seconds, caching results for zero-cost table renders

## Capabilities

### New Capabilities
- `openspec-cli`: `wt-openspec` CLI wrapper for init, update, and JSON status queries
- `openspec-header-button`: [O] button in project header with detection, tooltip, and click action
- `feature-worker`: Background thread polling memory + openspec status per project, replacing synchronous subprocess calls in table rendering

### Modified Capabilities

## Impact

- `bin/wt-openspec` — new CLI script
- `gui/workers/` — new `FeatureWorker` thread
- `gui/control_center/mixins/table.py` — [O] button in `_create_project_header`, remove `get_memory_status` subprocess call, read from cache instead
- `gui/control_center/mixins/menus.py` — OpenSpec section in `show_project_header_context_menu`
- `gui/control_center/main_window.py` — wire up FeatureWorker
