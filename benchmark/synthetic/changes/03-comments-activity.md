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

This is the first PROBE change. The requirements deliberately say "follow existing conventions" without repeating the specifics. The agent must recall or discover them.

**T1 (Pagination)**: Requirements say "follow the project's existing pagination format" — does the agent use `{entries, paging: {current, size, count, pages}}`? Or fall back to `{data, total, page, limit}`?

**T2 (Error format)**: "Error responses follow existing format" — does the agent use `{fault: {reason, code, ts}}`? Or `{error: string}`?

**T5 (ID prefix)**: Comments must use `cmt_` prefix. Activity log entries need an ID too — agent should use a prefix (e.g., `act_`). The spec mentions `cmt_` for comments.

**T6 (Success wrap)**: "Follow existing response conventions" — does the agent include `{ok: true}` in responses?

### Not Probed Here

- T3 (soft-delete): Comments have `removedAt` per spec, but the requirement explicitly says "soft-delete" — too much guidance to count as a probe.
- T4 (date helper): No human-readable date display needed in comments.

### Memory Predictions (Run B)

- **Recall**: Agent should recall pagination format, error format, ID convention, ok wrapper
- **Expected advantage**: Memory agent uses correct conventions immediately. Baseline agent may or may not read C01 code for reference.

### Scoring

4 convention probes: T1, T2, T5, T6
Each is binary PASS/FAIL based on response format.
