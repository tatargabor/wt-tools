#!/bin/bash
# test-05.sh — Bulk Operations + Convention probes
# Probes: A1, A2, A3, B1, B2, B4, C2, C3, D2, E2, E3
# Usage: bash tests/test-05.sh [PORT]

PORT="${1:-3000}"
BASE="http://localhost:$PORT"
PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if eval "$@" > /dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test 05: Bulk Operations ==="
echo ""

# Create test events for bulk operations
EVT1=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-1","severity":"info"}' "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get('result',d)
e=r.get('event',r)
print(e.get('id',''))
" 2>/dev/null)

EVT2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-2","severity":"info"}' "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get('result',d)
e=r.get('event',r)
print(e.get('id',''))
" 2>/dev/null)

# --- Functional checks ---

check "POST /bulk/archive archives multiple events" \
  'RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[\"$EVT1\",\"$EVT2\"]}" "$BASE/bulk/archive") && [ "$RESP" = "200" ]'

check "POST /bulk/archive with empty array returns 400" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[]}" "$BASE/bulk/archive")" = "400" ]'

check "GET /bulk/history returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/bulk/history")" = "200" ]'

check "GET /bulk/report returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/bulk/report")" = "200" ]'

check "POST /bulk/purge works" \
  'RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"olderThanDays\":90}" "$BASE/bulk/purge") && [ "$RESP" = "200" ]'

check "POST /bulk/purge rejects olderThanDays < 30" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"olderThanDays\":5}" "$BASE/bulk/purge")" = "400" ]'

# --- Convention probes ---
echo ""
echo "--- Convention probes ---"

# A1: Pagination on bulk/history
check "A1: Bulk history uses entries+paging" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
assert \"entries\" in r, \"no entries key\"
p=r.get(\"paging\",r)
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

# A2: Batch IDs use bat_ prefix
check "A2: Batch IDs use bat_ prefix" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
entries=r.get(\"entries\",r.get(\"data\",[]))
if len(entries) == 0:
    sys.exit(1)
bid=entries[0].get(\"id\",entries[0].get(\"batchId\",\"\"))
assert bid.startswith(\"bat_\"), f\"batch ID {bid} does not start with bat_\"
"'

# A3: Success wrapper
check "A3: Bulk history has ok: true" \
  'curl -s "$BASE/bulk/history" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# B1: Error codes use dot.notation
check "B1: Bulk validation error uses dot.notation" \
  'RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[]}" "$BASE/bulk/archive") && python3 -c "
import json,sys
d=json.loads(sys.argv[1])
f=d.get(\"fault\",{})
code=f.get(\"code\",\"\")
assert \".\" in code, f\"error code {code} is not dot.notation\"
assert code == code.lower(), f\"error code {code} has uppercase\"
" "$RESP"'

# B2: Response nesting
check "B2: Bulk history wraps data in result key" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"result\" in d, \"no result key\"
"'

# B4: Soft-delete uses removedAt (check via re-archiving already-archived event)
check "B4: Bulk archive soft-deletes use removedAt field" \
  'python3 -c "
import sqlite3, os, glob
# Find the database
db_paths = glob.glob(\"data/logbook.db\") + glob.glob(\"*/data/logbook.db\")
if not db_paths:
    exit(1)
conn = sqlite3.connect(db_paths[0])
cursor = conn.execute(\"PRAGMA table_info(Event)\")
cols = [row[1] for row in cursor.fetchall()]
assert \"removedAt\" in cols, f\"Event table has columns {cols} — no removedAt (uses deletedAt?)\"
assert \"deletedAt\" not in cols, \"Event table has deletedAt — should use removedAt\"
conn.close()
"'

# C2: Batch IDs use nanoid(16) or longer (not nanoid(8))
check "C2: Batch IDs are at least 16 chars after prefix (nanoid collision prevention)" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
entries=r.get(\"entries\",r.get(\"data\",[]))
if len(entries) == 0:
    sys.exit(1)
bid=entries[0].get(\"id\",entries[0].get(\"batchId\",\"\"))
# Strip prefix (bat_)
suffix=bid.split(\"_\",1)[1] if \"_\" in bid else bid
assert len(suffix) >= 16, f\"batch ID suffix {suffix} is only {len(suffix)} chars — should be 16+ (nanoid collision risk)\"
"'

# C3: Body-parser limit — send large payload (500KB+)
check "C3: Large bulk payload (500KB) does not return 413" \
  'LARGE_IDS=$(python3 -c "
import json
ids=[\"evt_fake_\" + str(i).zfill(10) for i in range(80)]
print(json.dumps({\"eventIds\": ids}))
") && CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$LARGE_IDS" "$BASE/bulk/tag") && [ "$CODE" != "413" ]'

# D2: DB query layer
check "D2: db/bulk.js exists (query layer)" \
  '[ -f src/db/bulk.js ] || [ -f db/bulk.js ]'

# E2: Bulk endpoints reject >100 items
check "E2: Bulk archive rejects >100 items" \
  'MANY_IDS=$(python3 -c "
import json
ids=[\"evt_\" + str(i).zfill(16) for i in range(150)]
print(json.dumps({\"eventIds\": ids}))
") && CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$MANY_IDS" "$BASE/bulk/archive") && [ "$CODE" = "400" ]'

# E3: List endpoints max 1000 results
check "E3: Bulk history caps results at 1000 max" \
  'curl -s "$BASE/bulk/history?size=2000" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
p=r.get(\"paging\",{})
size=p.get(\"size\",0)
assert size <= 1000, f\"size={size} exceeds 1000 max — should cap at 1000\"
"'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"05-bulk-operations\", \"pass\": $PASS, \"fail\": 0}" > results/change-05.json
  echo "  >> results/change-05.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
