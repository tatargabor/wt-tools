## 1. Data Extraction

- [x] 1.1 Extract per-change iteration counts and token usage from `wt-loop history` for both runs (Phase 1: C01-C09, Phase 2: C10-C12)
- [x] 1.2 Collect all test results from `results/change-NN.json` for both runs into a comparison table
- [x] 1.3 Extract git log timestamps per change for wall-clock timing comparison

## 2. Convention Trap Analysis (new in v5)

- [x] 2.1 TRAP-H (formatPrice): Audit all `formatPrice` imports and `.toFixed(2)` usages across both codebases, score per-change
- [x] 2.2 TRAP-I (pagination): Audit all list API endpoints for `{ data, total, page, limit }` format in both runs, score per-change
- [x] 2.3 TRAP-J (error codes): Audit all API error responses for `errors.ts` constant usage in both runs, score per-change
- [x] 2.4 TRAP-K (soft delete): Audit all product queries for `deletedAt` filtering in both runs, score per-change

## 3. Original Trap Analysis (from v4)

- [x] 3.1 Score TRAP-A (images migration C01→C08), TRAP-B ($queryRaw C02→C05), TRAP-D (float money C04→C09) for both runs
- [x] 3.2 Score TRAP-E (API consistency), TRAP-F (coupon/stock cross-dep C04→C07), TRAP-G (UI regressions) for both runs

## 4. Memory Quality Audit

- [x] 4.1 List all Run B memories, categorize each as high/medium/low value with justification
- [x] 4.2 Analyze code map memory coverage: how many changes have maps, agent vs hook generated, quality assessment
- [x] 4.3 Check for convention-specific memories (formatPrice, pagination, errors.ts, soft delete) — document gaps

## 5. C10-C12 Deep Dive (highest memory-value changes)

- [x] 5.1 C10 (cart UX correction): Check counter-pattern compliance — did either run add Update button or confirm()?
- [x] 5.2 C11 (dashboard redesign): Check tab removal, badge implementation, pagination convention recall
- [x] 5.3 C12 (sprint retro): Score all 9 bugs individually for both runs — this is the key memory test

## 6. Write v5-results.md

- [x] 6.1 Create `benchmark/v5-results.md` with: overall metrics table, trap analysis, per-change scoring, memory audit, v4→v5 comparison, and 3-5 prioritized improvement recommendations
