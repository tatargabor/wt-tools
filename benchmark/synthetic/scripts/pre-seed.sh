#!/bin/bash
# pre-seed.sh — Inject convention memories for Mode C
# Run from the benchmark project directory

set -euo pipefail

if ! wt-memory health > /dev/null 2>&1; then
  echo "Error: wt-memory is not healthy"
  exit 1
fi

echo "Pre-seeding 10 convention memories (T1-T10)..."
echo ""

# --- Category A: Code-readable conventions (T1, T3, T5) ---

echo "Category A: Code-readable conventions..."

echo 'LogBook project convention: All list endpoints return {entries: [...], paging: {current: N, size: N, count: N, pages: N}}. Query params: ?page=1&size=20. Key names: entries (not data), paging (not pagination), current (not page), size (not limit), count (not total), pages (not totalPages). This applies to every paginated endpoint in the project.' \
  | wt-memory remember --type Decision --tags "convention,pagination,api-format,trap:T1,category:A"

echo 'LogBook project convention: Soft-delete uses removedAt column (DATETIME, nullable). NOT deletedAt, NOT isDeleted. All queries filter WHERE removedAt IS NULL. Archive operation = UPDATE SET removedAt = datetime("now"). Purge = hard DELETE WHERE removedAt IS NOT NULL AND removedAt < threshold.' \
  | wt-memory remember --type Decision --tags "convention,soft-delete,database,trap:T3,category:A"

echo 'LogBook project convention: All entity IDs use prefixed nanoid format. Events: evt_<nanoid(12)>, Categories: cat_<nanoid(12)>, Comments: cmt_<nanoid(12)>, Tags: tag_<nanoid(12)>, Batches: bat_<nanoid(12)>. Generated via makeId(prefix) from lib/ids.js which uses nanoid package. Do NOT use auto-increment, UUID, CUID, or ULID.' \
  | wt-memory remember --type Decision --tags "convention,id-format,database,trap:T5,category:A"

# --- Category B: Human override conventions (T2, T4, T6, T7, T8, T10) ---

echo ""
echo "Category B: Human override conventions (C02 corrections)..."

echo 'LogBook project convention: All error responses use {fault: {reason: string, code: string, ts: string}}. Key: fault (not error), reason (not message). ts is current ISO timestamp. Error codes use dot.notation format like "event.not_found" or "comment.invalid" (NOT SCREAMING_SNAKE like EVT_NOT_FOUND). Example: {fault: {reason: "Event not found", code: "event.not_found", ts: "2026-02-17T10:30:00Z"}}.' \
  | wt-memory remember --type Decision --tags "convention,error-format,api-format,trap:T2,category:A"

echo 'LogBook project convention: ALL timestamps in API responses (not just display dates) must use fmtDate(date) from lib/fmt.js. Returns YYYY/MM/DD HH:mm (slash-separated, 24h, no seconds). Import: const { fmtDate } = require("../lib/fmt") or adjust path. This applies to ALL dates in responses — createdAt, updatedAt, timestamps in listings, etc. Do NOT use toISOString(), toLocaleDateString(), dayjs, moment, or inline formatting for any date field.' \
  | wt-memory remember --type Decision --tags "convention,date-format,utility,trap:T4,category:B"

echo 'LogBook project convention: ALL successful API responses (2xx) wrap payload in a result key. Format: {ok: true, result: {...}}. For lists: {ok: true, result: {entries: [...], paging: {...}}}. For single items: {ok: true, result: {event: {...}}}. For actions: {ok: true, result: {archived: 5}}. The ok field and result wrapper are always present for success responses.' \
  | wt-memory remember --type Decision --tags "convention,response-format,api-format,trap:T6,trap:T8,category:B"

echo 'LogBook correction (from code review): Error codes MUST use dot.notation format, e.g. "event.not_found", "comment.invalid_body", "export.unsupported_format". Do NOT use SCREAMING_SNAKE like EVT_NOT_FOUND or COMMENT_INVALID. The project-spec.md still says SCREAMING_SNAKE but that is outdated — dot.notation is the current standard.' \
  | wt-memory remember --type Decision --tags "convention,error-codes,correction,trap:T7,category:B"

echo 'LogBook correction (from code review): All successful responses must nest data inside a "result" key. List: {ok: true, result: {entries: [...], paging: {...}}}. Single: {ok: true, result: {event: {...}}}. Do NOT use flat format like {ok: true, entries: [...]} — always wrap in result.' \
  | wt-memory remember --type Decision --tags "convention,response-nesting,correction,trap:T8,category:B"

echo 'LogBook correction (from code review): Sorting/ordering uses ?order=newest|oldest parameter (not ?sort=desc|asc or ?sortBy=). Values are semantic: "newest" and "oldest" (not "asc"/"desc"). Apply to any endpoint that returns ordered lists (dashboard/recent, timelines, activity feeds).' \
  | wt-memory remember --type Decision --tags "convention,sort-parameter,correction,trap:T10,category:B"

# --- Category C: Forward-looking advice (T9) ---

echo ""
echo "Category C: Forward-looking advice..."

echo 'LogBook advice for future batch operations: When implementing endpoints that accept multiple IDs (bulk archive, bulk delete, batch fetch), always use POST with IDs in the request body: {ids: ["evt_abc", "evt_def"]}. Do NOT use GET with query parameters like ?ids=evt_abc,evt_def. POST body is the project standard for batch ID operations.' \
  | wt-memory remember --type Decision --tags "convention,batch-operations,advice,trap:T9,category:C"

echo ""
echo "Pre-seeded 10 convention memories successfully."
echo "  Category A (code-readable): 3 memories (T1, T3, T5)"
echo "  Category B (human override): 5 memories (T2, T4, T6+T8, T7, T10)"
echo "  Category C (forward-looking): 1 memory (T9)"
echo ""
echo "Note: T6 and T8 share one memory (both about success response format)."
echo "Verify with: wt-memory list --type Decision"
