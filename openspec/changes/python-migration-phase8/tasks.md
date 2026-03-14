# Tasks — python-migration-phase8

## Phase 8: Orchestration Engine Completion

### 1. Digest Engine Migration

- [ ] Create `lib/wt_orch/digest.py` with `scan_spec_directory()` — recursive spec file finder with ignore patterns
- [ ] Add `build_digest_prompt()` — assemble LLM prompt from spec files and project context
- [ ] Add `call_digest_api()` — Claude CLI call with retry, parse `DigestResult` dataclass
- [ ] Add `write_digest_output()` — write `index.yaml`, `requirements.yaml`, `dependencies.yaml`, `coverage.yaml`, `domains/*.md`
- [ ] Add `stabilize_ids()` — preserve requirement IDs across re-digests by content similarity matching
- [ ] Add `validate_digest()` — check structural integrity (files exist, unique IDs, valid refs)
- [ ] Add `populate_coverage()`, `check_coverage_gaps()`, `update_coverage_status()` — coverage tracking
- [ ] Add `generate_triage_md()`, `parse_triage_md()`, `merge_triage_to_ambiguities()`, `merge_planner_resolutions()` — triage pipeline
- [ ] Add `check_digest_freshness()` — compare spec mtime vs digest mtime
- [ ] Register CLI subcommands: `wt-orch-core digest run|validate|coverage|freshness`
- [ ] Create `tests/unit/test_digest.py` — scanning, ID stabilization, validation, coverage, freshness tests

### 2. Watchdog Migration

- [ ] Create `lib/wt_orch/watchdog.py` with `WatchdogResult` dataclass and `watchdog_check()` — per-change health evaluation
- [ ] Add `watchdog_init_state()` — create initial baseline (file count, test count, iteration)
- [ ] Add `detect_hash_loop()` — ring buffer analysis for action hash repetition
- [ ] Add escalation logic — levels 0-3 (ok → restart → redispatch → fail), reset on progress
- [ ] Register CLI subcommands: `wt-orch-core watchdog check|status`
- [ ] Create `tests/unit/test_watchdog.py` — timeout, hash loop, escalation, progress reset tests

### 3. Auditor Migration

- [ ] Create `lib/wt_orch/auditor.py` with `build_audit_prompt()` — collect merged changes with scopes and file lists
- [ ] Add `run_audit()` — Claude CLI call, parse gaps/recommendations/coverage_score
- [ ] Add `parse_audit_result()` — structured finding extraction with severity levels
- [ ] Register CLI subcommands: `wt-orch-core audit run|prompt`
- [ ] Create `tests/unit/test_auditor.py` — prompt construction, result parsing, severity tests

### 4. Builder + Server-Detect + Orch-Memory Migration

- [ ] Create `lib/wt_orch/builder.py` with `check_base_build()` — auto-detect PM, run build, cache result
- [ ] Add `fix_base_build()` — LLM-assisted build fix with single attempt guard
- [ ] Add `detect_dev_server()` and `detect_package_manager()` to `lib/wt_orch/config.py` (from server-detect.sh)
- [ ] Add `install_dependencies()` to `config.py` — run PM install command
- [ ] Add `orch_remember()`, `orch_recall()`, `orch_gate_stats()` to `lib/wt_orch/events.py` or new `orch_memory.py`
- [ ] Register CLI subcommands: `wt-orch-core build check|fix|detect-server|detect-pm`
- [ ] Create `tests/unit/test_builder.py` — PM detection, dev server cascade, build caching tests

### 5. Wrapper Elimination

- [ ] Update `bin/wt-orchestrate` — remove all `source lib/orchestration/*.sh` lines
- [ ] Update `bin/wt-orchestrate` — replace direct bash function calls with `wt-orch-core` CLI calls
- [ ] Verify all orchestration flows still work: digest → plan → dispatch → verify → merge → audit
- [ ] Delete `lib/orchestration/digest.sh`
- [ ] Delete `lib/orchestration/watchdog.sh`
- [ ] Delete `lib/orchestration/auditor.sh`
- [ ] Delete `lib/orchestration/builder.sh`
- [ ] Delete `lib/orchestration/orch-memory.sh`
- [ ] Delete `lib/orchestration/server-detect.sh`
- [ ] Delete remaining wrapper files: `state.sh`, `planner.sh`, `dispatcher.sh`, `verifier.sh`, `merger.sh`, `monitor.sh`, `events.sh`, `config.sh`, `utils.sh`, `reporter.sh`, `milestone.sh`
- [ ] Remove `lib/orchestration/` directory if empty
- [ ] Run full test suite: `pytest tests/unit/ -v`
