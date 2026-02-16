#!/usr/bin/env bash
# eval-schema.sh - Evaluate Prisma schema correctness
# Checks: Image table, Int money fields, CartReservation, Variant table, indexes
#
# Usage: ./eval-schema.sh <project-dir>
# Output: JSON object with check results

set -euo pipefail

PROJECT_DIR="${1:-.}"
SCHEMA_FILE=""

for f in "$PROJECT_DIR/prisma/schema.prisma" "$PROJECT_DIR/schema.prisma"; do
  if [ -f "$f" ]; then
    SCHEMA_FILE="$f"
    break
  fi
done

if [ -z "$SCHEMA_FILE" ]; then
  echo '{"error": "schema.prisma not found", "checks": {}}'
  exit 1
fi

python3 -c "
import re, json, sys

with open('$SCHEMA_FILE') as f:
    content = f.read()

results = {}

# --- Check 1: Variant is a separate table (not JSON on Product) ---
has_variant_model = bool(re.search(r'model Variant \{', content))
results['variant_separate_table'] = has_variant_model

# --- Check 2: Image is a separate table ---
has_image_model = bool(re.search(r'model Image \{', content))
results['image_table_exists'] = has_image_model

# Check Product has no JSON images field
product_match = re.search(r'model Product \{(.*?)\}', content, re.DOTALL)
product_has_json_images = False
if product_match:
    block = product_match.group(1)
    for line in block.split('\n'):
        stripped = line.strip()
        if stripped.startswith('images') and ('String' in stripped or 'Json' in stripped):
            product_has_json_images = True
results['product_no_json_images'] = not product_has_json_images

# --- Check 3: CartReservation model exists ---
has_reservation = bool(re.search(r'model CartReservation \{', content))
results['cart_reservation_exists'] = has_reservation

# --- Check 4: All money fields are Int ---
money_field_names = [
    'basePrice', 'price', 'value', 'minOrderValue',
    'totalAmount', 'subtotal', 'unitPrice', 'amount',
    'grossAmount', 'platformFee', 'netAmount'
]

money_fields_status = {}
for field_name in money_field_names:
    pattern = rf'^\s+{field_name}\s+(\w+)'
    matches = re.findall(pattern, content, re.MULTILINE)
    if matches:
        for field_type in matches:
            if field_type in ('Decimal', 'Float', 'String'):
                money_fields_status[field_name] = f'FAIL: {field_type}'
            else:
                money_fields_status[field_name] = f'OK: {field_type}'

results['money_fields'] = money_fields_status
results['all_money_int'] = all('FAIL' not in v for v in money_fields_status.values())

# --- Check 5: SubOrder has @@index on vendorId ---
suborder_match = re.search(r'model SubOrder \{(.*?)\}', content, re.DOTALL)
has_vendor_index = False
if suborder_match:
    block = suborder_match.group(1)
    index_lines = [l for l in block.split('\n') if '@@index' in l and 'vendorId' in l]
    has_vendor_index = len(index_lines) > 0
results['suborder_vendor_index'] = has_vendor_index

# --- Check 6: CartReservation has expiresAt field ---
reservation_match = re.search(r'model CartReservation \{(.*?)\}', content, re.DOTALL)
has_expires = False
if reservation_match:
    block = reservation_match.group(1)
    has_expires = 'expiresAt' in block
results['reservation_has_expiry'] = has_expires

# --- Summary ---
total = sum(1 for v in results.values() if isinstance(v, bool))
passed = sum(1 for v in results.values() if v is True)
results['summary'] = {'total': total, 'passed': passed, 'failed': total - passed}

print(json.dumps(results, indent=2))
"
