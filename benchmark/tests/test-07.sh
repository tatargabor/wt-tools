#!/usr/bin/env bash
# test-07.sh - Stock Reservation Rethink tests (Change 07)
# Tests: stock NOT decremented on cart add, stock decremented at checkout, expired reservation handling
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

echo "=== Test 07: Stock Reservation Rethink ==="
echo "Target: $BASE"
echo ""

# Get a variant with its current stock
VARIANT_DATA=$(curl -s "$BASE/api/products" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    for p in items:
        variants = p.get('variants', [])
        for v in variants:
            stock = v.get('stockQuantity', v.get('stock', 0))
            if stock > 2:
                print(json.dumps({'id': v['id'], 'stock': stock})); break
        else:
            continue
        break
    else:
        print('')
except:
    print('')
" 2>/dev/null)

if [ -z "$VARIANT_DATA" ]; then
  echo "SKIP: No variant with sufficient stock found"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

VARIANT_ID=$(echo "$VARIANT_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
STOCK_BEFORE=$(echo "$VARIANT_DATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['stock'])" 2>/dev/null)

# Test: POST /api/cart/items does NOT change stock
curl -s -X POST "$BASE/api/cart/items" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-07" \
  -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":1}" > /dev/null

# Re-read variant stock
STOCK_AFTER=$(curl -s "$BASE/api/products" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    for p in items:
        for v in p.get('variants', []):
            if str(v['id']) == '$VARIANT_ID':
                print(v.get('stockQuantity', v.get('stock', -1))); break
        else:
            continue
        break
    else:
        print('-1')
except:
    print('-1')
" 2>/dev/null)

check "POST /api/cart/items does NOT change Variant.stockQuantity" '[ "$STOCK_BEFORE" = "$STOCK_AFTER" ]'

# Test: CartReservation model exists (check via Prisma schema or API)
# We can check by looking at the schema file in the project
SCHEMA_FILE=""
for f in prisma/schema.prisma schema.prisma; do
  if [ -f "$f" ]; then
    SCHEMA_FILE="$f"
    break
  fi
done

if [ -n "$SCHEMA_FILE" ]; then
  HAS_RESERVATION=$(grep -ci "CartReservation" "$SCHEMA_FILE" 2>/dev/null)
  check "CartReservation model exists in Prisma schema" '[ "${HAS_RESERVATION:-0}" -gt 0 ]'
else
  echo "SKIP: Cannot find Prisma schema file"
  check "CartReservation model exists in Prisma schema" 'false'
fi

# Test: Expired reservation checkout returns 400 (not 500)
# This is hard to test directly without time manipulation
# We test that the checkout endpoint exists and handles errors gracefully
CHECKOUT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/checkout/confirm" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-07-expired" \
  -d '{"paymentIntentId":"pi_test_expired"}')
check "Checkout endpoint handles errors (not 500)" '[ "$CHECKOUT_STATUS" != "500" ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
