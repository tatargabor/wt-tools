#!/bin/bash
# test-04.sh — Dashboard & Export (PROBE: T1, T2, T3, T4, T6, T7, T8, T10)
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

# --- Convention probes ---

echo ""
echo "--- Convention probes ---"

# T1: Pagination format on dashboard/recent
check "T1-PROBE: Dashboard recent uses 'entries' + 'paging' format" \
  'curl -s "$BASE/dashboard/recent" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key\"
assert \"paging\" in d, \"no paging key\"
p=d[\"paging\"]
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

# T1: Pagination on notifications
check "T1-PROBE: Notifications uses 'entries' + 'paging' format" \
  'curl -s "$BASE/notifications" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key\"
assert \"paging\" in d, \"no paging key\"
"'

# T2: Error format on invalid export
check "T2-PROBE: Invalid export format returns 'fault'" \
  'RESP=$(curl -s "$BASE/export/events?format=xml") && echo "$RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"fault\" in d, \"expected fault key\"
assert \"reason\" in d[\"fault\"], \"expected reason in fault\"
"'

# T3: Soft-delete uses removedAt on notifications
check "T3-PROBE: Notification dismiss uses removedAt (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*notification*" -o -name "*.js" -path "*dashboard*" 2>/dev/null); do grep -q "removedAt" "$f" && FOUND=true; done; $FOUND'

# T4: Date helper usage in export
check "T4-PROBE: Export uses fmtDate (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*export*" 2>/dev/null); do grep -q "fmtDate\|require.*fmt\|from.*fmt" "$f" && FOUND=true; done; $FOUND'

# T4: Date helper in timeline
check "T4-PROBE: Timeline dates use slash format (YYYY/MM/DD)" \
  'curl -s "$BASE/dashboard/timeline" | python3 -c "
import json,sys
d=json.load(sys.stdin)
days=d.get(\"days\",d.get(\"entries\",[]))
if days:
    date=days[0].get(\"date\",\"\")
    assert \"/\" in date, f\"Date {date} does not use slash format\"
"'

# T6: Success wrapper
check "T6-PROBE: Dashboard summary includes ok: true" \
  'curl -s "$BASE/dashboard/summary" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

check "T6-PROBE: Dashboard recent includes ok: true" \
  'curl -s "$BASE/dashboard/recent" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# T7: Error codes use dot.notation (not SCREAMING_SNAKE)
check "T7-PROBE: Dashboard/export error codes use dot.notation (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*export*" -o -name "*.js" -path "*dashboard*" 2>/dev/null); do grep -qE "err\.code\s*=\s*['\''\"]\w+\.\w+" "$f" && FOUND=true; done; $FOUND'

# T8: Response wraps data in result key
check "T8-PROBE: Dashboard responses use result key (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*dashboard*" 2>/dev/null); do grep -qE "result\s*:" "$f" && FOUND=true; done; $FOUND'

# T10: Sort uses ?order= not ?sort=
check "T10-PROBE: Dashboard uses order parameter, not sort (source check)" \
  'HAS_ORDER=false; HAS_SORT=false; for f in $(find src -name "*.js" -path "*dashboard*" -o -name "*.js" -path "*activity*" 2>/dev/null); do grep -qE "req\.query\.order|order.*newest|order.*oldest" "$f" && HAS_ORDER=true; grep -qE "req\.query\.sort\b" "$f" && HAS_SORT=true; done; $HAS_ORDER && ! $HAS_SORT'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"04-dashboard-export\", \"pass\": $PASS, \"fail\": 0}" > results/change-04.json
  echo "  >> results/change-04.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
