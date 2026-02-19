## Why

Benchmark v6 revealed that the test suite is too weak to differentiate memory-aided vs baseline agents. test-12 passes 71% of checks with no running server, the payout check auto-passes on missing data, TRAP-M checks import statements instead of rendered components, and TRAP-N doesn't verify global Toast mounting. Additionally, code map generation only produced 2/12 maps (regressed from v5's 4/12) because the hook's safety-net logic is gated behind a design-marker guard that prevents re-evaluation. These weaknesses make v7 results unreliable without fixes.

## What Changes

- **Fix test-12 payout check (Bug 2)**: FAIL when no multi-vendor orders exist instead of auto-passing with `check ... 'true'`. The payout rounding algorithm (largest-remainder) is never actually tested.
- **Fix test-12 TRAP-M check (Bug 11)**: Change `grep "Pagination"` to `grep "<Pagination"` or JSX render pattern to distinguish import-only from actual render usage.
- **Fix test-12 TRAP-N check (Bug 12)**: Add explicit check that Toast component is mounted in `layout.tsx` (global mount), not just imported in 3+ files.
- **Fix test-12 vendor regression checks**: FAIL when no vendor ID is found instead of silently skipping 2 checks.
- **Fix C12 change def (Bug 11/12 explicit architecture)**: Add "Pagination must be rendered in JSX, not just imported" and "Toast must be mounted once in layout.tsx" to acceptance criteria in `12-sprint-retro.md`.
- **Fix TRAP-G checkout navigation (C02)**: Add "Cart page must include a Proceed to Checkout link to /checkout" acceptance criterion to `02-shopping-cart.md` and add corresponding test-02.sh check. 4th consecutive benchmark failure.
- **Make code map generation unconditional in save hook**: Move code map logic outside the design-marker guard so it fires for every commit, not just the first per-change-name.
- **Add recall-then-verify pattern to with-memory.md**: Instruct the memory agent to always verify recalled code maps against current codebase state via grep, preventing overconfidence.
- **Isolate memory DB per run**: Use distinct project names (`craftbazaar-baseline` / `craftbazaar-memory`) in init scripts to prevent shared storage.

## Capabilities

### New Capabilities

- `benchmark-testing`: Test script checks for payout verification, TRAP-M render detection, TRAP-N global mount, vendor regression enforcement, and memory DB isolation
- `memory-save-hook`: Code map generation unconditional (outside design-marker guard) and recall-then-verify pattern in CLAUDE.md template

### Modified Capabilities

_None — previous v5 specs were archived but not synced to main specs, so these are effectively new._

## Impact

- **benchmark/tests/test-12.sh**: 4 check modifications (payout, TRAP-M, TRAP-N, vendor)
- **benchmark/tests/test-02.sh**: New checkout link check (TRAP-G)
- **benchmark/changes/12-sprint-retro.md**: Bug 11/12 acceptance criteria tightened
- **benchmark/changes/02-shopping-cart.md**: Checkout link acceptance criterion added
- **bin/wt-hook-memory-save**: Code map block restructured (moved outside `continue` guard)
- **benchmark/claude-md/with-memory.md**: New "recall-then-verify" paragraph in Proactive Memory section
- **benchmark/init-baseline.sh / init-with-memory.sh**: Different project names for memory DB isolation
- **No breaking changes**: All modifications are backward-compatible with existing benchmark infrastructure
