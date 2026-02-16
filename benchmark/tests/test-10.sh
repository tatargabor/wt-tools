#!/usr/bin/env bash
# test-10.sh - Cart Page UX Correction tests (Change 10)
# Tests: no confirm() calls, no Update button, empty cart has /products link
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

echo "=== Test 10: Cart Page UX Correction ==="
echo "Target: $BASE"
echo ""

# Fetch cart page HTML
CART_HTML=$(curl -s "$BASE/cart")

if [ -z "$CART_HTML" ]; then
  echo "SKIP: Cannot fetch cart page at /cart"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# Test: No confirm() calls in cart page source
# Check for window.confirm, confirm(, or onClick handlers with confirm
HAS_CONFIRM=$(echo "$CART_HTML" | grep -ci "confirm(" 2>/dev/null)
check "No confirm() calls in cart page" '[ "${HAS_CONFIRM:-0}" -eq 0 ]'

if [ "${HAS_CONFIRM:-0}" -gt 0 ]; then
  echo "  Detail: Found $HAS_CONFIRM occurrences of confirm() in cart page source"
fi

# Test: No submit button with text matching "update" (case-insensitive)
# Look for buttons/inputs with "update" in text, value, or nearby content
HAS_UPDATE_BTN=$(echo "$CART_HTML" | python3 -c "
import sys, re
html = sys.stdin.read().lower()
# Look for various patterns that indicate an 'Update cart' button
patterns = [
    r'<button[^>]*>.*?update.*?</button>',
    r'<input[^>]*value=[\"\\'].*?update.*?[\"\\'][^>]*type=[\"\\']submit[\"\\']',
    r'<input[^>]*type=[\"\\']submit[\"\\'][^>]*value=[\"\\'].*?update.*?[\"\\']',
    r'<button[^>]*type=[\"\\']submit[\"\\'][^>]*>.*?update.*?</button>',
]
found = 0
for p in patterns:
    found += len(re.findall(p, html, re.DOTALL))
print(found)
" 2>/dev/null)
check "No submit button with text matching 'update'" '[ "${HAS_UPDATE_BTN:-1}" -eq 0 ]'

if [ "${HAS_UPDATE_BTN:-0}" -gt 0 ]; then
  echo "  Detail: Found $HAS_UPDATE_BTN 'Update' button(s) in cart page source"
fi

# Test: Empty cart page has link to /products
# Clear cart first, then check empty cart page
curl -s -X DELETE "$BASE/api/cart" -H "Cookie: sessionId=test-session-10-empty" > /dev/null 2>&1
EMPTY_CART_HTML=$(curl -s "$BASE/cart" -H "Cookie: sessionId=test-session-10-empty")

HAS_PRODUCTS_LINK=$(echo "$EMPTY_CART_HTML" | python3 -c "
import sys, re
html = sys.stdin.read()
# Look for a link to /products
patterns = [
    r'href=[\"\\'][^\"\\']*/products[\"\\']',
    r'href=[\"\\']\/products[\"\\']',
    r'href=[\"\\'].*products.*[\"\\']',
]
for p in patterns:
    if re.search(p, html, re.IGNORECASE):
        print('yes')
        break
else:
    print('no')
" 2>/dev/null)
check "Empty cart has link to /products" '[ "$HAS_PRODUCTS_LINK" = "yes" ]'

# --- TRAP-L: Responsive convention preservation checks ---

CART_PAGE=$(find src/app/cart -name "page.tsx" -o -name "page.jsx" 2>/dev/null | head -1)
if [ -n "$CART_PAGE" ]; then
  HAS_CONTAINER=$(grep -c "ResponsiveContainer" "$CART_PAGE" 2>/dev/null || echo 0)
  check "TRAP-L: Redesigned cart page still imports ResponsiveContainer" '[ "$HAS_CONTAINER" -gt 0 ]'
else
  check "TRAP-L: Redesigned cart page still imports ResponsiveContainer" 'false'
fi

if [ -f tailwind.config.ts ]; then
  HAS_480=$(grep -c "480" tailwind.config.ts 2>/dev/null || echo 0)
  check "TRAP-L: tailwind.config.ts still has custom sm:480px" '[ "$HAS_480" -gt 0 ]'
else
  check "TRAP-L: tailwind.config.ts still has custom sm:480px" 'false'
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-10.json << RESULT
{
  "change": "cart-ux-correction",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-10.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
