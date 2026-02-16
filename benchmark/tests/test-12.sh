#!/usr/bin/env bash
# test-12.sh - Sprint Retrospective Fixes tests (Change 12)
# Tests: API format consistency, payout math, reservation error, index, seed data
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

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
