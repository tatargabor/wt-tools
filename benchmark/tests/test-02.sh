#!/usr/bin/env bash
# test-02.sh - Shopping Cart tests (Change 02)
# Tests: cart CRUD, stock tracking, totals
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

echo "=== Test 02: Shopping Cart ==="
echo "Target: $BASE"
echo ""

# Get a variant ID from products
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
  echo "SKIP: No variant found — cannot test cart operations"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# Test: POST /api/cart/items adds an item
ADD_RESP=$(curl -s -X POST "$BASE/api/cart/items" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-02" \
  -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":1}")
ADD_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/cart/items" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-02b" \
  -d "{\"variantId\":\"$VARIANT_ID\",\"quantity\":1}")
check "POST /api/cart/items returns 200 or 201" '[ "$ADD_STATUS" = "200" ] || [ "$ADD_STATUS" = "201" ]'

# Test: GET /api/cart returns items
CART=$(curl -s "$BASE/api/cart" -H "Cookie: sessionId=test-session-02b")
HAS_ITEMS=$(echo "$CART" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('items', d.get('cartItems', d.get('data', [])))
    if isinstance(items, list) and len(items) > 0:
        print('yes')
    else:
        print('no')
except:
    print('no')
" 2>/dev/null)
check "GET /api/cart returns cart with items" '[ "$HAS_ITEMS" = "yes" ]'

# Test: Cart has totals
HAS_TOTAL=$(echo "$CART" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Look for total, cartTotal, totalAmount, or similar
    for key in ['total', 'cartTotal', 'totalAmount', 'subtotal']:
        if key in d:
            print('yes'); break
    else:
        print('no')
except:
    print('no')
" 2>/dev/null)
check "GET /api/cart includes total" '[ "$HAS_TOTAL" = "yes" ]'

# Test: DELETE /api/cart/items/[id] removes item
ITEM_ID=$(echo "$CART" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('items', d.get('cartItems', d.get('data', [])))
    print(items[0]['id'] if items else '')
except:
    print('')
" 2>/dev/null)

if [ -n "$ITEM_ID" ]; then
  DEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/api/cart/items/$ITEM_ID" \
    -H "Cookie: sessionId=test-session-02b")
  check "DELETE /api/cart/items/[id] returns 200" '[ "$DEL_STATUS" = "200" ]'
else
  check "DELETE /api/cart/items/[id] returns 200" 'false'
fi

# --- UI pattern checks (these establish baseline expectations) ---
# These checks verify cart page UX patterns that must be preserved in later changes.

# Check: No confirm() dialog in cart source (agents often add this by default)
CONFIRM_FOUND=$(find . -path ./node_modules -prune -o -name '*.tsx' -print -o -name '*.ts' -print -o -name '*.jsx' -print -o -name '*.js' -print 2>/dev/null \
  | xargs grep -l 'confirm(' 2>/dev/null \
  | xargs grep -l 'cart\|Cart' 2>/dev/null \
  | head -1)
check "No confirm() dialog in cart code" '[ -z "$CONFIRM_FOUND" ]'

# Check: Empty cart has a link to /products
EMPTY_CART_HTML=$(curl -s "$BASE/cart" -H "Cookie: sessionId=test-session-02-empty")
check "Empty cart has link to /products" 'echo "$EMPTY_CART_HTML" | grep -qi "href=.*/products"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
