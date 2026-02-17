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

This is the GAP change — intentionally no new convention probes. Its purpose is to push C01's conventions out of the agent's immediate focus before C03 starts probing.

### Conventions Expected

Even though this is a gap change, the agent should still follow existing conventions:
- Tag IDs should use `tag_` prefix (T5)
- Tag listing response should use `ok: true` wrapper (T6)
- Error responses should use `{fault}` format (T2)

These are NOT scored as probes (C01 code is still fresh in context). They're just baseline consistency checks.

### Memory Predictions (Run B)

- **Save**: Agent may save tagging patterns or filter implementation details
- **Recall**: Agent may recall C01 conventions (useful but not decisive — C01 is recent)
