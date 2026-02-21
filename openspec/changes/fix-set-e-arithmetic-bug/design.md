## Context

`bin/wt-hook-memory` uses `set -e` (line 12). The `_stop_migrate_staged()` function uses `(( count++ ))` to count processed entries. When count=0, `(( 0++ ))` evaluates to 0 (the pre-increment value), bash interprets 0 as false (exit code 1), and `set -e` terminates the background process.

## The Bug

```bash
set -e
count=0
(( count++ ))    # Returns old value 0 → exit code 1 → set -e kills process
echo "never reached"
```

This affects 3 counter increments in `_stop_migrate_staged()`:
- Line 1118: `(( conv_count++ ))` — Convention counter
- Line 1123: `(( cheat_count++ ))` — CheatSheet counter
- Line 1130: `(( count++ ))` — General entry counter

## Decision: Use `|| true` suffix

**Choice**: `(( var++ )) || true` over `var=$((var + 1))`

Rationale:
- Minimal diff — keeps the existing code style
- `|| true` is the standard bash idiom for protecting `set -e` from expected non-zero exits
- The `$((expr))` form would also work but changes the coding pattern used throughout

## Audit: Other `(( ))` in the same file

| Line | Expression | Risk | Action |
|------|-----------|------|--------|
| 61 | `echo $(( now - _METRICS_TIMER_START ))` | None — `$()` captures value | No change |
| 507, 660, 724, 776 | `local _tok_est=$(( ... ))` | None — assignment | No change |
| 1115 | `(( conv_count >= 2 )) && continue` | Safe — `&& continue` handles both exits | No change |
| 1118 | `(( conv_count++ ))` | **BUG** — kills on 0→1 | Fix |
| 1120 | `(( cheat_count >= 2 )) && continue` | Safe — `&& continue` handles both exits | No change |
| 1123 | `(( cheat_count++ ))` | **BUG** — kills on 0→1 | Fix |
| 1125 | `(( count >= 5 )) && continue` | Safe — `&& continue` handles both exits | No change |
| 1130 | `(( count++ ))` | **BUG** — kills on 0→1 | Fix |

## Secondary: Stuck staged file

The bug prevents `_stop_migrate_staged()` from reaching the `rm -f "$staged"` line (1143), so the staged file persists forever, causing every future extraction to crash at the same point.
