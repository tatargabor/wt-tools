#!/usr/bin/env bash
# eval-api.sh - Evaluate API response format consistency and money format
# Checks: list endpoint format {data:[...], total:N}, money values in cents
#
# Usage: ./eval-api.sh <port>
# Output: JSON object with check results

set -euo pipefail

PORT="${1:-3000}"
BASE="http://localhost:$PORT"

python3 -c "
import json, urllib.request, sys

results = {}

def fetch(path, cookie='sessionId=eval-session'):
    try:
        req = urllib.request.Request(f'$BASE{path}')
        req.add_header('Cookie', cookie)
        with urllib.request.urlopen(req, timeout=5) as resp:
            return json.loads(resp.read()), resp.status
    except Exception as e:
        return None, str(e)

# --- Check 1: List endpoint format consistency ---
list_endpoints = [
    '/api/products',
    '/api/vendors',
    '/api/orders',
]

endpoint_formats = {}
for ep in list_endpoints:
    data, status = fetch(ep)
    if data is None:
        endpoint_formats[ep] = {'status': 'error', 'detail': str(status)}
    elif isinstance(data, dict) and 'data' in data and isinstance(data['data'], list) and 'total' in data:
        endpoint_formats[ep] = {'status': 'correct', 'format': '{data:[...], total:N}'}
    elif isinstance(data, list):
        endpoint_formats[ep] = {'status': 'wrong', 'format': 'bare array'}
    elif isinstance(data, dict):
        keys = list(data.keys())
        endpoint_formats[ep] = {'status': 'wrong', 'format': f'dict with keys: {keys}'}
    else:
        endpoint_formats[ep] = {'status': 'unknown', 'format': str(type(data))}

results['list_endpoints'] = endpoint_formats
results['all_endpoints_consistent'] = all(
    v.get('status') == 'correct' for v in endpoint_formats.values()
)

# --- Check 2: Money values in cents (integers > 100 for typical products) ---
products_data, _ = fetch('/api/products')
money_format = 'unknown'
if products_data:
    items = products_data.get('data', products_data) if isinstance(products_data, dict) else products_data
    if isinstance(items, list):
        dollar_count = 0
        cents_count = 0
        for p in items:
            bp = p.get('basePrice', 0)
            if isinstance(bp, (int, float)):
                if bp > 100:
                    cents_count += 1
                elif bp > 0:
                    dollar_count += 1
            for v in p.get('variants', []):
                vp = v.get('price', 0)
                if isinstance(vp, (int, float)):
                    if vp > 100:
                        cents_count += 1
                    elif vp > 0:
                        dollar_count += 1

        if cents_count > 0 and dollar_count == 0:
            money_format = 'cents'
        elif dollar_count > 0 and cents_count == 0:
            money_format = 'dollars'
        elif cents_count > 0 and dollar_count > 0:
            money_format = 'mixed'
        else:
            money_format = 'no_data'

results['money_format'] = money_format
results['money_in_cents'] = money_format == 'cents'

# --- Summary ---
checks = {k: v for k, v in results.items() if isinstance(v, bool)}
total = len(checks)
passed = sum(1 for v in checks.values() if v is True)
results['summary'] = {'total': total, 'passed': passed, 'failed': total - passed}

print(json.dumps(results, indent=2))
"
