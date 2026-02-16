## ADDED Requirements

### Requirement: Per-change test scripts
Create `benchmark/tests/test-NN.sh` for each change (01-12). Tests use curl against localhost and grep/jq for verification.

Test structure per script:
```bash
#!/usr/bin/env bash
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

# ... checks ...

echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
```

#### Scenario: Test scripts for changes 01-06
- `test-01.sh`: GET /api/products returns 200 with array; GET /api/products/[id] returns product with variants array; POST /api/products creates product
- `test-02.sh`: POST /api/cart/items adds item; GET /api/cart returns items with totals; DELETE /api/cart/items/[id] removes item and restores stock
- `test-03.sh`: GET /api/vendors returns vendors; POST /api/orders creates order with sub-orders grouped by vendor
- `test-04.sh`: POST /api/cart/coupon validates and applies coupon; GET /api/cart shows discount breakdown; invalid coupon returns 400
- `test-05.sh`: POST /api/checkout creates payment intent; POST /api/checkout/confirm creates order with payment and payouts
- `test-06.sh`: PUT /api/sub-orders/[id]/status with valid transition returns 200; invalid transition returns 400; GET /api/orders/[id] shows derived status

#### Scenario: Test scripts for revision changes 07-09
- `test-07.sh`: POST /api/cart/items does NOT change Variant.stockQuantity; checkout DOES change it; expired reservation returns error
- `test-08.sh`: npx prisma validate passes; GET /api/products/[id] returns images as `[{url, altText, sortOrder}]`; Product model has no images column
- `test-09.sh`: All money fields in schema.prisma are Int type; test order payout sum equals payment amount exactly

#### Scenario: Test scripts for feedback changes 10-11
- `test-10.sh`: Cart page source has no confirm() calls; no submit button with text matching "update"; empty cart page has link to /products
- `test-11.sh`: Vendor dashboard has no tab/panel components; has pagination controls; has badge CSS classes

#### Scenario: Test script for sprint retro 12
- `test-12.sh`: All list endpoints return `{data:[...], total:N}`; 3-vendor payout sum == payment; expired reservation checkout returns 400; SubOrder has @@index on vendorId; seed script uses consistent cents

---

### Requirement: CLAUDE.md test integration
Update CLAUDE.md templates to instruct the agent:
1. Start dev server before running tests: `npm run dev &`
2. After each /opsx:apply, run `bash tests/test-NN.sh $PORT`
3. If test fails, fix the issues and re-run until pass
4. Do NOT commit until tests pass

#### Scenario: Agent runs tests and iterates
- **WHEN** agent completes C04 implementation
- **THEN** runs `bash tests/test-04.sh 3000`, sees failures, fixes them, re-runs until pass, then commits
