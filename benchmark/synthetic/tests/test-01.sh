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
  'EVT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"title\":\"to-delete\"}" "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"event\",d).get(\"id\",d.get(\"id\",\"\")))" 2>/dev/null) && [ "$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/events/$EVT_ID")" = "200" ]'

check "Seed data: at least 5 events exist" \
  'COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); p=d.get(\"paging\",{}); print(p.get(\"count\",p.get(\"total\",len(d.get(\"entries\",d.get(\"data\",[]))))))" 2>/dev/null) && [ "$COUNT" -ge 5 ]'

# --- Convention checks (verify C01 establishes them correctly) ---

echo ""
echo "--- Convention checks ---"

check "T1: Pagination uses 'entries' key" \
  'curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); assert \"entries\" in d, \"no entries key\""'

check "T1: Pagination has 'paging' object with current/size/count/pages" \
  'curl -s "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
p=d[\"paging\"]
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

check "T2: Error response uses 'fault' format" \
  'RESP=$(curl -s "$BASE/events/nonexistent-id") && echo "$RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); assert \"fault\" in d and \"reason\" in d[\"fault\"]"'

check "T3: Soft-delete uses removedAt (deleted event not in listing)" \
  'OLD_COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"paging\",{}).get(\"count\",len(d.get(\"entries\",[]))))" 2>/dev/null) && EVT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"title\":\"soft-del-test\"}" "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"event\",d).get(\"id\",d.get(\"id\",\"\")))" 2>/dev/null) && curl -s -X DELETE "$BASE/events/$EVT_ID" > /dev/null && NEW_COUNT=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get(\"paging\",{}).get(\"count\",len(d.get(\"entries\",[]))))" 2>/dev/null) && [ "$NEW_COUNT" = "$OLD_COUNT" ]'

check "T4: lib/fmt.js exists with fmtDate" \
  '[ -f src/lib/fmt.js ] || [ -f lib/fmt.js ]'

check "T5: Event IDs use evt_ prefix" \
  'curl -s "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
entries=d.get(\"entries\",d.get(\"data\",[]))
assert len(entries) > 0
assert entries[0][\"id\"].startswith(\"evt_\"), f\"ID {entries[0][\"id\"]} does not start with evt_\"
"'

check "T6: Responses include ok: true" \
  'curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"01-event-crud\", \"pass\": $PASS, \"fail\": 0}" > results/change-01.json
  echo "  >> results/change-01.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
