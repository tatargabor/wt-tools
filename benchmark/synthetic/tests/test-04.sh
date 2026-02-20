#!/bin/bash
# test-04.sh — Dashboard & Export + Convention probes
# Probes: A1(x2), A2, A3, A4, B1, B2, B3, C1, D1, D2, E1
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

check "GET /notifications returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/notifications")" = "200" ]'

check "GET /export/events?format=csv returns CSV" \
  'RESP=$(curl -s -w "\n%{http_code}" "$BASE/export/events?format=csv") && CODE=$(echo "$RESP" | tail -1) && [ "$CODE" = "200" ]'

check "GET /export/events?format=json returns JSON" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/export/events?format=json")" = "200" ]'

check "GET /export/events without format returns 400" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/export/events")" = "400" ]'

# --- Convention probes ---
echo ""
echo "--- Convention probes ---"

# A1: Pagination on dashboard/recent
check "A1: Dashboard recent uses entries+paging" \
  'curl -s "$BASE/dashboard/recent" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
assert \"entries\" in r, \"no entries key\"
p=r.get(\"paging\",r)
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

# A1: Pagination on notifications
check "A1: Notifications uses entries+paging" \
  'curl -s "$BASE/notifications" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
assert \"entries\" in r, \"no entries key\"
p=r.get(\"paging\",r)
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

# A2: Notification IDs use ntf_ prefix
check "A2: Notification IDs use ntf_ prefix" \
  'curl -s "$BASE/notifications" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
entries=r.get(\"entries\",r.get(\"data\",[]))
if len(entries) == 0:
    sys.exit(1)
assert entries[0][\"id\"].startswith(\"ntf_\"), f\"notification ID {entries[0][\"id\"]} does not start with ntf_\"
"'

# A3: Success wrapper
check "A3: Dashboard summary has ok: true" \
  'curl -s "$BASE/dashboard/summary" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# A4: Date formatting uses fmtDate (YYYY/MM/DD HH:mm)
check "A4: Timeline dates use project date format (YYYY/MM/DD)" \
  'curl -s "$BASE/dashboard/timeline" | python3 -c "
import json,sys,re
d=json.load(sys.stdin)
r=d.get(\"result\",d)
days=r.get(\"days\",[])
if len(days) > 0:
    date=days[0].get(\"date\",\"\")
    assert \"/\" in date, f\"date {date} does not use slash format from fmtDate\"
    assert re.match(r\"\d{4}/\d{2}/\d{2}\", date), f\"date {date} does not match YYYY/MM/DD\"
"'

# B1: Error code uses dot.notation
check "B1: Export invalid format error uses dot.notation" \
  'RESP=$(curl -s "$BASE/export/events?format=xml") && python3 -c "
import json,sys
d=json.loads(sys.argv[1])
f=d.get(\"fault\",{})
code=f.get(\"code\",\"\")
assert \".\" in code, f\"error code {code} is not dot.notation\"
assert code == code.lower(), f\"error code {code} has uppercase\"
" "$RESP"'

# B2: Response nesting
check "B2: Dashboard summary wraps data in result key" \
  'curl -s "$BASE/dashboard/summary" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"result\" in d, \"no result key — response should wrap data in result\"
"'

# B3: Order parameter uses ?order=newest|oldest
check "B3: Dashboard recent supports ?order=newest" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/dashboard/recent?order=newest")" = "200" ]'

check "B3: Dashboard recent supports ?order=oldest" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/dashboard/recent?order=oldest")" = "200" ]'

# C1: Concurrent write test (busy_timeout)
check "C1: 10 concurrent critical event POSTs succeed (busy_timeout)" \
  'PIDS=""; FAILS=0
for i in $(seq 1 10); do
  curl -s -o /tmp/c1_resp_$i -w "%{http_code}" -X POST -H "Content-Type: application/json" \
    -d "{\"title\":\"concurrent-$i\",\"severity\":\"critical\"}" "$BASE/events" > /tmp/c1_code_$i &
  PIDS="$PIDS $!"
done
for PID in $PIDS; do wait $PID; done
for i in $(seq 1 10); do
  CODE=$(cat /tmp/c1_code_$i 2>/dev/null)
  [ "$CODE" != "201" ] && [ "$CODE" != "200" ] && FAILS=$((FAILS+1))
  rm -f /tmp/c1_resp_$i /tmp/c1_code_$i
done
[ $FAILS -eq 0 ]'

# D1: Dashboard categories are flat (no parent/child)
check "D1: Dashboard summary categories are flat list" \
  'curl -s "$BASE/dashboard/summary" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get(\"result\",d)
cats=r.get(\"by_category\",[])
if len(cats) > 0:
    c=cats[0]
    assert \"parent\" not in c and \"parent_id\" not in c and \"parentId\" not in c and \"children\" not in c, \"categories should be flat\"
"'

# D2: DB query layer
check "D2: db/ query files exist for dashboard" \
  '[ -f src/db/dashboard.js ] || [ -f db/dashboard.js ] || [ -f src/db/notifications.js ] || [ -f db/notifications.js ]'

# E1: Events API returns ISO 8601 createdAt (not fmtDate format)
check "E1: GET /events createdAt is ISO 8601 (not custom format)" \
  'curl -s "$BASE/events" | python3 -c "
import json,sys,re
d=json.load(sys.stdin)
entries=d.get(\"entries\",d.get(\"data\",[]))
if len(entries) > 0:
    ca=entries[0].get(\"createdAt\",entries[0].get(\"created_at\",\"\"))
    assert \"T\" in ca or re.match(r\"\d{4}-\d{2}-\d{2}\", ca), f\"createdAt {ca} is not ISO 8601\"
    assert \"/\" not in ca, f\"createdAt {ca} uses slash format — should be ISO 8601 for mobile app\"
"'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"04-dashboard-export\", \"pass\": $PASS, \"fail\": 0}" > results/change-04.json
  echo "  >> results/change-04.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
