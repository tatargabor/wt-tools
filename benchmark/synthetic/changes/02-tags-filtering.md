# Change 02: Tags & Filtering

## Agent Input

### Overview

Add a tagging system to LogBook. Events can have multiple tags, and users can filter events by tag, category, severity, and date range.

### Requirements

1. **Tag model**: Create a `Tag` table (see project spec) and an `EventTag` join table for the many-to-many relationship.

2. **Tag API** (`src/routes/tags.js`):
   - `GET /tags` — List all tags (no pagination needed — tags are few)
   - `POST /tags` — Create a tag (requires `name`, must be unique)
   - `DELETE /tags/:id` — Hard-delete a tag and its EventTag associations

3. **Event tagging**:
   - `POST /events/:id/tags` — Attach a tag to an event. Body: `{"tagId": "tag_xxx"}`. Return 409 if already attached.
   - `DELETE /events/:id/tags/:tagId` — Remove a tag from an event.
   - `GET /events/:id` — Include `tags` array in the event response (list of `{id, name}`).

4. **Event filtering** — Enhance `GET /events`:
   - `?category=cat_xxx` — Filter by category ID
   - `?severity=critical` — Filter by severity level
   - `?tag=tag_xxx` — Filter by tag (events that have this tag)
   - `?from=2026-01-01&to=2026-02-01` — Filter by date range (inclusive)
   - Filters are combinable (AND logic)
   - Pagination still applies on top of filters

5. **Seed tags**: Add 5 tags to the seed script (`deployment`, `incident`, `release`, `maintenance`, `security`) and assign 2-3 tags to each existing event.

### Developer Notes (from code review of C01)

We reviewed the C01 implementation and have some corrections. **These apply to FUTURE changes (C03 onward) — do NOT apply them in this change (C02).** We don't want to expand the scope of this already-reviewed PR.

1. **Error code format change**: Starting in C03, switch from SCREAMING_SNAKE error codes (like `EVT_NOT_FOUND`) to **dot.notation** format. Use lowercase with dots: `event.not_found`, `comment.invalid_body`, `export.unsupported_format`. Don't change C02 error codes — keep them SCREAMING_SNAKE to match C01.

2. **Response nesting**: Starting in C03, wrap entity data in a `result` key. This helps the frontend team distinguish payload from metadata.
   - List responses: `{"ok": true, "result": {"entries": [...], "paging": {...}}}`
   - Single-item responses: `{"ok": true, "result": {"comment": {...}}}`
   - Action responses: `{"ok": true, "result": {"removed": true}}`
   Don't apply to C02 — the tags API spec is finalized with the flat format.

3. **Batch operations advice**: When we add bulk endpoints in a future change, always use **POST with body `{"ids": [...]}`** for operations on multiple items. Express doesn't parse array query params (`?ids=1,2,3`) reliably. Keep this in mind for later.

4. **Sort/order convention**: For any endpoint that supports ordering, use a `?order=newest|oldest` query parameter — **not** `?sort=desc|asc`. Our frontend expects the `order` param name with human-readable values. Apply this whenever you add ordering support in future changes.

### Acceptance Criteria

- [ ] Tag CRUD works (create, list, delete)
- [ ] Events can be tagged and untagged
- [ ] `GET /events/:id` includes `tags` array
- [ ] `GET /events?category=...` filters by category
- [ ] `GET /events?severity=...` filters by severity
- [ ] `GET /events?tag=...` filters by tag
- [ ] `GET /events?from=...&to=...` filters by date range
- [ ] Filters combine with AND logic
- [ ] Pagination works with filters applied
- [ ] Seed script includes tags and event-tag associations

<!-- EVALUATOR NOTES BELOW — NOT INCLUDED IN AGENT INPUT -->

## Evaluator Notes

### Purpose

C02 is now the **CORRECTION** change — it introduces human feedback that overrides C01 conventions. This is the core mechanism for creating memory-unique knowledge.

### Developer Notes → Trap Mapping

| Dev Note | Trap | Category | What it overrides |
|----------|------|----------|-------------------|
| 1. dot.notation error codes | T7 | B (human override) | C01's SCREAMING_SNAKE + project-spec.md |
| 2. result key wrapper | T8 | B (human override) | C01's flat format + project-spec.md |
| 3. POST body for batch | T9 | C (forward-looking) | No code exists — memory-only |
| 4. order parameter | T10 | B (human override) | No code exists — memory-only |

### Memory Predictions (Run B)

- **Save**: Agent should save all 4 Developer Notes as Decision/Learning memories
  - T7: "Error codes switched from SCREAMING_SNAKE to dot.notation"
  - T8: "Wrap responses in result key"
  - T9: "Use POST body for batch ops, not query params"
  - T10: "Use ?order=newest|oldest, not ?sort=desc|asc"
- **Recall**: Agent may recall C01 conventions (useful but C02 now overrides some)

### Scoring Notes

C02 itself is NOT probed in scoring. The probes are in C03-C05. C02's job is to:
1. Establish the correction knowledge (via Developer Notes)
2. Let the agent save it to memory (Mode B)
3. Create conflicting signals for no-memory agents (C01 code + stale spec ≠ C02 corrections)
