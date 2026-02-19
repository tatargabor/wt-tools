#!/bin/bash
# pre-rules.sh — Inject all 10 conventions into .claude/rules.yaml for Mode D
# Run from the benchmark TARGET project directory

set -euo pipefail

CLAUDE_DIR=".claude"
RULES_FILE="$CLAUDE_DIR/rules.yaml"

mkdir -p "$CLAUDE_DIR"

echo "Writing $RULES_FILE with all 10 conventions (T1-T10)..."

cat > "$RULES_FILE" << 'YAML'
rules:

  # Category A: Code-readable conventions

  - id: pagination-format
    topics: [paging, pagination, list, entries, page, size]
    content: |
      All list endpoints return {entries: [...], paging: {current: N, size: N, count: N, pages: N}}.
      Query params: ?page=1&size=20.
      Key names: entries (NOT data), paging (NOT pagination), current (NOT page),
      size (NOT limit), count (NOT total), pages (NOT totalPages).
      Applies to EVERY paginated endpoint.

  - id: soft-delete-column
    topics: [delete, archive, soft-delete, removedAt, deletedAt]
    content: |
      Soft-delete uses removedAt column (DATETIME, nullable). NOT deletedAt. NOT isDeleted.
      All queries filter WHERE removedAt IS NULL.
      Archive = UPDATE SET removedAt = datetime("now").
      Purge = hard DELETE WHERE removedAt IS NOT NULL.

  - id: id-format
    topics: [id, nanoid, identifier, makeId, prefix]
    content: |
      All entity IDs use prefixed nanoid format:
        Events:     evt_<nanoid(12)>
        Categories: cat_<nanoid(12)>
        Comments:   cmt_<nanoid(12)>
        Tags:       tag_<nanoid(12)>
        Batches:    bat_<nanoid(12)>
      Use makeId(prefix) from lib/ids.js. Do NOT use auto-increment, UUID, CUID, or ULID.

  # Category B: Human override conventions (corrections from C02)

  - id: error-format
    topics: [error, fault, response, exception, 4xx, 5xx]
    content: |
      All error responses: {fault: {reason: string, code: string, ts: string}}.
      Key: fault (NOT error). reason (NOT message). ts is current ISO timestamp.
      Error codes: dot.notation like "event.not_found", "comment.invalid"
      NOT SCREAMING_SNAKE like EVT_NOT_FOUND — even though project-spec.md says SCREAMING_SNAKE,
      dot.notation is the current standard.

  - id: date-format
    topics: [date, timestamp, fmtDate, format, createdAt, updatedAt, datetime]
    content: |
      ALL timestamps in API responses use fmtDate(date) from lib/fmt.js.
      Returns: YYYY/MM/DD HH:mm (slash-separated, 24-hour, no seconds).
      Import: const { fmtDate } = require("../lib/fmt") (adjust relative path).
      Applies to ALL date fields: createdAt, updatedAt, timestamps in listings, etc.
      Do NOT use toISOString(), toLocaleDateString(), dayjs, moment, or inline formatting.

  - id: success-response-format
    topics: [response, ok, result, success, wrapper, 2xx]
    content: |
      ALL successful responses (2xx) wrap payload in a result key.
      Format: {ok: true, result: {...}}
      Lists:   {ok: true, result: {entries: [...], paging: {...}}}
      Single:  {ok: true, result: {event: {...}}}
      Actions: {ok: true, result: {archived: 5}}
      The ok field and result wrapper are ALWAYS present for success. Never flat format.

  - id: error-code-notation
    topics: [error, code, notation, dot, snake]
    content: |
      Error codes MUST use dot.notation: "event.not_found", "comment.invalid_body",
      "export.unsupported_format".
      Do NOT use SCREAMING_SNAKE (EVT_NOT_FOUND, COMMENT_INVALID).
      project-spec.md is outdated on this — dot.notation is the current standard.

  - id: response-nesting
    topics: [nesting, result, entries, response, wrapper]
    content: |
      All successful responses nest data inside a "result" key.
      List:   {ok: true, result: {entries: [...], paging: {...}}}
      Single: {ok: true, result: {event: {...}}}
      Do NOT use flat format like {ok: true, entries: [...]} — always wrap in result.

  - id: sort-parameter
    topics: [sort, order, ordering, newest, oldest, asc, desc]
    content: |
      Sorting/ordering uses ?order=newest|oldest (NOT ?sort=desc|asc or ?sortBy=).
      Values are semantic: "newest" and "oldest" (not "asc"/"desc").
      Apply to any endpoint returning ordered lists (dashboard/recent, timelines, feeds).

  # Category C: Forward-looking advice

  - id: batch-ids-in-body
    topics: [batch, bulk, ids, multiple, post, body]
    content: |
      Batch endpoints that accept multiple IDs use POST with IDs in request body: {ids: ["evt_abc", "evt_def"]}.
      Do NOT use GET with query params like ?ids=evt_abc,evt_def.
      POST body is the project standard for all batch ID operations.
YAML

echo "Done. Created $RULES_FILE with 10 rules (T1-T10)."
echo ""
echo "Verify with: cat $RULES_FILE"
