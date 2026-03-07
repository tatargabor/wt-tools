## 1. Core lookup function

- [ ] 1.1 Add `wt_find_config()` function to `lib/orchestration/state.sh` that implements the fallback chain: `wt/` location → legacy location → empty. This replaces the existing `find_project_knowledge_file()` in `planner.sh` and the hardcoded `CONFIG_FILE` in `wt-orchestrate` line 29
- [ ] 1.2 Add `wt_find_runs_dir()` function that returns `wt/orchestration/runs/` or `docs/orchestration-runs/` or empty
- [ ] 1.3 Add `wt_find_requirements_dir()` function that returns `wt/requirements/` or empty

## 2. Update orchestration modules to use lookup functions

- [ ] 2.1 Update `wt-orchestrate` line 29 (`CONFIG_FILE=".claude/orchestration.yaml"`) to use `wt_find_config orchestration`, and update `state.sh` `load_config_file()` to accept the resolved path
- [ ] 2.2 Replace `find_project_knowledge_file()` in `planner.sh` (lines 342-350) with `wt_find_config project-knowledge` — this function is also called by dispatcher.sh and verifier.sh
- [ ] 2.3 Update `dispatcher.sh` project-knowledge injection to use `wt_find_config project-knowledge`
- [ ] 2.4 Update `verifier.sh` verification rules loading to use `wt_find_config project-knowledge`
- [ ] 2.5 Run log writing — N/A: run logs are manually created, not written by orchestrator code. `wt_find_runs_dir()` is available for future use

## 3. Scaffold wt/ directory in wt-project init

- [ ] 3.1 Add `scaffold_wt_directory()` function to `bin/wt-project` that creates `wt/` subdirectories with `mkdir -p` (including `wt/.work/` and `wt/plugins/`)
- [ ] 3.2a Add `wt/.work/` to project `.gitignore` if not already present
- [ ] 3.2 Add legacy file detection: check for `.claude/orchestration.yaml`, `project-knowledge.yaml`, `docs/orchestration-runs/`
- [ ] 3.3 Print migration suggestions when legacy files are found
- [ ] 3.4 Call `scaffold_wt_directory` from `deploy_wt_tools()` after `.claude/` deployment

## 4. Migrate command

- [ ] 4.1 Add `cmd_migrate()` function to `bin/wt-project` — moves files from legacy to `wt/` locations using `git mv` (or `mv` for non-git)
- [ ] 4.2 Handle orchestration.yaml migration: `.claude/orchestration.yaml` → `wt/orchestration/config.yaml`
- [ ] 4.3 Handle project-knowledge migration: `./project-knowledge.yaml` → `wt/knowledge/project-knowledge.yaml`
- [ ] 4.4 Handle run logs migration: `docs/orchestration-runs/*` → `wt/orchestration/runs/`
- [ ] 4.5 Add `migrate` to the case statement in `bin/wt-project` main dispatcher and update `usage()` help text
- [ ] 4.6 Update `cmd_init_knowledge()` to write to `wt/knowledge/project-knowledge.yaml` when `wt/` exists, fallback to project root
- [ ] 4.7 Update `_migrate_consumer()` to use `wt_find_config orchestration` for directive migration (currently hardcodes `.claude/orchestration.yaml`)

## 5. Plan history saving

- [ ] 5.1 Update `planner.sh` to save a copy of each plan to `wt/orchestration/plans/plan-v{N}-{date}.json` when `wt/orchestration/plans/` exists
- [ ] 5.2 Preserve existing `orchestration-plan.json` as the working file (no change to existing behavior)

## 6. Requirements as planner input

- [ ] 6.1 Update `planner.sh` to scan `wt/requirements/*.yaml` for requirements with status `captured` or `planned`
- [ ] 6.2 Inject requirement titles and descriptions into the decomposition prompt as additional context
- [ ] 6.3 Graceful degradation: skip if `wt/requirements/` does not exist or is empty

## 7. Plugin workspace support

- [ ] 7.1 Add `wt/plugins/` to the scaffolded directory structure in `scaffold_wt_directory()`
- [ ] 7.2 Document plugin workspace convention: each plugin gets `wt/plugins/<name>/`, plugin controls internal structure

## 8. Memory integration

- [ ] 8.1 Create `wt/knowledge/memory-seed.yaml` template in `templates/` with example seeds and format documentation
- [ ] 8.2 Add seed import logic to `wt-project init`: check if memory store is empty + seed file exists → auto-import with `source:seed` tag
- [ ] 8.3 Add `wt-memory seed` command: import from `wt/knowledge/memory-seed.yaml` with content-hash duplicate detection
- [ ] 8.4 Update `wt-memory sync push` to use `wt/.work/memory/` for export and sync-state when `wt/` exists (fallback to current behavior)
- [ ] 8.5 Update `wt-memory sync pull` to use `wt/.work/memory/import-staging/` when `wt/` exists
- [ ] 8.6 Add legacy `.sync-state` migration: on first sync with `wt/` present but no `wt/.work/memory/.sync-state`, copy from legacy storage path

## 9. Testing

- [ ] 9.1 Test `wt_find_config` fallback chain: new location wins, legacy works, missing returns empty
- [ ] 9.2 Test `wt-project init` creates `wt/` structure (including `wt/plugins/`, `wt/.work/`) and detects legacy files
- [ ] 9.3 Test `wt-project migrate` moves files correctly
- [ ] 9.4 Test planner reads requirements from `wt/requirements/`
- [ ] 9.5 Test `wt-memory seed` imports from seed file with duplicate detection
- [ ] 9.6 Test `wt-project init` auto-imports seeds when memory store is empty
