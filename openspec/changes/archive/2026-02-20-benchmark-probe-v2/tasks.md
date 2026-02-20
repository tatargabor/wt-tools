## 1. Project Foundation

- [x] 1.1 Update project-spec.md — keep LogBook domain, add SQLite WAL mention (but NOT busy_timeout trick), add Express body-parser defaults (but NOT the limit increase), keep conventions section matching v1 but with SCREAMING_SNAKE error codes (to create B1 conflict)
- [x] 1.2 Update CLAUDE.md variants (baseline.md, with-memory.md) — adjust for v2 trap categories, keep port assignments, update benchmark task workflow

## 2. Change Definitions

- [x] 2.1 Rewrite C01 (01-event-crud.md) — establish A-type conventions in code: pagination format, SCREAMING_SNAKE errors, flat response (no result key), prefixed IDs, fmtDate helper, removedAt soft-delete, db/ query layer, centralized error middleware
- [x] 2.2 Rewrite C02 (02-tags-filtering.md) — keep tags/filtering requirements, redesign Developer Notes with all 14 knowledge items across B/C/D/E categories, written as natural code review feedback
- [x] 2.3 Rewrite C03 (03-comments-activity.md) — comments + activity log requirements, say "follow existing conventions" without details, evaluator notes map 9 probes (3A + 2B + 2D)
- [x] 2.4 Rewrite C04 (04-dashboard-export.md) — dashboard + notifications + CSV export, include natural triggers for C1 (concurrent writes to notifications), evaluator notes map 13 probes (4A + 3B + 1C + 2D + 1E)
- [x] 2.5 Rewrite C05 (05-bulk-operations.md) — bulk archive/tag/purge, include natural triggers for C2 (batch IDs), C3 (large payloads), E2 (>100 items), E3 (max results), evaluator notes map 13 probes (3A + 3B + 2C + 1D + 2E)

## 3. Test Scripts

- [x] 3.1 Rewrite test-01.sh — verify C01 implementation: event/category CRUD, pagination format, error format (SCREAMING_SNAKE here), ID prefixes, success wrapper
- [x] 3.2 Rewrite test-02.sh — verify C02 implementation: tags CRUD, event filtering, tag association (uses C01 conventions, NOT C02 corrections)
- [x] 3.3 Rewrite test-03.sh — 9 probe functions: A1 (pagination on comments), A2 (cmt_/act_ prefixes), A3 (ok:true), B1 (dot.notation errors), B2 (result wrapper), D2 (check db/comments.js exists), D3 (no try-catch in routes/comments.js)
- [x] 3.4 Rewrite test-04.sh — 13 probe functions: A1 (pagination on recent/notifications), A2 (ntf_ prefix), A3 (ok:true), A4 (fmtDate on timeline/export), B1 (dot.notation), B2 (result wrapper), B3 (?order param on recent), C1 (10 concurrent notification POSTs), D1 (flat categories in dashboard), D2 (db/dashboard.js exists), E1 (ISO 8601 dates on events)
- [x] 3.5 Rewrite test-05.sh — 13 probe functions: A1 (pagination on history), A2 (bat_ prefix), A3 (ok:true), B1 (dot.notation), B2 (result wrapper), B4 (removedAt in bulk archive), C2 (batch ID length >=16), C3 (POST 500kb bulk payload succeeds), D2 (db/bulk.js exists), E2 (reject >100 items), E3 (history max 1000 results)

## 4. Scoring & Automation

- [x] 4.1 Rewrite score.sh — 5-category weighted scoring (A:x1, B:x2, C:x3, D:x2, E:x3), per-category breakdown, --compare mode, --json output
- [x] 4.2 Update init.sh — keep 4 modes (a/b/c/d), update file copies for v2, verify evaluator notes stripped
- [x] 4.3 Update run.sh — keep per-session runner, adjust max-turns if needed
- [x] 4.4 Update pre-seed.sh — add B/C/D/E knowledge items to pre-seeded memories for mode C
- [x] 4.5 Update pre-rules.sh — add B/C/D/E rules for mode D

## 5. Documentation

- [x] 5.1 Update run-guide.md — v2 trap categories, expected scores, probe counts, updated examples
