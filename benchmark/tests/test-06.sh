#!/usr/bin/env bash
# test-06.sh - Order Status Workflow tests (Change 06)
# Tests: status transitions, invalid transitions, derived status
PORT="${1:-3000}"
BASE="http://localhost:$PORT"
PASS=0; FAIL=0

check() {
  local name="$1" condition="$2"
  if eval "$condition"; then
    echo "PASS: $name"; ((PASS++))
  else
    echo "FAIL: $name"; ((FAIL++))
  fi
}

echo "=== Test 06: Order Status Workflow ==="
echo "Target: $BASE"
echo ""

# Find an existing order with sub-orders
ORDERS=$(curl -s "$BASE/api/orders" -H "Cookie: sessionId=test-session-03")
SUB_ORDER_ID=$(echo "$ORDERS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('orders', []))
    for o in items:
        subs = o.get('subOrders', o.get('sub_orders', []))
        for s in subs:
            if s.get('status', '') == 'pending':
                print(s['id']); break
        if subs:
            break
    else:
        print('')
except:
    print('')
" 2>/dev/null)

if [ -z "$SUB_ORDER_ID" ]; then
  echo "SKIP: No pending sub-order found — create an order first (test-03)"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# Test: Valid transition (pending → confirmed)
TRANSITION_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE/api/sub-orders/$SUB_ORDER_ID/status" \
  -H "Content-Type: application/json" \
  -d '{"status":"confirmed"}')
check "Valid transition pending→confirmed returns 200" '[ "$TRANSITION_STATUS" = "200" ]'

# Test: Invalid transition (confirmed → delivered, skipping shipped)
INVALID_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE/api/sub-orders/$SUB_ORDER_ID/status" \
  -H "Content-Type: application/json" \
  -d '{"status":"delivered"}')
check "Invalid transition confirmed→delivered returns 400" '[ "$INVALID_STATUS" = "400" ]'

# Test: GET /api/orders/[id] shows derived status
ORDER_ID=$(echo "$ORDERS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('orders', []))
    print(items[0]['id'] if items else '')
except:
    print('')
" 2>/dev/null)

if [ -n "$ORDER_ID" ]; then
  ORDER_DETAIL=$(curl -s "$BASE/api/orders/$ORDER_ID" -H "Cookie: sessionId=test-session-03")
  HAS_STATUS=$(echo "$ORDER_DETAIL" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    status = d.get('status', '')
    print('yes' if status else 'no')
except:
    print('no')
" 2>/dev/null)
  check "GET /api/orders/[id] shows derived status" '[ "$HAS_STATUS" = "yes" ]'
else
  check "GET /api/orders/[id] shows derived status" 'false'
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
