## 1. Bridge Health Check

- [x] 1.1 Add `check_design_mcp_health()` function to `lib/design/bridge.sh` — runs a 30s timeout `run_claude` with `DESIGN_MCP_CONFIG` and a probe prompt that triggers the MCP identity tool (e.g., `whoami`). Returns 0 on success, 1 on auth failure or timeout.
- [x] 1.2 Add unit test in `tests/unit/test_design_bridge.sh` — mock `run_claude` to test success, auth-failure, and timeout paths of the health check function.

## 2. Checkpoint Auto-Approve Exclusion

- [x] 2.1 Modify `trigger_checkpoint()` in `lib/orchestration/state.sh` — when `checkpoint_auto_approve=true` AND checkpoint type is `mcp_auth`, skip auto-approve and enter the polling loop.
- [x] 2.2 Add test case for `mcp_auth` exclusion — verify that `mcp_auth` checkpoints block even when `checkpoint_auto_approve` is enabled, while `periodic` checkpoints still auto-approve.

## 3. Planner Preflight Integration

- [x] 3.1 Insert preflight MCP check in `run_decomposition()` in `lib/orchestration/planner.sh` — after `setup_design_bridge()` succeeds, call `check_design_mcp_health()`. On failure, call `trigger_checkpoint "mcp_auth"` with an actionable notification message including server name.
- [x] 3.2 After checkpoint approval, retry health check once — if retry passes, proceed with design context. If retry fails, log warning and proceed without design context (graceful degradation after explicit user approval).

## 4. Web Dashboard

- [x] 4.1 Update `CheckpointBanner.tsx` — detect `mcp_auth` checkpoint type from state and display MCP-specific message: server name, authentication instructions (`/mcp → figma → Authenticate`), and approve button.

## 5. E2E Scaffold

- [x] 5.1 Verify `run-complex.sh` Figma MCP registration works end-to-end — run scaffold, confirm `settings.json` has official MCP, confirm bridge detects it, confirm preflight gate fires when not authenticated.
