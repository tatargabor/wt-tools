## 1. Python planner — design bridge functions

- [x] 1.1 Add `_detect_design_mcp()` to `planner.py` — read `.claude/settings.json`, return server name (figma/penpot/sketch/zeplin) or `None`
- [x] 1.2 Add `_load_design_file_ref()` to `planner.py` — read `design_file` from `wt/orchestration/config.yaml` or `.claude/orchestration.yaml`, return URL string or `None`
- [x] 1.3 Rewrite `_fetch_design_context(force=False)` in `planner.py` — detect MCP, load design_file ref, short-circuit if neither is set; if both set, call all three bash bridge functions in a single chained `bash -c` subprocess (`source bridge.sh && setup_design_bridge && check_design_mcp_health && fetch_design_snapshot "$force"`); read resulting `design-snapshot.md`, return content[:5000]. IMPORTANT: all bash bridge calls MUST be in ONE subprocess because `setup_design_bridge` exports env vars (`DESIGN_MCP_CONFIG`, `DESIGN_MCP_NAME`) that subsequent functions depend on — separate subprocess calls lose env state.
- [x] 1.4 Add fail-fast logic in `_fetch_design_context()` — if MCP detected AND design_file configured but health check or fetch fails, raise `RuntimeError` unless `DESIGN_OPTIONAL=true` env var is set. Skip health check entirely if `design_file` is not configured (avoids wasting 30s on a Claude probe with no design to fetch).
- [x] 1.5 Update `run_decomposition()` call site (planner.py ~L1050) — pass `force=True` to `_fetch_design_context()` when `replan_ctx` is provided (not None): `design_context = _fetch_design_context(force=bool(replan_ctx))`

## 2. Dispatch — propagate design_snapshot_dir

- [x] 2.1 Add `design_snapshot_dir` parameter to `dispatch_ready_changes()` signature (default `"."`)
- [x] 2.2 Pass `design_snapshot_dir` from `dispatch_ready_changes()` to each `dispatch_change()` call in the dispatch loop (L1092)
- [x] 2.3 In `engine.py`, pass `design_snapshot_dir=os.getcwd()` to ALL THREE `dispatch_ready_changes()` call sites: (a) `_handle_auto_replan()` at L793, (b) `_dispatch_ready_safe()` at L877, and (c) verify there are no other callers in engine.py
- [x] 2.4 In `cli.py`, update `dispatch-ready` subcommand (L583) and `dispatch-change` subcommand (L569) — both already run from project root via CLI, so use `design_snapshot_dir=os.getcwd()` as default. No new CLI argument needed (document this as "CLI uses cwd").

## 3. Verifier — wire up design compliance

- [x] 3.1 Add `design_snapshot_dir` parameter to `handle_change_done()` signature (default `""`)
- [x] 3.2 Thread `design_snapshot_dir` from `handle_change_done()` to the `review_change()` call at L1401
- [x] 3.3 Update all callers of `handle_change_done()` — trace from `poll_change()` and engine poll loop to pass `design_snapshot_dir=os.getcwd()`
- [x] 3.4 In `review_change()` (verifier.py), replace the `pass` placeholder with a bash bridge subprocess call: `source bridge.sh 2>/dev/null && build_design_review_section "$design_snapshot_dir"` — assign stdout to `design_compliance` variable (empty string on failure, log warning)

## 4. Unit tests (Python)

- [x] 4.1 Create `tests/unit/test_design_bridge_python.py` — test `_detect_design_mcp()` with mock settings.json containing figma, no design MCP, and missing settings file. Use `unittest` with `tempfile` for mock project dirs.
- [x] 4.2 Test `_load_design_file_ref()` with mock orchestration config containing design_file, without design_file, and missing config
- [x] 4.3 Test `_fetch_design_context()` happy path — use `unittest.mock.patch` on `run_command` to simulate bash bridge success, create a mock design-snapshot.md, verify content returned
- [x] 4.4 Test `_fetch_design_context()` fail-fast — mock `run_command` to return non-zero, verify `RuntimeError` raised when design_file is configured
- [x] 4.5 Test `_fetch_design_context()` with `DESIGN_OPTIONAL=true` — mock `run_command` to fail, verify empty string returned and no error
- [x] 4.6 Test `_fetch_design_context()` cache hit — create existing `design-snapshot.md` with `## Design Tokens`, verify `run_command` NOT called
- [x] 4.7 Test `dispatch_ready_changes` passes `design_snapshot_dir` to `dispatch_change` — use `unittest.mock.patch` on `dispatch_change` and verify kwarg
- [x] 4.8 Test verifier `review_change` design compliance — mock bash bridge subprocess to return token summary, verify `design_compliance` included in template input
