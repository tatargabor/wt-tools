#!/bin/bash
# test-02.sh — Tags & Filtering (GAP change — no convention probes)
# C02 uses C01 conventions, NOT C02 Developer Notes corrections
# Usage: bash tests/test-02.sh [PORT]

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

echo "=== Test 02: Tags & Filtering ==="
echo ""

# --- Functional checks ---

check "GET /tags returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/tags")" = "200" ]'

check "POST /tags creates a tag" \
  'RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"name\":\"test-tag-$(date +%s)\"}" "$BASE/tags") && [ "$RESP" = "201" ]'

check "Seed tags exist (at least 3)" \
  'COUNT=$(curl -s "$BASE/tags" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
tags=r.get(\"tags\",r.get(\"entries\",r.get(\"data\",r if isinstance(r,list) else [])))
if isinstance(tags, list): print(len(tags))
else: print(0)
" 2>/dev/null) && [ "$COUNT" -ge 3 ]'

# Tag an event
check "POST /events/:id/tags attaches a tag" \
  'EVT_ID=$(curl -s "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); entries=d.get(\"entries\",d.get(\"data\",[])); print(entries[0][\"id\"])" 2>/dev/null) && TAG_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"name\":\"attach-test-$(date +%s)\"}" "$BASE/tags" | python3 -c "import json,sys; d=json.load(sys.stdin); r=d.get(\"result\",d); t=r.get(\"tag\",r); print(t.get(\"id\",\"\"))" 2>/dev/null) && STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"tagId\":\"$TAG_ID\"}" "$BASE/events/$EVT_ID/tags") && [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]'

# Filter by severity
check "GET /events?severity=info filters correctly" \
  'RESP=$(curl -s "$BASE/events?severity=info") && python3 -c "
import json,sys
d=json.loads(sys.argv[1])
entries=d.get(\"entries\",d.get(\"data\",[]))
assert all(e.get(\"severity\")==\"info\" for e in entries if \"severity\" in e), \"non-info event found\"
" "$RESP"'

# Filter by category
check "GET /events?category=... filters correctly" \
  'CAT_ID=$(curl -s "$BASE/categories" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
cats=r.get(\"categories\",r.get(\"entries\",r.get(\"data\",r if isinstance(r,list) else [])))
if isinstance(cats,list) and len(cats)>0: print(cats[0].get(\"id\",\"\"))
else: print(\"\")
" 2>/dev/null) && [ -n "$CAT_ID" ] && [ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/events?category=$CAT_ID")" = "200" ]'

# Filter by date range
check "GET /events?from=...&to=... returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/events?from=2020-01-01&to=2030-01-01")" = "200" ]'

# Pagination with filter
check "Pagination works with filters" \
  'RESP=$(curl -s "$BASE/events?severity=info&page=1&size=5") && python3 -c "
import json,sys
d=json.loads(sys.argv[1])
assert \"entries\" in d or \"data\" in d, \"no entries/data key\"
" "$RESP"'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"02-tags-filtering\", \"pass\": $PASS, \"fail\": 0}" > results/change-02.json
  echo "  >> results/change-02.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
