#!/bin/bash
# test-03.sh — Comments & Activity + Convention probes
# Probes: A1, A2, A3, B1, B2, D2, D3
# Usage: bash tests/test-03.sh [PORT]

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

echo "=== Test 03: Comments & Activity ==="
echo ""

# Get a valid event ID
EVT_ID=$(curl -s "$BASE/events" | python3 -c "
import json,sys
d=json.load(sys.stdin)
entries=d.get('entries',d.get('data',[]))
print(entries[0]['id'] if entries else '')
" 2>/dev/null)

# --- Functional checks ---

check "POST /events/:id/comments creates comment" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"author\":\"tester\",\"body\":\"test comment\"}" "$BASE/events/'"$EVT_ID"'/comments")" = "201" ]'

check "GET /events/:id/comments returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/events/'"$EVT_ID"'/comments")" = "200" ]'

check "PUT /comments/:id updates a comment" \
  'CMT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"author\":\"updater\",\"body\":\"will update\"}" "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
c=r.get(\"comment\",r)
print(c.get(\"id\",\"\"))
" 2>/dev/null) && [ "$(curl -s -o /dev/null -w "%{http_code}" -X PUT -H "Content-Type: application/json" -d "{\"body\":\"updated body\"}" "$BASE/comments/$CMT_ID")" = "200" ]'

check "DELETE /comments/:id soft-deletes" \
  'CMT_ID=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"author\":\"deleter\",\"body\":\"will delete\"}" "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
c=r.get(\"comment\",r)
print(c.get(\"id\",\"\"))
" 2>/dev/null) && [ "$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/comments/$CMT_ID")" = "200" ]'

check "GET /activity returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/activity")" = "200" ]'

# --- Convention probes ---
echo ""
echo "--- Convention probes ---"

# A1: Pagination format on comments
check "A1: Comments pagination uses entries+paging" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
assert \"entries\" in r, \"no entries key in comments response\"
p=r.get(\"paging\",r)
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p, \"paging missing fields\"
"'

# A1: Pagination format on activity
check "A1: Activity pagination uses entries+paging" \
  'curl -s "$BASE/activity" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
assert \"entries\" in r, \"no entries key in activity response\"
p=r.get(\"paging\",r)
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p, \"paging missing fields\"
"'

# A2: Comment IDs use cmt_ prefix
check "A2: Comment IDs use cmt_ prefix" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
entries=r.get(\"entries\",r.get(\"data\",[]))
assert len(entries) > 0, \"no comments found\"
assert entries[0][\"id\"].startswith(\"cmt_\"), f\"comment ID {entries[0][\"id\"]} does not start with cmt_\"
"'

# A2: Activity IDs use a prefix
check "A2: Activity log entries have prefixed IDs" \
  'curl -s "$BASE/activity" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
entries=r.get(\"entries\",r.get(\"data\",[]))
assert len(entries) > 0, \"no activity entries\"
aid=entries[0][\"id\"]
assert \"_\" in aid, f\"activity ID {aid} has no prefix separator\"
"'

# A3: Success wrapper
check "A3: Comments response has ok: true" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# B1: Error codes use dot.notation (NOT SCREAMING_SNAKE)
check "B1: 404 error uses dot.notation code" \
  'RESP=$(curl -s "$BASE/events/nonexistent/comments") && python3 -c "
import json,sys
d=json.loads(sys.argv[1])
f=d.get(\"fault\",{})
code=f.get(\"code\",\"\")
assert \".\" in code, f\"error code {code} is not dot.notation — should be like event.not_found\"
assert code == code.lower(), f\"error code {code} has uppercase — dot.notation should be lowercase\"
" "$RESP"'

# B2: Response nesting — result wrapper
check "B2: Comments response wraps data in result key" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"result\" in d, \"no result key — response should wrap data in result\"
assert \"entries\" in d[\"result\"], \"entries should be inside result\"
"'

# D2: DB query layer — db/comments.js exists
check "D2: db/comments.js exists (query layer)" \
  '[ -f src/db/comments.js ] || [ -f db/comments.js ]'

# D3: No try-catch in routes (centralized error handling)
check "D3: routes/comments.js has no try-catch blocks" \
  'ROUTE_FILE=""; [ -f src/routes/comments.js ] && ROUTE_FILE=src/routes/comments.js; [ -f routes/comments.js ] && ROUTE_FILE=routes/comments.js; [ -n "$ROUTE_FILE" ] && ! grep -q "try {" "$ROUTE_FILE"'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"03-comments-activity\", \"pass\": $PASS, \"fail\": 0}" > results/change-03.json
  echo "  >> results/change-03.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
