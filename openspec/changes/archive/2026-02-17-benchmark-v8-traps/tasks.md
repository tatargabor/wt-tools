## 1. C02 Change File — Developer Notes

- [x] 1.1 Rewrite `benchmark/synthetic/changes/02-tags-filtering.md` to add a "Developer Notes (from code review of C01)" section containing corrections T7 (dot.notation error codes), T8 (result key wrapper), T9 (POST body for batch ops), T10 (order parameter convention)
- [x] 1.2 Add evaluator notes section documenting which correction maps to which trap and expected memory behavior

## 2. C01 Change File — Ensure SCREAMING_SNAKE baseline

- [x] 2.1 Verify C01 change file (`01-event-crud.md`) explicitly uses SCREAMING_SNAKE error codes and flat response format — these become the "old" patterns that C02 overrides
- [x] 2.2 Verify project-spec.md conventions section documents SCREAMING_SNAKE and flat format (intentionally stale after C02)

## 3. Test Script Updates — New Probes

- [x] 3.1 Update `tests/test-03.sh` to add T7 probe (dot.notation error codes in comments routes), T8 probe (result key in responses), T10 probe (order parameter if applicable)
- [x] 3.2 Update `tests/test-04.sh` to add T7 probe (dot.notation in dashboard/export), T8 probe (result key), T10 probe (order parameter for dashboard recent/timeline)
- [x] 3.3 Update `tests/test-05.sh` to add T7 probe (dot.notation in bulk), T8 probe (result key), T9 probe (POST body for batch IDs, not query params)

## 4. Scoring — Weighted Categories

- [x] 4.1 Update `scripts/score.sh` to add T7 probe (grep for dot.notation vs SCREAMING_SNAKE in C03-C05 source)
- [x] 4.2 Update `scripts/score.sh` to add T8 probe (grep for `result` key wrapping in C03-C05 source)
- [x] 4.3 Update `scripts/score.sh` to add T9 probe (grep for `req.body.ids` vs `req.query.ids` in C05 source)
- [x] 4.4 Update `scripts/score.sh` to add T10 probe (grep for `req.query.order` vs `req.query.sort` in C04-C05 source)
- [x] 4.5 Implement weighted scoring: Category A (T1,T3,T5) x1, Category B (T2,T4,T6,T7,T8,T10) x2, Category C (T9) x3
- [x] 4.6 Update comparison output format to show per-category subtotals and weighted final score
- [x] 4.7 Update JSON output to include categories and weighted scores

## 5. Documentation Updates

- [x] 5.1 Update `scoring-rubric.md` with T7-T10 trap definitions, grep patterns, and category weights
- [x] 5.2 Update `run-guide.md` with n=3 run protocol (3 runs per mode, median scoring)
- [x] 5.3 Update `README.md` quick-start to mention v8 trap categories

## 6. Pre-seed Script

- [x] 6.1 Update `scripts/pre-seed.sh` to include T7-T10 correction memories for Mode C (pre-seeded recall-only mode)

## 7. with-memory.md CLAUDE.md

- [x] 7.1 Update `claude-md/with-memory.md` to ensure recall step mentions correction patterns (so the agent recalls C02 corrections in C03-C05 sessions)
