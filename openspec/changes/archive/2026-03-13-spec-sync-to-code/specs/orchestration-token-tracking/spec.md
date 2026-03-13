## MODIFIED Requirements

### R1: Token Tracking Resilience
- `get_current_tokens()` in `lib/loop/state.sh` SHALL return the token count from `wt-usage` when available
- When `wt-usage` is unavailable or fails, `get_current_tokens()` SHALL return 0 rather than failing
- The orchestrator uses iteration count (`--max 30`) as the primary safety net, not token tracking

### R2: wt-usage Import Fix
- `bin/wt-usage` SHALL resolve its Python import path correctly regardless of CWD
- If the gui module is not available (e.g., headless install), wt-usage SHALL exit with a clear error instead of an unhandled ImportError
