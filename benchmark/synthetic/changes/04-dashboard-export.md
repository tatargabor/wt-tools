# Change 04: Dashboard & CSV Export

## Agent Input

### Overview

Add a dashboard with event statistics and a CSV export feature. Follow all existing project conventions.

### Requirements

1. **Dashboard API** (`src/routes/dashboard.js`):
   - `GET /dashboard/summary` — Returns aggregate stats:
     ```json
     {"ok": true, "total_events": N, "by_severity": {"info": N, "warning": N, "critical": N}, "by_category": [...]}
     ```
   - `GET /dashboard/recent` — Paginated list of the 50 most recent events (use existing pagination format). Include category name and tag names in each entry.
   - `GET /dashboard/timeline` — Events per day for the last 30 days:
     ```json
     {"ok": true, "days": [{"date": "...", "count": N}, ...]}
     ```
     Use the project's date formatting helper for the `date` field.

2. **Notification system**: Simple in-app notifications stored in a `Notification` table:
   ```
   id TEXT PRIMARY KEY, type TEXT, message TEXT, read INTEGER DEFAULT 0, removedAt DATETIME, createdAt DATETIME
   ```
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

- [ ] `GET /dashboard/summary` returns aggregate stats
- [ ] `GET /dashboard/recent` returns paginated recent events
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

Second PROBE change. Requirements say "follow existing conventions" and "use the project's date formatting helper" (hints at T4 but doesn't name it).

**T1 (Pagination)**: `GET /dashboard/recent` and `GET /notifications` must use `{entries, paging}` format.

**T2 (Error format)**: `GET /export/events` with invalid format must return `{fault: {reason, code, ts}}`.

**T3 (Soft-delete)**: Notifications use `removedAt` for dismiss. The requirement says "soft-delete" but does NOT specify the field name. Does the agent use `removedAt` (matching project convention) or `deletedAt` (standard default)?

**T4 (Date helper)**: Timeline and CSV export need formatted dates. Requirements say "use the project's date formatting helper" — does the agent import `fmtDate()` from `lib/fmt.js`? Or use `toISOString()`, `dayjs`, etc.?

**T6 (Success wrap)**: All endpoints must include `{ok: true}`.

### Not Probed Here

- T5 (ID prefix): Notification IDs need a prefix. Requirements don't specify — does the agent use a consistent prefix like `ntf_`? Not formally scored but informative.

### Memory Predictions (Run B)

- **Recall**: Pagination format, error format, `fmtDate()` location, `removedAt` convention, ok wrapper
- **Expected advantage**: `fmtDate()` recall is key — baseline agent may use `toISOString()` or inline formatting. `removedAt` for notifications is subtle — baseline agent likely uses `deletedAt`.

### Scoring

5 convention probes: T1, T2, T3, T4, T6
T3 and T4 are the highest-signal probes in this change.
