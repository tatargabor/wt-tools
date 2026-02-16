#!/usr/bin/env bash
# test-03.sh - Multi-Vendor tests (Change 03)
# Tests: vendor CRUD, order creation with sub-orders
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

echo "=== Test 03: Multi-Vendor ==="
echo "Target: $BASE"
echo ""

# Test: GET /api/vendors returns vendors
VENDORS=$(curl -s "$BASE/api/vendors")
VENDOR_COUNT=$(echo "$VENDORS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('vendors', []))
    print(len(items))
except:
    print(0)
" 2>/dev/null)
check "GET /api/vendors returns vendors" '[ "$VENDOR_COUNT" -gt 0 ]'

# Test: Vendors exist (seed data)
check "At least 2 vendors in seed data" '[ "$VENDOR_COUNT" -ge 2 ]'

# Test: POST /api/orders creates an order
# First add items to cart
VARIANT_ID=$(curl -s "$BASE/api/products" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    for p in items:
        variants = p.get('variants', [])
        if variants:
            print(variants[0]['id']); break
    else:
        print('')
except:
    print('')
" 2>/dev/null)

if [ -n "$VARIANT_ID" ]; then
  # Add to cart
  curl -s -X POST "$BASE/api/cart/items" \
    -H "Content-Type: application/json" \
    -H "Cookie: sessionId=test-session-03" \
    -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":1}" > /dev/null

  # Create order
  ORDER_RESP=$(curl -s -X POST "$BASE/api/orders" \
    -H "Content-Type: application/json" \
    -H "Cookie: sessionId=test-session-03")
  HAS_ORDER=$(echo "$ORDER_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    print('yes' if d.get('id') else 'no')
except:
    print('no')
" 2>/dev/null)
  check "POST /api/orders creates an order" '[ "$HAS_ORDER" = "yes" ]'

  # Test: Order has sub-orders
  ORDER_ID=$(echo "$ORDER_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    print(d.get('id', ''))
except:
    print('')
" 2>/dev/null)

  if [ -n "$ORDER_ID" ]; then
    ORDER_DETAIL=$(curl -s "$BASE/api/orders/$ORDER_ID" -H "Cookie: sessionId=test-session-03")
    HAS_SUBORDERS=$(echo "$ORDER_DETAIL" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    subs = d.get('subOrders', d.get('sub_orders', []))
    print('yes' if len(subs) > 0 else 'no')
except:
    print('no')
" 2>/dev/null)
    check "Order has sub-orders grouped by vendor" '[ "$HAS_SUBORDERS" = "yes" ]'
  else
    check "Order has sub-orders grouped by vendor" 'false'
  fi
else
  check "POST /api/orders creates an order" 'false'
  check "Order has sub-orders grouped by vendor" 'false'
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-03.json << RESULT
{
  "change": "multi-vendor",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-03.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
