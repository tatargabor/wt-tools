# Change 04: Dashboard & CSV Export

## Agent Input

### Overview

Add a dashboard with event statistics, a notification system, and CSV export. Follow all existing project conventions.

### Requirements

1. **Dashboard API** (`src/routes/dashboard.js`):
   - `GET /dashboard/summary` — Returns aggregate stats:
     ```json
     {"total_events": N, "by_severity": {"info": N, "warning": N, "critical": N}, "by_category": [...]}
     ```
     Categories should be a flat list of `{id, name, count}` objects.
   - `GET /dashboard/recent` — Paginated list of the 50 most recent events. Support ordering. Include category name and tag names in each entry.
   - `GET /dashboard/timeline` — Events per day for the last 30 days:
     ```json
     {"days": [{"date": "...", "count": N}, ...]}
     ```
     Use the project's date formatting helper for the `date` field.

2. **Notification system**: Simple in-app notifications stored in a `Notification` table (see project spec):
   - `GET /notifications` — Paginated list of non-removed notifications.
   - `POST /notifications/:id/read` — Mark as read.
   - `DELETE /notifications/:id` — Dismiss (soft-delete) the notification.
   - Auto-create a notification when a critical event is logged.

3. **CSV Export** (`src/routes/export.js`):
   - `GET /export/events?format=csv` — Export all events as CSV. Columns: `id, title, severity, category, tags, created_at`. Use the project's date formatting helper for the `created_at` column.
   - `GET /export/events?format=json` — Export as JSON array.
   - Return 400 error if format parameter is missing or invalid.

4. **Seed notifications**: Add 3-4 sample notifications to the seed script.

### Acceptance Criteria

- [ ] `GET /dashboard/summary` returns aggregate stats with flat category list
- [ ] `GET /dashboard/recent` returns paginated recent events with ordering support
- [ ] `GET /dashboard/timeline` returns daily counts with formatted dates
- [ ] Notification CRUD works (list, mark-read, dismiss)
- [ ] Dismissed notifications are soft-deleted, not hard-deleted
- [ ] `GET /export/events?format=csv` returns valid CSV with formatted dates
- [ ] `GET /export/events?format=json` returns JSON array
- [ ] Invalid format returns error in existing error format
- [ ] All endpoints follow existing project conventions

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Convention Probes

Second PROBE change. Higher density than C03.

**A1 (Pagination)**: `GET /dashboard/recent` and `GET /notifications` must use `{entries, paging}` format.

**A2 (ID prefix)**: Notification IDs must use `ntf_` prefix per project spec entity definition.

**A3 (Success wrap)**: All endpoints must include `{ok: true}`.

**A4 (Date helper)**: Timeline and CSV export need formatted dates. Requirements say "use the project's date formatting helper" — does the agent import `fmtDate()` from `lib/fmt.js`? Or use `toISOString()`, `dayjs`, etc.?

**B1 (Error codes)**: Export invalid format error must use dot.notation (e.g., `export.invalid_format`), not SCREAMING_SNAKE.

**B2 (Response nesting)**: All responses must use `result` wrapper.

**B3 (Order param)**: `GET /dashboard/recent` supports ordering — does the agent use `?order=newest|oldest` (C02 instruction) or `?sort=desc|asc`?

**C1 (busy_timeout)**: This change creates notifications on critical events — a concurrent write scenario. The test sends 10 simultaneous notification-creating requests. Without `busy_timeout(3000)` in db setup, some will fail with SQLITE_BUSY.

**D1 (Flat categories)**: Dashboard summary has `by_category` — does the agent keep it as a flat list? Or add parent_id / tree structure? Memory agent should remember "flat categories only."

**D2 (DB query layer)**: Does the agent create `db/dashboard.js`, `db/notifications.js`, `db/export.js`? Or inline SQL in routes?

**E1 (ISO 8601 dates)**: CSV export has `created_at` column. The agent should use `fmtDate()` for the display column but NOT change `createdAt` in the events API response (which must stay ISO 8601 for mobile app). The trap: agent might "helpfully" format createdAt in GET /events too.

### Memory Predictions (Run B)

- **Recall**: Pagination, error format (dot.notation), fmtDate, result wrapper, order param, busy_timeout, flat categories, db layer, ISO 8601 constraint
- **Expected advantage**: C1 (busy_timeout) is the strongest signal — baseline will likely crash under concurrent writes. B3 (order param) and D1 (flat categories) are also strong differentiators.

### Scoring

13 probes: A1(x2 for recent+notifications), A2, A3, A4, B1, B2, B3, C1, D1, D2, E1
