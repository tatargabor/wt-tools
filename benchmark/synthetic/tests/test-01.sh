#!/bin/bash
# test-01.sh — Event & Category CRUD + Convention establishment
# Usage: bash tests/test-01.sh [PORT]

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

echo "=== Test 01: Event & Category CRUD ==="
echo ""

# --- Functional checks ---

check "GET /events returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/events")" = "200" ]'

check "GET /categories returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/categories")" = "200" ]'

check "POST /categories creates a category" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"name\":\"test-cat\"}" "$BASE/categories")" = "201" ]'

check "POST /events creates an event" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"title\":\"Test event\",\"severity\":\"info\"}" "$BASE/events")" = "201" ]'

check "GET /events/:id returns single event" \
  'EVT_ID=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"entries\",d.get(\"data\",[]))[0][\"id\"])" 2>/dev/null) && [ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/events/$EVT_ID")" = "200" ]'

check "DELETE /events/:id returns 200" \
  'EVT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"title\":\"to-delete\"}" "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get(\"result\",d); e=r.get(\"event\",r); print(e.get(\"id\",\"\"))" 2>/dev/null) && [ "$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/events/$EVT_ID")" = "200" ]'

check "Seed data: at least 5 events exist" \
  'COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); p=d.get(\"paging\",{}); print(p.get(\"count\",p.get(\"total\",len(d.get(\"entries\",d.get(\"data\",[]))))))" 2>/dev/null) && [ "$COUNT" -ge 5 ]'

# --- Convention checks (verify C01 establishes them correctly) ---

echo ""
echo "--- Convention checks ---"

check "A1: Pagination uses entries+paging keys" \
  'curl -s "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key\"
p=d[\"paging\"]
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

check "A2: Event IDs use evt_ prefix" \
  'curl -s "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
entries=d.get(\"entries\",d.get(\"data\",[]))
assert len(entries) > 0
assert entries[0][\"id\"].startswith(\"evt_\"), f\"ID does not start with evt_\"
"'

check "A3: Responses include ok: true" \
  'curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

check "A4: lib/fmt.js exists with fmtDate" \
  '[ -f src/lib/fmt.js ] || [ -f lib/fmt.js ]'

check "Error response uses fault format with SCREAMING_SNAKE code" \
  'RESP=$(curl -s "$BASE/events/nonexistent-id") && echo "$RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"fault\" in d and \"reason\" in d[\"fault\"] and \"code\" in d[\"fault\"]
code=d[\"fault\"][\"code\"]
assert code == code.upper() and \"_\" in code, f\"code {code} is not SCREAMING_SNAKE\"
"'

check "Soft-delete: deleted event not in listing" \
  'OLD_COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"paging\",{}).get(\"count\",len(d.get(\"entries\",[]))))" 2>/dev/null) && EVT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"title\":\"soft-del-test\"}" "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get(\"result\",d); e=r.get(\"event\",r); print(e.get(\"id\",\"\"))" 2>/dev/null) && curl -s -X DELETE "$BASE/events/$EVT_ID" > /dev/null && NEW_COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"paging\",{}).get(\"count\",len(d.get(\"entries\",[]))))" 2>/dev/null) && [ "$NEW_COUNT" = "$OLD_COUNT" ]'

check "DB query layer: db/events.js exists" \
  '[ -f src/db/events.js ] || [ -f db/events.js ]'

check "Centralized errors: middleware/errors.js exists" \
  '[ -f src/middleware/errors.js ] || [ -f middleware/errors.js ]'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"01-event-crud\", \"pass\": $PASS, \"fail\": 0}" > results/change-01.json
  echo "  >> results/change-01.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
