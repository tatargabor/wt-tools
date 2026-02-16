#!/usr/bin/env bash
# test-01.sh - Product Catalog tests (Change 01)
# Tests: product CRUD, variant operations, seed data
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

echo "=== Test 01: Product Catalog ==="
echo "Target: $BASE"
echo ""

# Test: GET /api/products returns 200
RESP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/products")
check "GET /api/products returns 200" '[ "$RESP" = "200" ]'

# Test: GET /api/products returns a JSON array or object with products
BODY=$(curl -s "$BASE/api/products")
HAS_PRODUCTS=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    # Accept: array, {data:[...]}, {products:[...]}
    if isinstance(d, list):
        print('yes' if len(d) > 0 else 'no')
    elif isinstance(d, dict):
        for key in ['data', 'products']:
            if key in d and isinstance(d[key], list) and len(d[key]) > 0:
                print('yes'); break
        else:
            print('no')
    else:
        print('no')
except:
    print('no')
" 2>/dev/null)
check "GET /api/products returns non-empty product list" '[ "$HAS_PRODUCTS" = "yes" ]'

# Test: GET /api/products/[id] returns a product with variants
FIRST_ID=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    print(items[0]['id'] if items else '')
except:
    print('')
" 2>/dev/null)

if [ -n "$FIRST_ID" ]; then
  PRODUCT=$(curl -s "$BASE/api/products/$FIRST_ID")
  HAS_VARIANTS=$(echo "$PRODUCT" | python3 -c "
import sys, json
try:
    p = json.load(sys.stdin)
    # Accept product directly or wrapped in {data: ...}
    if 'data' in p: p = p['data']
    variants = p.get('variants', [])
    print('yes' if len(variants) > 0 else 'no')
except:
    print('no')
" 2>/dev/null)
  check "GET /api/products/[id] returns product with variants" '[ "$HAS_VARIANTS" = "yes" ]'
else
  check "GET /api/products/[id] returns product with variants" 'false'
fi

# Test: POST /api/products creates a product
CREATE_RESP=$(curl -s -X POST "$BASE/api/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","description":"A test","basePrice":1999}')
CREATED_ID=$(echo "$CREATE_RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'data' in d: d = d['data']
    print(d.get('id', ''))
except:
    print('')
" 2>/dev/null)
check "POST /api/products creates a product" '[ -n "$CREATED_ID" ]'

# Test: Seed data has at least 3 products
PRODUCT_COUNT=$(echo "$BODY" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('products', []))
    print(len(items))
except:
    print(0)
" 2>/dev/null)
check "Seed data has at least 3 products" '[ "$PRODUCT_COUNT" -ge 3 ]'

# --- TRAP-L: Responsive convention checks ---

# Test: tailwind.config.ts has custom sm:480px breakpoint
if [ -f tailwind.config.ts ]; then
  HAS_480=$(grep -c "480" tailwind.config.ts 2>/dev/null || echo 0)
  check "TRAP-L: tailwind.config.ts has custom sm:480px breakpoint" '[ "$HAS_480" -gt 0 ]'
else
  check "TRAP-L: tailwind.config.ts has custom sm:480px breakpoint" 'false'
fi

# Test: ResponsiveContainer component exists
check "TRAP-L: ResponsiveContainer.tsx exists" '[ -f src/components/ResponsiveContainer.tsx ]'

# Test: Products page imports ResponsiveContainer
PRODUCTS_PAGE=$(find src/app/products -name "page.tsx" -o -name "page.jsx" 2>/dev/null | head -1)
if [ -n "$PRODUCTS_PAGE" ]; then
  HAS_CONTAINER=$(grep -c "ResponsiveContainer" "$PRODUCTS_PAGE" 2>/dev/null || echo 0)
  check "TRAP-L: Products page imports ResponsiveContainer" '[ "$HAS_CONTAINER" -gt 0 ]'
else
  check "TRAP-L: Products page imports ResponsiveContainer" 'false'
fi

# Test: No xl: or 2xl: classes in src/
XL_COUNT=$(grep -r "xl:" src/ --include="*.tsx" --include="*.jsx" --include="*.ts" 2>/dev/null | grep -v node_modules | grep -cE "\bxl:" || echo 0)
check "TRAP-L: No xl: or 2xl: Tailwind classes in src/" '[ "$XL_COUNT" -eq 0 ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-01.json << RESULT
{
  "change": "product-catalog",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-01.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
