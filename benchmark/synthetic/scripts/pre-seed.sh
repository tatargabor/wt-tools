#!/bin/bash
# pre-seed.sh — Inject convention memories for Mode C
# Run from the benchmark project directory

set -euo pipefail

if ! wt-memory health > /dev/null 2>&1; then
  echo "Error: wt-memory is not healthy"
  exit 1
fi

echo "Pre-seeding 6 convention memories..."

echo 'LogBook project convention: All list endpoints return {entries: [...], paging: {current: N, size: N, count: N, pages: N}}. Query params: ?page=1&size=20. Key names: entries (not data), paging (not pagination), current (not page), size (not limit), count (not total), pages (not totalPages). This applies to every paginated endpoint in the project.' \
  | wt-memory remember --type Decision --tags "convention,pagination,api-format"

echo 'LogBook project convention: All error responses use {fault: {reason: string, code: string, ts: string}}. Key: fault (not error), reason (not message). Error codes are SCREAMING_SNAKE. ts is current ISO timestamp. Example: {fault: {reason: "Event not found", code: "EVT_NOT_FOUND", ts: "2026-02-17T10:30:00Z"}}. Do NOT use {error: string} or {message: string, code: string}.' \
  | wt-memory remember --type Decision --tags "convention,error-format,api-format"

echo 'LogBook project convention: Soft-delete uses removedAt column (DATETIME, nullable). NOT deletedAt, NOT isDeleted. All queries filter WHERE removedAt IS NULL. Archive operation = UPDATE SET removedAt = datetime("now"). Purge = hard DELETE WHERE removedAt IS NOT NULL AND removedAt < threshold.' \
  | wt-memory remember --type Decision --tags "convention,soft-delete,database"

echo 'LogBook project convention: All human-readable timestamps use fmtDate(date) from lib/fmt.js. Returns YYYY/MM/DD HH:mm (slash-separated, 24h, no seconds). Import: const { fmtDate } = require("../lib/fmt") or adjust path as needed. Do NOT use toISOString(), toLocaleDateString(), dayjs, moment, or inline date formatting.' \
  | wt-memory remember --type Decision --tags "convention,date-format,utility"

echo 'LogBook project convention: All entity IDs use prefixed nanoid format. Events: evt_<nanoid(12)>, Categories: cat_<nanoid(12)>, Comments: cmt_<nanoid(12)>, Tags: tag_<nanoid(12)>, Batches: bat_<nanoid(12)>. Generated via makeId(prefix) from lib/ids.js which uses nanoid package. Do NOT use auto-increment, UUID, CUID, or ULID.' \
  | wt-memory remember --type Decision --tags "convention,id-format,database"

echo 'LogBook project convention: ALL successful API responses (2xx) include ok: true at the top level. Format: {ok: true, ...payload}. For lists: {ok: true, entries: [...], paging: {...}}. For single items: {ok: true, event: {...}}. For actions: {ok: true, archived: 5}. The ok field is always present and always true for success responses.' \
  | wt-memory remember --type Decision --tags "convention,response-format,api-format"

echo ""
echo "Pre-seeded 6 convention memories successfully."
echo "Verify with: wt-memory list --type Decision"
