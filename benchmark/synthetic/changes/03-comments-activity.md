# Change 03: Comments & Activity Log

## Agent Input

### Overview

Add a commenting system to events and an activity log that tracks all changes. Follow the existing project conventions established in earlier changes.

### Requirements

1. **Comment model**: Create a `Comment` table per the project spec. Comments belong to an event and have an author and body.

2. **Comment API** (`src/routes/comments.js`):
   - `GET /events/:id/comments` — Paginated list of comments for an event. Follow the project's existing pagination format.
   - `POST /events/:id/comments` — Create a comment (requires `author`, `body`). Return 404 if the event doesn't exist or is removed.
   - `PUT /comments/:id` — Update a comment's body.
   - `DELETE /comments/:id` — Soft-delete the comment.

3. **Activity log**: Create a simple `ActivityLog` table:
   ```
   id TEXT PRIMARY KEY, action TEXT, entityType TEXT, entityId TEXT, detail TEXT, createdAt DATETIME
   ```
   Automatically insert a log entry when events are created, updated, removed, commented on, tagged, or untagged.

4. **Activity API** (`src/routes/activity.js`):
   - `GET /activity` — Paginated list of recent activity, newest first.
   - `GET /events/:id/activity` — Paginated activity for a specific event.

5. **Seed comments**: Add 2-3 comments to existing seed events.

### Acceptance Criteria

- [ ] `POST /events/:id/comments` creates a comment
- [ ] `GET /events/:id/comments` returns paginated comments
- [ ] `PUT /comments/:id` updates a comment
- [ ] `DELETE /comments/:id` soft-deletes a comment
- [ ] Activity log records event CRUD, comments, and tag operations
- [ ] `GET /activity` returns paginated activity list
- [ ] Error responses follow existing format
- [ ] All new endpoints follow existing response conventions

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Convention Probes

First PROBE change. Requirements deliberately say "follow existing conventions" without repeating specifics. The agent must recall or discover them.

**A1 (Pagination)**: "Follow the project's existing pagination format" — does the agent use `{entries, paging: {current, size, count, pages}}`? Or fall back to `{data, total, page, limit}`?

**A2 (ID prefix)**: Comments must use `cmt_` prefix. Activity log entries need an ID — agent should use a prefix (e.g., `act_`). The spec mentions `cmt_` for comments.

**A3 (Success wrap)**: "Follow existing response conventions" — does the agent include `{ok: true}` in responses?

**B1 (Error codes)**: "Error responses follow existing format" — does the agent use dot.notation (from C02 Developer Notes) or SCREAMING_SNAKE (from C01 code)? Memory agents should use dot.notation. Baseline agents will likely copy C01's SCREAMING_SNAKE.

**B2 (Response nesting)**: Does the agent wrap data in a `result` key (C02 correction) or use flat format (C01 code)? Memory agents should use result wrapper.

**D2 (DB query layer)**: Does the agent create `db/comments.js` and `db/activity.js` for SQL queries? Or put inline SQL in routes? The C01 code shows the pattern, and C02 explains why.

**D3 (Centralized errors)**: Does the agent add try-catch blocks in routes/comments.js? Or use `next(err)` and let middleware handle it? C01 code + C02 rationale both point to middleware.

### Not Probed Here

- A4 (Date helper): No human-readable date display needed in comments.
- B3 (Order param): No ordering endpoint in C03.
- B4 (removedAt): Comments have `removedAt` per spec, and the requirement explicitly says "soft-delete" — too much guidance.
- C1-C3: No concurrent write triggers or bulk operations.
- D1: No category aggregation.
- E1-E3: No mobile compat or bulk limits.

### Memory Predictions (Run B)

- **Recall**: Agent should recall B1 (dot.notation), B2 (result key), D2 (db layer), D3 (middleware errors)
- **Expected advantage**: Memory agent uses dot.notation + result wrapper immediately. Baseline agent copies C01's SCREAMING_SNAKE + flat format.

### Scoring

7 probes: A1, A2, A3, B1, B2, D2, D3
