## Why

The `improve-memory-hooks` change created two automatic Claude Code hooks — `wt-hook-memory-save` (Stop) and `wt-hook-memory-recall` (UserPromptSubmit) — but never registered them in `wt-deploy-hooks`. The hooks exist on disk and are symlinked by `install.sh`, but no project gets them in `.claude/settings.json`. Only the benchmark `init-with-memory.sh` manually wires them with jq. Result: memory auto-save and auto-recall are silently inactive in all normal projects.

## What Changes

- `wt-deploy-hooks` includes memory hooks (`wt-hook-memory-save`, `wt-hook-memory-recall`) in the default deployed config
- New `--no-memory` flag for `wt-deploy-hooks` to skip memory hooks (benchmark baseline use case)
- Existing projects with old-style settings.json get upgraded (memory hooks added) on re-deploy
- Benchmark init scripts simplified: `init-with-memory.sh` drops manual jq wiring, `init-baseline.sh` uses `--no-memory`
- Documentation updated with automatic hooks section
- Smart recall spec updated: implementation uses git log (not openspec list) — spec aligned to reality

## Capabilities

### New Capabilities

- `auto-memory-hooks-deploy`: Default deployment of memory save/recall hooks via `wt-deploy-hooks`

### Modified Capabilities

- `hook-auto-install`: Adding memory hooks to the deployed config and `--no-memory` flag
- `smart-memory-recall`: Align spec to implementation — git log for change detection instead of openspec list

## Impact

- `bin/wt-deploy-hooks` — main change: config template and flag
- `.claude/settings.json` — this project's config gets memory hooks
- `benchmark/init-with-memory.sh` — simplified (remove manual jq)
- `benchmark/init-baseline.sh` — add `--no-memory` flag
- `docs/developer-memory.md` — new section on automatic hooks
