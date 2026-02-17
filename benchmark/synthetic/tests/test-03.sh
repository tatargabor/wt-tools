#!/bin/bash
# test-03.sh — Comments & Activity (functional checks only)
# Convention probes are in score.sh (run post-hoc, not during agent session)
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

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"03-comments-activity\", \"pass\": $PASS, \"fail\": 0}" > results/change-03.json
  echo "  >> results/change-03.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
