#!/usr/bin/env bash
# test-09.sh - Integer Cents tests (Change 09)
# Tests: all money fields are Int, payout math is exact
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

echo "=== Test 09: Integer Cents ==="
echo "Target: $BASE"
echo ""

# Test: All money fields in schema.prisma are Int type
SCHEMA_FILE=""
for f in prisma/schema.prisma schema.prisma; do
  if [ -f "$f" ]; then
    SCHEMA_FILE="$f"
    break
  fi
done

if [ -n "$SCHEMA_FILE" ]; then
  # Check known money fields are Int (not Decimal, Float, or String)
  MONEY_FIELDS_OK=$(python3 -c "
import re

money_field_names = [
    'basePrice', 'price', 'value', 'minOrderValue',
    'totalAmount', 'subtotal', 'unitPrice', 'amount',
    'grossAmount', 'platformFee', 'netAmount'
]

with open('$SCHEMA_FILE') as f:
    content = f.read()

bad_fields = []
for field_name in money_field_names:
    # Find lines that define this field
    pattern = rf'^\s+{field_name}\s+(\w+)'
    for match in re.finditer(pattern, content, re.MULTILINE):
        field_type = match.group(1)
        if field_type in ('Decimal', 'Float', 'String'):
            bad_fields.append(f'{field_name}: {field_type}')

if bad_fields:
    print('FAIL: ' + ', '.join(bad_fields))
else:
    print('OK')
" 2>/dev/null)
  check "All money fields are Int type (not Decimal/Float)" '[ "$MONEY_FIELDS_OK" = "OK" ]'

  if [ "$MONEY_FIELDS_OK" != "OK" ]; then
    echo "  Detail: $MONEY_FIELDS_OK"
  fi
else
  echo "SKIP: Cannot find Prisma schema file"
  check "All money fields are Int type (not Decimal/Float)" 'false'
fi

# Test: Product prices are in cents (integer values > 100 for typical products)
PRICES=$(curl -s "$BASE/api/products" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    cents_count = 0
    dollar_count = 0
    for p in items:
        bp = p.get('basePrice', 0)
        if isinstance(bp, (int, float)) and bp > 100:
            cents_count += 1
        elif isinstance(bp, (int, float)) and bp > 0:
            dollar_count += 1
        for v in p.get('variants', []):
            vp = v.get('price', 0)
            if isinstance(vp, (int, float)) and vp > 100:
                cents_count += 1
            elif isinstance(vp, (int, float)) and vp > 0:
                dollar_count += 1
    if cents_count > 0 and dollar_count == 0:
        print('cents')
    elif dollar_count > 0 and cents_count == 0:
        print('dollars')
    else:
        print('mixed')
except:
    print('unknown')
" 2>/dev/null)
check "API returns prices in cents (not dollars)" '[ "$PRICES" = "cents" ]'

# Test: Order payout sum equals payment amount exactly
# Create a test order and check payout math
# This is an integrity check — if we can get order details with payouts
ORDERS=$(curl -s "$BASE/api/orders" -H "Cookie: sessionId=test-session-05")
PAYOUT_CHECK=$(echo "$ORDERS" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('orders', []))
    if not items:
        print('no_orders')
        sys.exit(0)

    # Check first order that has payouts
    for o in items:
        payouts = o.get('payouts', o.get('vendorPayouts', []))
        payment = o.get('payment', {})
        total = o.get('totalAmount', 0)

        if payouts:
            payout_sum = sum(p.get('netAmount', 0) + p.get('platformFee', 0) for p in payouts)
            payment_amount = payment.get('amount', total)
            if payout_sum == payment_amount:
                print('exact')
            else:
                print(f'mismatch: payouts={payout_sum} payment={payment_amount}')
            break
    else:
        print('no_payouts')
except:
    print('error')
" 2>/dev/null)

case "$PAYOUT_CHECK" in
  exact)
    check "Payout sum equals payment amount exactly" 'true'
    ;;
  no_orders|no_payouts)
    echo "SKIP: No orders with payouts found — run checkout first"
    check "Payout sum equals payment amount exactly" 'false'
    ;;
  *)
    echo "  Detail: $PAYOUT_CHECK"
    check "Payout sum equals payment amount exactly" 'false'
    ;;
esac

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
