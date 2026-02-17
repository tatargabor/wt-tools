#!/bin/bash
# test-04.sh — Dashboard & Export (functional checks only)
# Convention probes are in score.sh (run post-hoc, not during agent session)
# Usage: bash tests/test-04.sh [PORT]

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

echo "=== Test 04: Dashboard & Export ==="
echo ""

# --- Functional checks ---

check "GET /dashboard/summary returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/dashboard/summary")" = "200" ]'

check "GET /dashboard/recent returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/dashboard/recent")" = "200" ]'

check "GET /dashboard/timeline returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/dashboard/timeline")" = "200" ]'

check "GET /export/events?format=csv returns CSV" \
  'CT=$(curl -s -D- -o /dev/null "$BASE/export/events?format=csv" 2>&1 | grep -i content-type) && echo "$CT" | grep -qi "text/csv\|text/plain\|application/octet"'

check "GET /export/events?format=json returns JSON array" \
  'curl -s "$BASE/export/events?format=json" | python3 -c "import json,sys; d=json.load(sys.stdin); assert isinstance(d.get(\"events\",d.get(\"data\",d if isinstance(d,list) else None)),list)"'

check "GET /notifications returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/notifications")" = "200" ]'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"04-dashboard-export\", \"pass\": $PASS, \"fail\": 0}" > results/change-04.json
  echo "  >> results/change-04.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
