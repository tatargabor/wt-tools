#!/usr/bin/env bash
# test-11.sh - Vendor Dashboard Redesign tests (Change 11)
# Tests: no tabs, pagination controls, badge CSS classes
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

echo "=== Test 11: Vendor Dashboard Redesign ==="
echo "Target: $BASE"
echo ""

# Get a vendor ID
VENDOR_ID=$(curl -s "$BASE/api/vendors" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d if isinstance(d, list) else d.get('data', d.get('vendors', []))
    print(items[0]['id'] if items else '')
except:
    print('')
" 2>/dev/null)

if [ -z "$VENDOR_ID" ]; then
  echo "SKIP: No vendor found"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# Fetch vendor dashboard HTML
DASHBOARD_HTML=$(curl -s "$BASE/vendor/$VENDOR_ID/dashboard")

if [ -z "$DASHBOARD_HTML" ]; then
  echo "SKIP: Cannot fetch vendor dashboard"
  echo "Results: $PASS passed, $FAIL failed"
  exit 1
fi

# Test: No tab/panel components
HAS_TABS=$(echo "$DASHBOARD_HTML" | python3 -c "
import sys, re
html = sys.stdin.read().lower()
# Look for tab-related patterns
tab_patterns = [
    r'role=[\"\\']tab[\"\\']',
    r'role=[\"\\']tabpanel[\"\\']',
    r'role=[\"\\']tablist[\"\\']',
    r'class=[\"\\'][^\"\\']*(tab-panel|tabpanel|tab-list|tablist|tab-content|tabcontent)[^\"\\']*(\"|\\')',
    r'<tab[^a-z]',
    r'<tabs[^a-z]',
    r'data-tab',
]
found = 0
for p in tab_patterns:
    found += len(re.findall(p, html))
print(found)
" 2>/dev/null)
check "No tab/panel components in vendor dashboard" '[ "${HAS_TABS:-1}" -eq 0 ]'

if [ "${HAS_TABS:-0}" -gt 0 ]; then
  echo "  Detail: Found $HAS_TABS tab-related elements in dashboard source"
fi

# Test: Pagination controls present
HAS_PAGINATION=$(echo "$DASHBOARD_HTML" | python3 -c "
import sys, re
html = sys.stdin.read().lower()
# Look for pagination-related patterns
patterns = [
    r'class=[\"\\'][^\"\\']*(pagination|paginate)[^\"\\']*(\"|\\')',
    r'aria-label=[\"\\'][^\"\\']*(pagination|page)[^\"\\']*(\"|\\')',
    r'>prev(ious)?<',
    r'>next<',
    r'page\s+\d+\s+(of|/)\s+\d+',
]
for p in patterns:
    if re.search(p, html):
        print('yes'); break
else:
    print('no')
" 2>/dev/null)
check "Pagination controls present" '[ "$HAS_PAGINATION" = "yes" ]'

# Test: Badge CSS classes present
HAS_BADGES=$(echo "$DASHBOARD_HTML" | python3 -c "
import sys, re
html = sys.stdin.read().lower()
# Look for badge-related CSS classes
if re.search(r'class=[\"\\'][^\"\\']*(badge)[^\"\\']*(\"|\\')', html):
    print('yes')
else:
    print('no')
" 2>/dev/null)
check "Status badges with 'badge' CSS class present" '[ "$HAS_BADGES" = "yes" ]'

# --- TRAP-L: Responsive convention preservation checks ---

DASHBOARD_SRC=$(find src/app/vendor -name "page.tsx" -o -name "page.jsx" 2>/dev/null | head -1)
if [ -n "$DASHBOARD_SRC" ]; then
  HAS_CONTAINER=$(grep -c "ResponsiveContainer" "$DASHBOARD_SRC" 2>/dev/null || echo 0)
  check "TRAP-L: Redesigned dashboard still imports ResponsiveContainer" '[ "$HAS_CONTAINER" -gt 0 ]'
else
  check "TRAP-L: Redesigned dashboard still imports ResponsiveContainer" 'false'
fi

# Check no xl: or 2xl: classes introduced
XL_COUNT=$(grep -r "xl:" src/ --include="*.tsx" --include="*.jsx" --include="*.ts" 2>/dev/null | grep -v node_modules | grep -cE "\bxl:" || echo 0)
check "TRAP-L: No xl: or 2xl: Tailwind classes in src/" '[ "$XL_COUNT" -eq 0 ]'

echo ""
echo "Results: $PASS passed, $FAIL failed"

# Write results file on full pass (agent cannot fake this)
if [ $FAIL -eq 0 ]; then
  mkdir -p results
  cat > results/change-11.json << RESULT
{
  "change": "vendor-dashboard-redesign",
  "completed": true,
  "test_pass": $PASS,
  "test_fail": $FAIL
}
RESULT
  echo ">> results/change-11.json written"
fi

exit $((FAIL > 0 ? 1 : 0))
