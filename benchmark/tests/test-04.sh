#!/usr/bin/env bash
# test-04.sh - Discount and Coupon tests (Change 04)
# Tests: coupon validation, discount application, cart totals
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

echo "=== Test 04: Discounts and Coupons ==="
echo "Target: $BASE"
echo ""

# Get a valid coupon code from the API (if coupons are listable)
# First try to get a vendor ID for vendor coupons
VENDOR_ID=$(curl -s "$BASE/api/vendors" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('vendors', []))
    print(items[0]['id'] if items else '')
except:
    print('')
" 2>/dev/null)

# Try to get coupon codes from vendor coupons API
COUPON_CODE=""
if [ -n "$VENDOR_ID" ]; then
  COUPONS=$(curl -s "$BASE/api/vendors/$VENDOR_ID/coupons")
  COUPON_CODE=$(echo "$COUPONS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('coupons', []))
    for c in items:
        if c.get('isActive', True):
            print(c.get('code', '')); break
    else:
        print('')
except:
    print('')
" 2>/dev/null)
fi

# Add an item to cart first
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
  curl -s -X POST "$BASE/api/cart/items" \
    -H "Content-Type: application/json" \
    -H "Cookie: sessionId=test-session-04" \
    -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":2}" > /dev/null
fi

# Test: POST /api/cart/coupon with valid coupon
if [ -n "$COUPON_CODE" ]; then
  APPLY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/cart/coupon" \
    -H "Content-Type: application/json" \
    -H "Cookie: sessionId=test-session-04" \
    -d "{\"code\":\"$COUPON_CODE\"}")
  check "POST /api/cart/coupon applies valid coupon (200)" '[ "$APPLY_STATUS" = "200" ]'

  # Test: Cart shows discount
  CART=$(curl -s "$BASE/api/cart" -H "Cookie: sessionId=test-session-04")
  HAS_DISCOUNT=$(echo "$CART" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Look for discount, discountAmount, coupon, or appliedCoupon
    found = False
    for key in ['discount', 'discountAmount', 'coupon', 'appliedCoupon']:
        if key in d and d[key]:
            found = True; break
    print('yes' if found else 'no')
except:
    print('no')
" 2>/dev/null)
  check "Cart shows applied discount" '[ "$HAS_DISCOUNT" = "yes" ]'
else
  echo "SKIP: No coupon code found — testing with invalid code only"
  check "POST /api/cart/coupon applies valid coupon (200)" 'false'
  check "Cart shows applied discount" 'false'
fi

# Test: Invalid coupon returns 400
INVALID_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/cart/coupon" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-04" \
  -d '{"code":"INVALID_NONEXISTENT_CODE_12345"}')
check "Invalid coupon returns 400" '[ "$INVALID_STATUS" = "400" ]'

# --- Regression checks: Cart UI (from C02) ---
# C04 modifies the cart page to add coupon input. Verify earlier UI fixes survived.

CONFIRM_FOUND=$(find . -path ./node_modules -prune -o -name '*.tsx' -print -o -name '*.ts' -print -o -name '*.jsx' -print -o -name '*.js' -print 2>/dev/null \
  | xargs grep -l 'confirm(' 2>/dev/null \
  | xargs grep -l 'cart\|Cart' 2>/dev/null \
  | head -1)
check "REGRESSION: No confirm() in cart code" '[ -z "$CONFIRM_FOUND" ]'

EMPTY_CART_HTML=$(curl -s "$BASE/cart" -H "Cookie: sessionId=test-session-04-empty")
check "REGRESSION: Empty cart still has /products link" 'echo "$EMPTY_CART_HTML" | grep -qi "href=.*/products"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
