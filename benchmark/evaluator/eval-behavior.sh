#!/usr/bin/env bash
# eval-behavior.sh - Evaluate behavioral correctness
# Checks: stock logic placement, checkout transactionality, payout formula
#
# Usage: ./eval-behavior.sh <project-dir>
# Output: JSON object with check results

set -euo pipefail

PROJECT_DIR="${1:-.}"

python3 -c "
import json, os, re, glob

results = {}
project = '$PROJECT_DIR'

# Find all source files
src_files = []
for ext in ['ts', 'tsx', 'js', 'jsx']:
    src_files.extend(glob.glob(os.path.join(project, 'src', '**', f'*.{ext}'), recursive=True))
    src_files.extend(glob.glob(os.path.join(project, 'app', '**', f'*.{ext}'), recursive=True))

def read_all_src():
    content = {}
    for f in src_files:
        try:
            with open(f) as fh:
                content[f] = fh.read()
        except:
            pass
    return content

all_src = read_all_src()

# --- Check 1: Stock decrement is in checkout, NOT in cart add ---
stock_in_cart = False
stock_in_checkout = False

for path, content in all_src.items():
    lower_path = path.lower()
    # Check cart routes for stock decrement
    if 'cart' in lower_path and ('route' in lower_path or 'api' in lower_path):
        if re.search(r'stockQuantity.*-=|decrement.*stock|stock.*decrement|update.*stockQuantity', content):
            stock_in_cart = True
    # Check checkout routes for stock decrement
    if 'checkout' in lower_path and ('route' in lower_path or 'api' in lower_path):
        if re.search(r'stockQuantity|decrement.*stock|stock.*decrement', content):
            stock_in_checkout = True

results['stock_not_in_cart'] = not stock_in_cart
results['stock_in_checkout'] = stock_in_checkout

# --- Check 2: Checkout uses transaction ---
checkout_transactional = False
for path, content in all_src.items():
    if 'checkout' in path.lower():
        if re.search(r'\\\$transaction|\\.transaction\(', content):
            checkout_transactional = True

results['checkout_transactional'] = checkout_transactional

# --- Check 3: Payout uses integer arithmetic (no parseFloat, no toFixed for money) ---
payout_uses_float = False
for path, content in all_src.items():
    if 'checkout' in path.lower() or 'payout' in path.lower():
        # Look for float operations on money
        if re.search(r'parseFloat.*(?:amount|price|fee|payout|gross|net)', content):
            payout_uses_float = True
        if re.search(r'\.toFixed\(\d\).*(?:amount|price|fee|payout)', content):
            payout_uses_float = True

results['payout_integer_arithmetic'] = not payout_uses_float

# --- Check 4: Largest-remainder method for payout splitting ---
has_largest_remainder = False
for path, content in all_src.items():
    if re.search(r'largest.?remainder|remainder.*sort|floor.*remainder|Math\.floor.*split', content, re.IGNORECASE):
        has_largest_remainder = True

results['largest_remainder_payout'] = has_largest_remainder

# --- Check 5: No confirm() in cart page components ---
cart_has_confirm = False
for path, content in all_src.items():
    if 'cart' in path.lower() and ('page' in path.lower() or 'component' in path.lower()):
        if re.search(r'(?:window\.)?confirm\s*\(', content):
            cart_has_confirm = True

results['cart_no_confirm_dialog'] = not cart_has_confirm

# --- Check 6: No tabs in vendor dashboard ---
dashboard_has_tabs = False
for path, content in all_src.items():
    if 'vendor' in path.lower() and ('dashboard' in path.lower()):
        if re.search(r'Tab|TabPanel|TabList|role=[\"\\']tab', content, re.IGNORECASE):
            dashboard_has_tabs = True

results['dashboard_no_tabs'] = not dashboard_has_tabs

# --- Summary ---
total = sum(1 for v in results.values() if isinstance(v, bool))
passed = sum(1 for v in results.values() if v is True)
results['summary'] = {'total': total, 'passed': passed, 'failed': total - passed}

print(json.dumps(results, indent=2))
"
