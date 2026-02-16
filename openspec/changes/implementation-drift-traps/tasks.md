## 1. TRAP-M Evaluator Notes — Pagination UI Drift

- [x] 1.1 Add TRAP-M evaluator notes to `benchmark/changes/01-product-catalog.md`: document that evaluator should note what pagination UI the agent builds on `/products` (Prev/Next, Load More, page numbers, nothing). Expected memory save: pagination approach details.
- [x] 1.2 Add TRAP-M evaluator notes to `benchmark/changes/03-multi-vendor.md`: document that evaluator should compare `/vendors` and `/orders` pagination UI with C01's `/products` pattern. Note divergence. Expected memory recall: C01 pagination approach.
- [x] 1.3 Add TRAP-M evaluator notes to `benchmark/changes/11-vendor-dashboard-redesign.md`: document that C11 explicitly requires pagination (Prev/Next + page numbers). Note whether agent creates a reusable component or ad-hoc implementation. Expected memory recall: prior pagination implementations.

## 2. TRAP-N Evaluator Notes — Notification/Feedback Drift

- [x] 2.1 Add TRAP-N evaluator notes to `benchmark/changes/02-shopping-cart.md`: document that evaluator should note what feedback pattern the agent uses on cart item removal (alert, inline, console.log, nothing). Expected memory save: feedback approach.
- [x] 2.2 Add TRAP-N evaluator notes to `benchmark/changes/05-checkout.md`: document that evaluator should note checkout error/success feedback pattern. Compare with C02. Expected memory recall: C02 feedback.
- [x] 2.3 Add TRAP-N evaluator notes to `benchmark/changes/06-order-workflow.md`: document that evaluator should note vendor status update feedback pattern. Compare with C02 and C05. Expected memory recall: prior feedback patterns.
- [x] 2.4 Add TRAP-N evaluator notes to `benchmark/changes/10-cart-ux-correction.md`: document that C10 explicitly introduces "toast with undo" for cart. Note whether agent builds reusable toast system or cart-only. Note whether agent retroactively updates other pages.

## 3. C12 Sprint Retro — New Bugs

- [x] 3.1 Add Bug 10 to `benchmark/changes/12-sprint-retro.md` Agent Input: "Pagination UI inconsistency — different pages use different pagination controls. Create shared `<Pagination>` component at `src/components/Pagination.tsx` (props: page, totalPages, onPageChange). Replace all ad-hoc pagination UI."
- [x] 3.2 Add Bug 10 evaluator notes to C12: document that this is TRAP-M payoff, memory agent knows which pages have pagination and what each uses, no-memory agent must search. Track iterations for Bug 10 separately.
- [x] 3.3 Add Bug 11 to `benchmark/changes/12-sprint-retro.md` Agent Input: "Inconsistent user feedback — cart uses toast, other pages use alert(), inline messages, or nothing. Create shared toast system at `src/components/Toast.tsx`. Replace ALL window.alert() and window.confirm() calls with toast notifications."
- [x] 3.4 Add Bug 11 evaluator notes to C12: document that this is TRAP-N payoff, memory agent knows which pages use which pattern, no-memory agent must grep. Track iterations for Bug 11 separately.

## 4. Test Script Updates

- [x] 4.1 Add Bug 10 checks to `benchmark/tests/test-12.sh`: check `src/components/Pagination.tsx` exists, check list pages import it, check no inline pagination buttons outside component
- [x] 4.2 Add Bug 11 checks to `benchmark/tests/test-12.sh`: check `src/components/Toast.tsx` exists, check zero `window.alert(` in `src/`, check zero `window.confirm(` in `src/`, check at least 3 files import Toast

## 5. Scoring Rubric

- [x] 5.1 Add TRAP-M section to `benchmark/scoring-rubric.md`: scoring table for Pagination UI drift (C01 initial, C03 divergence, C11 reusability, C12 iterations/completeness)
- [x] 5.2 Add TRAP-N section to `benchmark/scoring-rubric.md`: scoring table for Notification/feedback drift (C02 initial, C05 error, C06 status, C10 toast reuse, C12 iterations/completeness)
- [x] 5.3 Update C12 summary in scoring rubric: increase from "9 bugs" to "11 bugs", add Bug 10 and Bug 11 to the per-bug scoring table
