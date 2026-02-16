## 1. Update wt-deploy-hooks

- [x] 1.1 Add `--no-memory` flag parsing to the argument loop
- [x] 1.2 Update the `hook_json` template to include `wt-hook-memory-recall` (UserPromptSubmit, timeout 15) and `wt-hook-memory-save` (Stop, timeout 30) by default
- [x] 1.3 Create a separate `hook_json_no_memory` template with only the base hooks for `--no-memory` mode
- [x] 1.4 Update idempotency check: detect existing configs missing memory hooks and upgrade them (append to existing arrays)
- [x] 1.5 Verify the script handles all three cases: fresh deploy, upgrade, and already-complete

## 2. Update this project's settings.json

- [x] 2.1 Add `wt-hook-memory-recall` to UserPromptSubmit hooks array (timeout 15)
- [x] 2.2 Add `wt-hook-memory-save` to Stop hooks array (timeout 30)

## 3. Simplify benchmark init scripts

- [x] 3.1 Remove manual jq memory hook wiring from `benchmark/init-with-memory.sh` (lines 53-60)
- [x] 3.2 Update `benchmark/init-baseline.sh`: change `wt-deploy-hooks .` to `wt-deploy-hooks --no-memory .`

## 4. Align smart-memory-recall spec to implementation

- [x] 4.1 Update `improve-memory-hooks/specs/smart-memory-recall/spec.md`: change "OpenSpec-aware query building" to describe git log approach instead of `openspec list --json`
- [x] 4.2 Update scenario "4 of 6 changes completed" to reflect git log commit message parsing

## 5. Update documentation

- [x] 5.1 Add "Automatic memory hooks" section to `docs/developer-memory.md` (after "Stop hook memory reminder") describing wt-hook-memory-save and wt-hook-memory-recall
- [x] 5.2 Update the architecture diagram in `docs/developer-memory.md` to show the automatic hooks layer

## 6. Verify

- [x] 6.1 Test fresh deploy: `wt-deploy-hooks /tmp/test-fresh` creates settings.json with all 4 hooks
- [x] 6.2 Test upgrade: deploy base-only config, then re-run `wt-deploy-hooks` — memory hooks get added
- [x] 6.3 Test `--no-memory`: `wt-deploy-hooks --no-memory /tmp/test-nomem` creates settings.json with only 2 base hooks
- [x] 6.4 Confirm this project's `.claude/settings.json` has all 4 hooks active
