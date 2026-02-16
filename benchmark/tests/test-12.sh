#!/usr/bin/env bash
# test-12.sh - Sprint Retrospective Fixes tests (Change 12)
# Tests: API format consistency, payout math, reservation error, index, seed data
PORT="${1:-4000}"
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

echo "=== Test 12: Sprint Retrospective Fixes ==="
echo "Target: $BASE"
echo ""

# --- Bug 1: All list endpoints return { data: [...], total: N } ---
ENDPOINTS=("/api/products" "/api/vendors" "/api/orders")
ALL_CONSISTENT=true
for ep in "${ENDPOINTS[@]}"; do
  RESP=$(curl -s "$BASE$ep" -H "Cookie: sessionId=test-session-12")
  FORMAT_OK=$(echo "$RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if isinstance(d, dict) and 'data' in d and isinstance(d['data'], list) and 'total' in d:
        print('yes')
    else:
        print('no')
except:
    print('error')
" 2>/dev/null)
  if [ "$FORMAT_OK" != "yes" ]; then
    ALL_CONSISTENT=false
    echo "  Detail: $ep does not return {data:[...], total:N}"
  fi
done
check "All list endpoints return {data:[...], total:N}" '$ALL_CONSISTENT'

# --- Bug 2: 3-vendor payout sum == payment amount ---
# Check existing orders for payout accuracy
PAYOUT_OK=$(curl -s "$BASE/api/orders" -H "Cookie: sessionId=test-session-12" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('data', d) if isinstance(d, dict) else d
    if not isinstance(items, list):
        items = []

    checked = False
    for o in items:
        payouts = o.get('payouts', o.get('vendorPayouts', []))
        payment = o.get('payment', {})
        total = o.get('totalAmount', 0)

        if payouts and len(payouts) >= 2:
            payout_sum = sum(p.get('netAmount', 0) + p.get('platformFee', 0) for p in payouts)
            payment_amount = payment.get('amount', total)
            if payout_sum != payment_amount:
                print(f'mismatch: sum={payout_sum} payment={payment_amount}')
                sys.exit(0)
            checked = True

    if checked:
        print('exact')
    else:
        print('no_multi_vendor_orders')
except:
    print('error')
" 2>/dev/null)

case "$PAYOUT_OK" in
  exact)
    check "Payout sum equals payment amount (no rounding drift)" 'true'
    ;;
  no_multi_vendor_orders)
    echo "  Note: No multi-vendor orders found — create one for full verification"
    check "Payout sum equals payment amount (no rounding drift)" 'true'  # Pass if no data to verify
    ;;
  *)
    echo "  Detail: $PAYOUT_OK"
    check "Payout sum equals payment amount (no rounding drift)" 'false'
    ;;
esac

# --- Bug 3: Expired reservation checkout returns 400 (not 500) ---
# Attempt checkout with no valid cart/reservation
EXPIRED_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/checkout/confirm" \
  -H "Content-Type: application/json" \
  -H "Cookie: sessionId=test-session-12-expired" \
  -d '{"paymentIntentId":"pi_test_expired_reservation"}')
# Should be 400 (bad request) not 500 (server error)
check "Expired/invalid checkout returns 400 (not 500)" '[ "$EXPIRED_STATUS" = "400" ]'

# --- Bug 4: SubOrder has @@index on vendorId ---
SCHEMA_FILE=""
for f in prisma/schema.prisma schema.prisma; do
  if [ -f "$f" ]; then
    SCHEMA_FILE="$f"
    break
  fi
done

if [ -n "$SCHEMA_FILE" ]; then
  HAS_INDEX=$(python3 -c "
import re
with open('$SCHEMA_FILE') as f:
    content = f.read()
# Find SubOrder model block
match = re.search(r'model SubOrder \{(.*?)\}', content, re.DOTALL)
if match:
    block = match.group(1)
    if '@@index' in block and 'vendorId' in block:
        # Check that @@index contains vendorId
        index_lines = [l for l in block.split('\n') if '@@index' in l and 'vendorId' in l]
        print('yes' if index_lines else 'no')
    else:
        print('no')
else:
    print('no_model')
" 2>/dev/null)
  check "SubOrder has @@index([vendorId])" '[ "$HAS_INDEX" = "yes" ]'
else
  echo "SKIP: Cannot find Prisma schema file"
  check "SubOrder has @@index([vendorId])" 'false'
fi

# --- Bug 5: Seed data uses cents consistently ---
# Check that product prices and coupon values are in cents (integers > 100 for typical values)
SEED_CHECK=$(curl -s "$BASE/api/products" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('data', d) if isinstance(d, dict) else d
    if not isinstance(items, list):
        items = []

    dollar_count = 0
    cents_count = 0
    for p in items:
        bp = p.get('basePrice', 0)
        if isinstance(bp, (int, float)):
            if bp < 100 and bp > 0:
                dollar_count += 1
            elif bp >= 100:
                cents_count += 1
        for v in p.get('variants', []):
            vp = v.get('price', 0)
            if isinstance(vp, (int, float)):
                if vp < 100 and vp > 0:
                    dollar_count += 1
                elif vp >= 100:
                    cents_count += 1

    if dollar_count > 0:
        print(f'mixed: {dollar_count} dollar values, {cents_count} cent values')
    elif cents_count > 0:
        print('consistent')
    else:
        print('no_data')
except:
    print('error')
" 2>/dev/null)

case "$SEED_CHECK" in
  consistent)
    check "Seed data uses cents consistently (no dollar/cent mixing)" 'true'
    ;;
  no_data)
    echo "  Note: No product data to verify"
    check "Seed data uses cents consistently (no dollar/cent mixing)" 'false'
    ;;
  *)
    echo "  Detail: $SEED_CHECK"
    check "Seed data uses cents consistently (no dollar/cent mixing)" 'false'
    ;;
esac

# --- Regression checks: ALL prior UI fixes must survive sprint retro ---
# C12 touches many parts of the codebase. Verify nothing regressed.

# Cart UI (from C02, verified in C04/C07/C10)
CONFIRM_FOUND=$(find . -path ./node_modules -prune -o -name '*.tsx' -print -o -name '*.ts' -print -o -name '*.jsx' -print -o -name '*.js' -print 2>/dev/null \
  | xargs grep -l 'confirm(' 2>/dev/null \
  | xargs grep -l 'cart\|Cart' 2>/dev/null \
  | head -1)
check "REGRESSION: No confirm() in cart code" '[ -z "$CONFIRM_FOUND" ]'

EMPTY_CART_HTML=$(curl -s "$BASE/cart" -H "Cookie: sessionId=test-session-12-empty")
check "REGRESSION: Empty cart has /products link" 'echo "$EMPTY_CART_HTML" | grep -qi "href=.*/products"'

# Product display (from C01/C03/C08)
PRODUCT_PAGE=$(curl -s "$BASE/products")
check "REGRESSION: /products page renders" 'echo "$PRODUCT_PAGE" | grep -qi "product\|catalog\|shop"'

# Vendor dashboard (from C06/C11) — no tabs
VENDOR_DASH_ID=$(curl -s "$BASE/api/vendors" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('data', d) if isinstance(d, dict) else d
    if isinstance(items, list) and items:
        print(items[0]['id'])
    else:
        print('')
except:
    print('')
" 2>/dev/null)
if [ -n "$VENDOR_DASH_ID" ]; then
  DASH_HTML=$(curl -s "$BASE/vendor/$VENDOR_DASH_ID/dashboard")
  check "REGRESSION: Vendor dashboard has no tabs" '! echo "$DASH_HTML" | grep -qiE "<tab|role=.tab|TabPanel|TabList"'
  check "REGRESSION: Vendor dashboard has badges" 'echo "$DASH_HTML" | grep -qi "badge"'
fi

# --- Bug 10: TRAP-L — Responsive convention (all pages use ResponsiveContainer) ---
if [ -f tailwind.config.ts ]; then
  HAS_480=$(grep -c "480" tailwind.config.ts 2>/dev/null || echo 0)
  check "TRAP-L: tailwind.config.ts has custom sm:480px" '[ "$HAS_480" -gt 0 ]'
else
  check "TRAP-L: tailwind.config.ts has custom sm:480px" 'false'
fi

check "TRAP-L: ResponsiveContainer.tsx exists" '[ -f src/components/ResponsiveContainer.tsx ]'

# Check all main pages for ResponsiveContainer import
for PAGE_DIR in products cart checkout vendor orders; do
  PAGE_FILE=$(find "src/app/$PAGE_DIR" -name "page.tsx" -o -name "page.jsx" 2>/dev/null | head -1)
  if [ -n "$PAGE_FILE" ]; then
    HAS_RC=$(grep -c "ResponsiveContainer" "$PAGE_FILE" 2>/dev/null || echo 0)
    check "TRAP-L: /$PAGE_DIR page uses ResponsiveContainer" '[ "$HAS_RC" -gt 0 ]'
  fi
done

XL_COUNT=$(grep -r "xl:" src/ --include="*.tsx" --include="*.jsx" --include="*.ts" 2>/dev/null | grep -v node_modules | grep -cE "\bxl:" || echo 0)
check "TRAP-L: No xl:/2xl: Tailwind classes in src/" '[ "$XL_COUNT" -eq 0 ]'

# --- Bug 11: TRAP-M — Shared Pagination component ---
check "TRAP-M: src/components/Pagination.tsx exists" '[ -f src/components/Pagination.tsx ]'

# Check list pages import the shared Pagination component
PAGINATION_IMPORTS=0
for PAGE_DIR in products vendors orders vendor; do
  PAGE_FILES=$(find "src/app/$PAGE_DIR" -name "page.tsx" -o -name "page.jsx" 2>/dev/null)
  for PF in $PAGE_FILES; do
    if grep -q "Pagination" "$PF" 2>/dev/null; then
      ((PAGINATION_IMPORTS++))
    fi
  done
done
check "TRAP-M: At least 3 pages import Pagination component" '[ "$PAGINATION_IMPORTS" -ge 3 ]'

# --- Bug 12: TRAP-N — Shared Toast/notification system ---
check "TRAP-N: src/components/Toast.tsx exists" '[ -f src/components/Toast.tsx ]'

# No window.alert() calls in src/
ALERT_COUNT=$(grep -r "window\.alert\b\|window\.confirm\b" src/ --include="*.tsx" --include="*.jsx" --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | wc -l)
check "TRAP-N: No window.alert() or window.confirm() in src/" '[ "$ALERT_COUNT" -eq 0 ]'

# Check at least 3 files import Toast
TOAST_IMPORTS=$(grep -rl "Toast" src/ --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v "Toast.tsx" | wc -l)
check "TRAP-N: At least 3 files import Toast component" '[ "$TOAST_IMPORTS" -ge 3 ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-12.json << RESULT
{
  "change": "sprint-retro",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-12.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
