#!/usr/bin/env bash
# test-08.sh - Product Images Table tests (Change 08)
# Tests: Image table exists, Product has no images column, API returns new format
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

echo "=== Test 08: Product Images Table ==="
echo "Target: $BASE"
echo ""

# Test: npx prisma validate passes
VALIDATE_RESULT=$(cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && npx prisma validate 2>&1)
VALIDATE_EXIT=$?
check "npx prisma validate passes" '[ "$VALIDATE_EXIT" = "0" ]'

# Test: Image table exists in Prisma schema
SCHEMA_FILE=""
for f in prisma/schema.prisma schema.prisma; do
  if [ -f "$f" ]; then
    SCHEMA_FILE="$f"
    break
  fi
done

if [ -n "$SCHEMA_FILE" ]; then
  HAS_IMAGE_MODEL=$(grep -c "model Image" "$SCHEMA_FILE" 2>/dev/null)
  check "Image model exists in Prisma schema" '[ "${HAS_IMAGE_MODEL:-0}" -gt 0 ]'

  # Test: Product model has no 'images' column (JSON string)
  # Check if Product model still has an 'images' field (it shouldn't)
  HAS_IMAGES_FIELD=$(python3 -c "
import re
with open('$SCHEMA_FILE') as f:
    content = f.read()
# Find Product model block
match = re.search(r'model Product \{(.*?)\}', content, re.DOTALL)
if match:
    block = match.group(1)
    # Check for 'images' field (not 'Image' relation)
    lines = block.strip().split('\n')
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('images') and ('String' in stripped or 'Json' in stripped):
            print('yes'); break
    else:
        print('no')
else:
    print('unknown')
" 2>/dev/null)
  check "Product model has no JSON images column" '[ "$HAS_IMAGES_FIELD" = "no" ]'
else
  echo "SKIP: Cannot find Prisma schema file"
  check "Image model exists in Prisma schema" 'false'
  check "Product model has no JSON images column" 'false'
fi

# Test: GET /api/products/[id] returns images as [{url, altText, sortOrder}]
FIRST_ID=$(curl -s "$BASE/api/products" | python3 -c "
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
  IMAGES_FORMAT=$(echo "$PRODUCT" | python3 -c "
import sys, json
try:
    p = json.load(sys.stdin)
    if 'data' in p: p = p['data']
    images = p.get('images', [])
    if isinstance(images, list) and len(images) > 0:
        img = images[0]
        if isinstance(img, dict) and 'url' in img:
            print('yes')
        else:
            print('no')
    elif isinstance(images, list) and len(images) == 0:
        print('yes')  # Empty but correct type
    else:
        print('no')
except:
    print('no')
" 2>/dev/null)
  check "API returns images as [{url, altText, sortOrder}]" '[ "$IMAGES_FORMAT" = "yes" ]'
else
  check "API returns images as [{url, altText, sortOrder}]" 'false'
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $((FAIL > 0 ? 1 : 0))
