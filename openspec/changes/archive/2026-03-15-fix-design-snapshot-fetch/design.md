## Context

The orchestrator's design pipeline has 4 stages: detect → fetch → inject → verify. The bash orchestrator implemented all 4 via `lib/design/bridge.sh` functions called from `planner.sh`. The Python migration ported the planner but left `_fetch_design_context()` as a read-only stub — it checks for an existing `design-snapshot.md` on disk but never generates one. The bash bridge functions (`setup_design_bridge`, `check_design_mcp_health`, `fetch_design_snapshot`) still exist and work, but nothing in the Python code calls them.

Current state of each stage in Python:
1. **Detect**: Not called — no MCP detection in Python planner
2. **Fetch**: `_fetch_design_context()` only reads, never fetches
3. **Inject (dispatch)**: `design_snapshot_dir` param exists but defaults to `"."` and is never propagated from `dispatch_ready_changes()`
4. **Verify**: `if design_snapshot_dir: pass` — placeholder

## Goals / Non-Goals

**Goals:**
- Planner preflight detects design MCP, health-checks it, fetches snapshot via `fetch-figma-design.py`
- Fail-fast: if design MCP is registered AND `design_file` is configured but snapshot fetch fails, block decomposition with a clear error
- `design_snapshot_dir` propagated through engine → dispatch_ready_changes → dispatch_change
- Verifier calls `build_design_review_section()` and includes result in review prompt
- Unit tests for the new Python design bridge logic

**Non-Goals:**
- Porting `fetch-figma-design.py` to a library — keep it as a subprocess call
- Porting bash bridge functions to Python — reuse them via subprocess where needed (dispatch, verify)
- Changing the MCP checkpoint flow — that already works in bash and is orthogonal
- Changing `design_prompt_section()` — it already works when a snapshot exists

## Decisions

### D1: Call bash bridge for detect/health/fetch from Python

**Decision**: The Python planner calls bash bridge functions via subprocess rather than reimplementing them in Python.

**Rationale**: `setup_design_bridge()`, `check_design_mcp_health()`, and `fetch_design_snapshot()` are complex bash functions that shell out to `run_claude` and `fetch-figma-design.py`. They work correctly. Reimplementing in Python would duplicate ~200 lines of tested logic with zero benefit. The planner already calls bash functions elsewhere (e.g., `design_context_for_dispatch` in dispatcher.py:790).

**Alternative considered**: Pure Python port. Rejected because:
- `setup_design_bridge` does jq parsing of settings.json — trivial in Python but would duplicate existing tested code
- `check_design_mcp_health` calls `run_claude --mcp-config` — we'd need to replicate the same subprocess call
- `fetch_design_snapshot` invokes `fetch-figma-design.py` — already Python, but with bash-level progress logging and heartbeat emission

**CRITICAL constraint**: `setup_design_bridge()` exports `DESIGN_MCP_CONFIG` and `DESIGN_MCP_NAME` env vars that `check_design_mcp_health()` and `fetch_design_snapshot()` depend on. These env vars only exist in the subprocess's environment. All three functions MUST be called in a single chained `bash -c` invocation (e.g., `source bridge.sh && setup_design_bridge && check_design_mcp_health && fetch_design_snapshot`). Separate subprocess calls per function would lose env state between calls. The dispatcher already uses this single-command pattern at dispatcher.py:790.

### D2: Fail-fast when design configured but fetch fails

**Decision**: If `design_file` is set in orchestration config AND a design MCP is detected but the snapshot fetch fails, `_fetch_design_context()` raises `RuntimeError` to block decomposition.

**Rationale**: Silent fallback (current behavior) means agents proceed without design tokens, producing UI that doesn't match the Figma. The user explicitly configured a design source — they expect it to be used. A clear error lets them fix the MCP auth or config before wasting tokens on a designless run.

**Escape hatch**: Set `DESIGN_OPTIONAL=true` env var to fall back to empty context (for CI or projects where design is nice-to-have).

### D3: design_snapshot_dir = project root, threaded through full call chain

**Decision**: `design_snapshot_dir` defaults to `os.getcwd()` (project root) when called from the engine, since `fetch_design_snapshot()` writes to project root. The value is threaded through the FULL call chain: engine → dispatch_ready_changes → dispatch_change, AND engine → poll_change → handle_change_done → review_change.

**Rationale**: The bash bridge copies the snapshot to `$PROJECT_ROOT/design-snapshot.md` (bridge.sh L244). The Python planner runs from project root. Using cwd as default makes the snapshot visible to both planner (reads it), dispatcher (passes it to `design_context_for_dispatch`), and verifier (passes it to `build_design_review_section`). Without threading through the verifier call chain, the `pass` placeholder fix is dead code — `design_snapshot_dir` would always be `""`.

**CLI callers**: `cli.py` calls `dispatch_change()` and `dispatch_ready_changes()` directly. These use `os.getcwd()` as default — acceptable since CLI is always invoked from project root. No new CLI argument needed.

### D4: Verifier calls bash build_design_review_section via subprocess

**Decision**: Same pattern as dispatcher — source bridge.sh and call the function.

**Rationale**: `build_design_review_section()` does awk parsing of the snapshot and produces a compact token summary. Already tested. Rewriting in Python would be fragile for no gain.

## Risks / Trade-offs

- **[Risk] bash dependency**: Python code depends on bash bridge functions → **Mitigation**: These functions are stable, tested, and already used by the dispatcher. The coupling is intentional — bridge.sh is the single source of truth for design operations.
- **[Risk] MCP timeout during fetch**: Figma MCP calls take 4-5 min → **Mitigation**: 300s timeout on the fetch subprocess. If it times out, the fail-fast gate triggers with a clear error message.
- **[Risk] DESIGN_OPTIONAL escape hatch abuse**: Teams may set it to skip broken auth → **Mitigation**: Log a visible warning when DESIGN_OPTIONAL suppresses a failure, so it shows up in run reports.
