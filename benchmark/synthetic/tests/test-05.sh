#!/bin/bash
# test-05.sh — Bulk Operations (functional checks only)
# Convention probes are in score.sh (run post-hoc, not during agent session)
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
EVT1=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-1","severity":"info"}' "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('event',d).get('id',d.get('id','')))" 2>/dev/null)
EVT2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-2","severity":"info"}' "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('event',d).get('id',d.get('id','')))" 2>/dev/null)

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

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"05-bulk-operations\", \"pass\": $PASS, \"fail\": 0}" > results/change-05.json
  echo "  >> results/change-05.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
