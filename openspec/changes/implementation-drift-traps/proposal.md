## Why

The benchmark's existing convention traps (H-K, and the planned L) all follow the same pattern: a rule is stated in an early change and compliance is tested later. But real-world codebases also suffer from **implementation drift** — when similar functionality is implemented differently across screens because no shared component was established upfront. Unifying divergent implementations is a task where memory has high value: the agent needs to know HOW and WHERE each page implemented the pattern.

v5 results show that both runs score similarly on convention traps because the C12 audit explicitly tells the agent what to fix. Implementation drift traps are harder to cheat because:
1. No explicit convention was ever stated — the divergence is natural
2. C12 says "unify these" but doesn't tell you what each page currently does
3. Memory agent knows the implementation details of each page; no-memory agent must search

## What Changes

- Add **TRAP-M: Pagination UI divergence** — C01, C03 create ad-hoc pagination UI; C11 introduces a specific format; C12 asks for a shared `<Pagination>` component
- Add **TRAP-N: Notification/feedback divergence** — C02, C05, C06 each handle user feedback differently; C10 introduces "toast" as the correct pattern; C12 asks to standardize all feedback to a shared toast system
- Add two new bugs to C12's sprint retro (Bug 10: Pagination UI, Bug 11: Notification system)
- Add evaluator notes to C01, C02, C03, C05, C06, C10, C11, C12 documenting the drift traps
- Add intermediate test checks where feasible
- Update scoring rubric with TRAP-M and TRAP-N sections

## Capabilities

### New Capabilities
- `implementation-drift-traps`: TRAP-M (Pagination UI) and TRAP-N (Notification/feedback) — implementation drift convention traps for the CraftBazaar benchmark. Tests whether memory of own implementation details helps unify divergent patterns.

### Modified Capabilities

## Impact

- Modified files: `benchmark/changes/01-product-catalog.md` (evaluator notes for pagination UI), `benchmark/changes/02-shopping-cart.md` (evaluator notes for notification choice), `benchmark/changes/03-multi-vendor.md` (evaluator notes for pagination UI on new list pages), `benchmark/changes/05-checkout.md` (evaluator notes for error feedback choice), `benchmark/changes/06-order-workflow.md` (evaluator notes for status change feedback), `benchmark/changes/10-cart-ux-correction.md` (evaluator notes — toast introduced here), `benchmark/changes/11-vendor-dashboard-redesign.md` (evaluator notes — pagination UI specified), `benchmark/changes/12-sprint-retro.md` (add Bugs 10-11)
- Modified files: `benchmark/scoring-rubric.md` (add TRAP-M and TRAP-N sections), `benchmark/tests/test-12.sh` (add checks for shared Pagination and Toast components)
- No runtime code changes — all modifications are within the benchmark definition and evaluator
