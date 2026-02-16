## 1. Revision change definitions (07-09)

- [x] 1.1 Create `benchmark/changes/07-stock-rethink.md` — agent input: reverse C02 stock-on-add to soft-reserve with 15min TTL, stock only decreases at checkout. Evaluator notes: memory predictions, measurable criteria.
- [x] 1.2 Create `benchmark/changes/08-images-table.md` — agent input: migrate C01 JSON-string images to separate Image table with altText, sortOrder. Evaluator notes per spec.
- [x] 1.3 Create `benchmark/changes/09-integer-cents.md` — agent input: all Decimal/Float money fields to Int cents across C01,C03,C04,C05. Evaluator notes per spec.

## 2. Feedback change definitions (10-11)

- [x] 2.1 Create `benchmark/changes/10-cart-ux-correction.md` — agent input: 4 specific UX corrections to C02 cart page (inline edit, toast not confirm, real-time total, CTA on empty). Evaluator notes: repeat-failure trap, counter-pattern analysis.
- [x] 2.2 Create `benchmark/changes/11-vendor-dashboard-redesign.md` — agent input: replace C06 tabbed dashboard with flat date-sorted list, badge status, dropdown actions, pagination. Evaluator notes: counter-pattern trap.

## 3. Sprint retro change definition (12)

- [x] 3.1 Create `benchmark/changes/12-sprint-retro.md` — agent input: 5 vague bug descriptions (API inconsistency, payout rounding, expired reservation 500, missing index, seed data mismatch). Evaluator notes: hardest memory test, expected iteration difference.

## 4. Per-change acceptance tests

- [x] 4.1 Create `benchmark/tests/test-01.sh` through `test-06.sh` — curl-based tests for original changes: product CRUD, cart operations, vendor/order creation, coupon validation, checkout flow, status transitions.
- [x] 4.2 Create `benchmark/tests/test-07.sh` through `test-09.sh` — tests for revision changes: stock NOT decremented on cart add, Image table exists and API returns new format, all money fields are Int and payout math is exact.
- [x] 4.3 Create `benchmark/tests/test-10.sh` and `test-11.sh` — HTML/source inspection tests: no confirm() in cart, no Update button, no tabs in dashboard, pagination and badges present.
- [x] 4.4 Create `benchmark/tests/test-12.sh` — sprint retro tests: all 5 bugs verified (API format, payout sum, reservation error code, index, seed consistency).

## 5. Targeted recall hook

- [x] 5.1 Modify `bin/wt-hook-memory-recall` — only fire on change boundary (compare with `.claude/last-recall-change` marker). For revision changes, also recall the original change. Zero output when skipping.

## 6. Evaluator scripts

- [x] 6.1 Create `benchmark/evaluator/eval-schema.sh` — check Prisma schema for Image table, Int money fields, CartReservation, Variant table, indexes. Output JSON.
- [x] 6.2 Create `benchmark/evaluator/eval-api.sh` — check API routes for consistent response format and money format. Output JSON.
- [x] 6.3 Create `benchmark/evaluator/eval-behavior.sh` — check stock logic placement, checkout transactionality, payout formula. Output JSON.
- [x] 6.4 Create `benchmark/evaluator/eval-coherence.sh` — run prisma validate, tsc, seed script. Output JSON.
- [x] 6.5 Create `benchmark/evaluator/collect-results.sh` and `compare.sh` — gather metrics and generate comparison report.

## 7. Benchmark infrastructure updates

- [x] 7.1 Update `benchmark/init-baseline.sh` and `benchmark/init-with-memory.sh` to include changes 07-12, copy test scripts to `tests/` dir.
- [x] 7.2 Update `benchmark/claude-md/baseline.md` and `with-memory.md` — reference 12 changes, add test instructions ("run tests/test-NN.sh after each apply, fix until pass").
- [x] 7.3 Update `benchmark/scoring-rubric.md` — add test pass/fail metrics, revision change scoring, sprint retro scoring.
- [x] 7.4 Update `benchmark/run-guide.md` — new iteration budget (--max 30), test runner instructions, evaluator usage.
