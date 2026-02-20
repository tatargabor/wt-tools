#!/bin/bash
# pre-rules.sh — Inject all conventions into .claude/rules.yaml for Mode D (MemoryProbe v2)
# Covers all 5 categories: A (code-readable), B (human override), C (debug), D (architecture), E (stakeholder)
# Run from the benchmark TARGET project directory

set -euo pipefail

CLAUDE_DIR=".claude"
RULES_FILE="$CLAUDE_DIR/rules.yaml"

mkdir -p "$CLAUDE_DIR"

echo "Writing $RULES_FILE with v2 convention rules (A1-A4, B1-B4, C1-C3, D1-D3, E1-E3)..."

cat > "$RULES_FILE" << 'YAML'
rules:

  # === Category A: Code-readable conventions ===

  - id: pagination-format
    topics: [paging, pagination, list, entries, page, size]
    content: |
      All list endpoints return {entries: [...], paging: {current: N, size: N, count: N, pages: N}}.
      Query params: ?page=1&size=20.
      Key names: entries (NOT data), paging (NOT pagination), current (NOT page),
      size (NOT limit), count (NOT total), pages (NOT totalPages).

  - id: id-prefix-format
    topics: [id, nanoid, identifier, makeId, prefix]
    content: |
      All entity IDs use prefixed nanoid format via makeId(prefix) from lib/ids.js:
        Events: evt_, Categories: cat_, Comments: cmt_, Tags: tag_,
        Activity: act_, Notifications: ntf_, Batches: bat_
      Do NOT use auto-increment, UUID, CUID, or ULID.

  - id: success-wrapper
    topics: [response, ok, success, wrapper, 2xx]
    content: |
      ALL successful responses (2xx) include {ok: true, ...payload}.
      The ok field is always present at the top level.

  - id: date-helper
    topics: [date, timestamp, fmtDate, format, datetime]
    content: |
      Human-readable dates use fmtDate(date) from lib/fmt.js.
      Returns: YYYY/MM/DD HH:mm (slash-separated, 24-hour, no seconds).
      Use for display fields like timeline dates, export dates.
      NOTE: Do NOT use fmtDate for createdAt fields — those must stay ISO 8601.

  # === Category B: Human override conventions (corrections from C02 code review) ===

  - id: error-code-dot-notation
    topics: [error, fault, code, notation, dot, snake, 4xx, 5xx]
    content: |
      Error codes MUST use dot.notation: "event.not_found", "comment.invalid_body",
      "export.unsupported_format". All lowercase.
      Do NOT use SCREAMING_SNAKE (EVT_NOT_FOUND, COMMENT_INVALID).
      The project-spec.md says SCREAMING_SNAKE but that is outdated — dot.notation
      is the current standard starting from C03.

  - id: response-nesting-result-key
    topics: [nesting, result, entries, response, wrapper, payload]
    content: |
      Starting from C03, all successful responses nest data inside a "result" key.
      List:   {ok: true, result: {entries: [...], paging: {...}}}
      Single: {ok: true, result: {comment: {...}}}
      Action: {ok: true, result: {removed: true}}
      Do NOT use flat format like {ok: true, entries: [...]} — always wrap in result.

  - id: order-parameter
    topics: [sort, order, ordering, newest, oldest, asc, desc]
    content: |
      Sorting/ordering uses ?order=newest|oldest (NOT ?sort=desc|asc or ?sortBy=).
      Values are semantic: "newest" and "oldest" (not "asc"/"desc").
      Apply to any endpoint returning ordered lists.

  - id: soft-delete-removedAt
    topics: [delete, archive, soft-delete, removedAt, deletedAt]
    content: |
      Soft-delete uses removedAt column (DATETIME, nullable). NOT deletedAt. NOT isDeleted.
      "removed" implies soft-delete (can be restored), "deleted" implies hard-delete.
      Be consistent across all tables.

  # === Category C: Debug knowledge (invisible in code) ===

  - id: sqlite-busy-timeout
    topics: [sqlite, busy, concurrent, write, lock, WAL, timeout]
    content: |
      Set busy_timeout(3000) in db/setup.js right after opening the connection.
      WAL mode alone is NOT enough — you need busy_timeout too.
      Without it, concurrent writes cause intermittent SQLITE_BUSY errors.

  - id: nanoid-collision-batch
    topics: [nanoid, collision, batch, bulk, id, length]
    content: |
      For batch/bulk operation IDs, use nanoid(16) or longer — NOT nanoid(8).
      With 8 characters, collision probability rises sharply above ~100K records.
      The existing makeId uses nanoid(12) which is fine for entity IDs,
      but batch operations that create many IDs need 16+.

  - id: body-parser-limit
    topics: [body-parser, json, limit, payload, 413, large, bulk, import]
    content: |
      The default express.json() limit is 100KB. For endpoints that accept
      large payloads (bulk operations, imports), configure body parser with
      { limit: '1mb' }. Don't change it globally — just on the specific router.

  # === Category D: Architecture decisions ===

  - id: flat-categories
    topics: [category, categories, parent, child, hierarchy, tree, nested]
    content: |
      Categories are intentionally flat — NO parent/child hierarchy.
      Hierarchical categories were tried early and it was a UX disaster.
      Dashboard aggregates by category as a flat list, not a tree.
      Do NOT add parent_id or nesting to categories.

  - id: db-query-layer
    topics: [sql, query, database, db, inline, route]
    content: |
      ALL SQL queries go in db/*.js modules. Routes call db functions —
      routes MUST NOT contain inline SQL. This is how schema migrations
      and query optimization work. When a table changes, update one file.

  - id: centralized-error-handler
    topics: [error, middleware, try-catch, catch, handler, next]
    content: |
      All error formatting goes through middleware/errors.js.
      Routes throw errors or call next(err) — they do NOT catch errors
      and format responses themselves. No try-catch blocks wrapping
      entire route handlers. Consistent format in one place.

  # === Category E: Stakeholder constraints (external requirements) ===

  - id: iso-8601-createdAt
    topics: [createdAt, ISO, 8601, mobile, app, date, format]
    content: |
      The mobile app v2 (50K+ users) expects createdAt as ISO 8601 string.
      Do NOT change createdAt to fmtDate() format or Unix timestamps.
      fmtDate() is for human-readable display fields only.
      Breaking this = P0 production incident.

  - id: bulk-max-100-items
    topics: [bulk, batch, limit, max, items, 100, eventIds]
    content: |
      Ops team requirement: all bulk endpoints MUST reject requests with
      more than 100 items. Return 400 error if eventIds or similar arrays
      exceed 100. Hard limit to prevent database lock timeouts.

  - id: list-max-1000-results
    topics: [list, size, max, 1000, pagination, cap, limit]
    content: |
      All paginated list endpoints MUST cap size parameter at 1000 max.
      If ?size=5000 is passed, treat as ?size=1000.
      Responses above 5MB cause mobile client timeouts.
YAML

echo "Done. Created $RULES_FILE with 17 rules across 5 categories."
echo "  A (code-readable):  4 rules (A1-A4)"
echo "  B (human override): 4 rules (B1-B4)"
echo "  C (debug):          3 rules (C1-C3)"
echo "  D (architecture):   3 rules (D1-D3)"
echo "  E (stakeholder):    3 rules (E1-E3)"
echo ""
echo "Verify with: cat $RULES_FILE"
