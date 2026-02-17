#!/bin/bash
# test-03.sh — Comments & Activity (PROBE: T1, T2, T5, T6, T7, T8)
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

check "GET /activity returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/activity")" = "200" ]'

# --- Convention probes ---

echo ""
echo "--- Convention probes ---"

# T1: Pagination format on comments
check "T1-PROBE: Comment list uses 'entries' + 'paging' format" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key — expected project pagination format\"
assert \"paging\" in d, \"no paging key\"
p=d[\"paging\"]
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p, \"paging missing fields\"
"'

# T1: Pagination on activity
check "T1-PROBE: Activity list uses 'entries' + 'paging' format" \
  'curl -s "$BASE/activity" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key\"
assert \"paging\" in d, \"no paging key\"
"'

# T2: Error format
check "T2-PROBE: 404 on missing event uses 'fault' format" \
  'RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"author\":\"x\",\"body\":\"y\"}" "$BASE/events/nonexistent/comments") && echo "$RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"fault\" in d, \"expected fault key in error response\"
assert \"reason\" in d[\"fault\"], \"expected reason in fault\"
"'

# T5: Comment IDs use cmt_ prefix
check "T5-PROBE: Comment IDs use cmt_ prefix" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "
import json,sys
d=json.load(sys.stdin)
entries=d.get(\"entries\",d.get(\"data\",[]))
assert len(entries) > 0, \"no comments found\"
cid=entries[0][\"id\"]
assert cid.startswith(\"cmt_\"), f\"Comment ID {cid} does not start with cmt_\"
"'

# T6: ok wrapper on comment responses
check "T6-PROBE: Comment list includes ok: true" \
  'curl -s "$BASE/events/'"$EVT_ID"'/comments" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True, \"missing ok: true\""'

check "T6-PROBE: Activity list includes ok: true" \
  'curl -s "$BASE/activity" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True, \"missing ok: true\""'

# T7: Error codes use dot.notation (not SCREAMING_SNAKE)
check "T7-PROBE: Comment error codes use dot.notation (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*comment*" 2>/dev/null); do grep -qE "['\''\"]\w+\.\w+['\''\"]\s*;?\s*$|code.*['\''\"]\w+\.\w+['\''\"]\s*|err\.code\s*=\s*['\''\"]\w+\.\w+['\''\"]\s*" "$f" && FOUND=true; done; $FOUND'

check "T7-PROBE: Comment error codes NOT SCREAMING_SNAKE (source check)" \
  'FAIL=false; for f in $(find src -name "*.js" -path "*comment*" 2>/dev/null); do grep -qE "err\.code\s*=\s*['\''\"]\s*[A-Z]{2,}_[A-Z]{2,}" "$f" && FAIL=true; done; ! $FAIL'

# T8: Response wraps data in result key
check "T8-PROBE: Comment list response uses result key (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*comment*" 2>/dev/null); do grep -qE "result\s*:" "$f" && FOUND=true; done; $FOUND'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"03-comments-activity\", \"pass\": $PASS, \"fail\": 0}" > results/change-03.json
  echo "  >> results/change-03.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
