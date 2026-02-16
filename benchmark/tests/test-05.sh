#!/usr/bin/env bash
# test-05.sh - Checkout and Payment tests (Change 05)
# Tests: payment intent creation, order confirmation, payout splitting
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

echo "=== Test 05: Checkout and Payment ==="
echo "Target: $BASE"
echo ""

# Add an item to cart
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

if [ -z "$VARIANT_ID" ]; then
  echo "SKIP: No variant found"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

curl -s -X POST "$BASE/api/cart/items" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-05" \
  -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":1}" > /dev/null

# Test: POST /api/checkout creates payment intent
CHECKOUT_RESP=$(curl -s -X POST "$BASE/api/checkout" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-05")
CHECKOUT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/checkout" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-05b")
check "POST /api/checkout returns 200" '[ "$CHECKOUT_STATUS" = "200" ] || [ "$CHECKOUT_STATUS" = "201" ]'

HAS_CLIENT_SECRET=$(echo "$CHECKOUT_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    # Look for clientSecret or client_secret
    secret = d.get('clientSecret', d.get('client_secret', ''))
    print('yes' if secret else 'no')
except:
    print('no')
" 2>/dev/null)
check "Checkout returns client secret" '[ "$HAS_CLIENT_SECRET" = "yes" ]'

# Test: POST /api/checkout/confirm creates order with payment
# Note: This test may fail if Stripe test mode isn't configured properly
# We test the endpoint exists and returns a meaningful response
CONFIRM_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/checkout/confirm" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-05" \
  -d '{"paymentIntentId":"pi_test_fake"}')
# 200 = success, 400 = validation error (expected for fake payment) — both OK
# 404 = endpoint doesn't exist, 500 = server error — both bad
check "POST /api/checkout/confirm endpoint exists" '[ "$CONFIRM_STATUS" != "404" ]'

# --- TRAP-L: Responsive convention checks ---

CHECKOUT_PAGE=$(find src/app/checkout -name "page.tsx" -o -name "page.jsx" 2>/dev/null | head -1)
if [ -n "$CHECKOUT_PAGE" ]; then
  HAS_CONTAINER=$(grep -c "ResponsiveContainer" "$CHECKOUT_PAGE" 2>/dev/null || echo 0)
  check "TRAP-L: Checkout page imports ResponsiveContainer" '[ "$HAS_CONTAINER" -gt 0 ]'
else
  check "TRAP-L: Checkout page imports ResponsiveContainer" 'false'
fi

# --- Convention compliance checks ---
if [[ -f "$(dirname "$0")/lib/check-conventions.sh" ]]; then
  source "$(dirname "$0")/lib/check-conventions.sh"
  echo ""
  echo "=== Convention Checks ==="
  check_convention_pagination "$PORT"
  check_convention_format_price
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-05.json << RESULT
{
  "change": "checkout",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-05.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
