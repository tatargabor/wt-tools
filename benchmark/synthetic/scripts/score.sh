#!/bin/bash
# score.sh — MemoryProbe v2 scoring (5-category weighted)
# Usage: ./score.sh <project-dir> [--json]
#        ./score.sh --compare <dir-a> <dir-b>
#
# Categories (14 traps):
#   A (code-readable,       x1): A1 pagination, A2 ID prefix, A3 ok wrapper, A4 date helper
#   B (human override,      x2): B1 dot.notation, B2 result key, B3 order param, B4 removedAt
#   C (debug knowledge,     x3): C1 busy_timeout, C2 nanoid(16), C3 body-parser limit
#   D (architecture,        x2): D1 flat categories, D2 db query layer, D3 no try-catch
#   E (stakeholder,         x3): E1 ISO 8601 dates, E2 bulk max 100, E3 list max 1000

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Parse args ---
JSON_MODE=false
COMPARE_MODE=false
PROJECT=""
COMPARE_A=""
COMPARE_B=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --compare) COMPARE_MODE=true; COMPARE_A="$2"; COMPARE_B="$3"; shift 3 ;;
    *) PROJECT="$1"; shift ;;
  esac
done

# --- Score a single project ---
score_project() {
  local DIR="$1"
  local PORT="${2:-3000}"

  cd "$DIR"

  # Start server if not running
  local STARTED_SERVER=false
  if ! curl -s -o /dev/null "http://localhost:$PORT/events" 2>/dev/null; then
    PORT=$PORT node src/server.js &
    local SERVER_PID=$!
    STARTED_SERVER=true
    sleep 2
  fi

  # Run probe tests and capture output
  local T3_OUT T4_OUT T5_OUT
  T3_OUT=$(bash tests/test-03.sh "$PORT" 2>&1) || true
  T4_OUT=$(bash tests/test-04.sh "$PORT" 2>&1) || true
  T5_OUT=$(bash tests/test-05.sh "$PORT" 2>&1) || true

  # Stop server if we started it
  if $STARTED_SERVER; then
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
  fi

  # Parse probe results from test output
  local ALL_OUT="$T3_OUT
$T4_OUT
$T5_OUT"

  # Extract probe lines (format: "  PASS: A1: ..." or "  FAIL: A1: ...")
  python3 -c "
import json, sys, re

output = sys.stdin.read()

# Category definitions
weights = {'A': 1, 'B': 2, 'C': 3, 'D': 2, 'E': 3}
cat_labels = {
    'A': 'Code-readable',
    'B': 'Human override',
    'C': 'Debug knowledge',
    'D': 'Architecture',
    'E': 'Stakeholder'
}

# Parse PASS/FAIL lines with probe IDs
probes = []
for line in output.split('\n'):
    line = line.strip()
    m = re.match(r'(PASS|FAIL):\s+([A-E]\d):', line)
    if m:
        result = m.group(1)
        probe_id = m.group(2)
        desc = line[m.end():].strip()
        cat = probe_id[0]
        probes.append({
            'id': probe_id,
            'cat': cat,
            'result': result,
            'desc': desc
        })

# Aggregate per-category
cat_pass = {}
cat_total = {}
for cat in weights:
    cat_pass[cat] = 0
    cat_total[cat] = 0

for p in probes:
    cat = p['cat']
    cat_total[cat] += 1
    if p['result'] == 'PASS':
        cat_pass[cat] += 1

# Calculate weighted score
raw = sum(cat_pass[c] * weights[c] for c in weights)
mx = sum(cat_total[c] * weights[c] for c in weights)
pct = round(raw * 100 / mx) if mx > 0 else 0

total_pass = sum(cat_pass.values())
total = sum(cat_total.values())
unweighted_pct = round(total_pass * 100 / total) if total > 0 else 0

result = {
    'score': {'pass': total_pass, 'total': total, 'percent': unweighted_pct},
    'weightedScore': {'raw': raw, 'max': mx, 'percent': pct},
    'categories': {},
    'probes': probes
}

for cat in sorted(weights):
    result['categories'][cat] = {
        'label': cat_labels[cat],
        'weight': weights[cat],
        'pass': cat_pass[cat],
        'total': cat_total[cat]
    }

json_mode = '--json' in sys.argv

if json_mode:
    print(json.dumps(result))
else:
    print()
    print('MemoryProbe v2 Convention Scoring')
    print('=' * 55)
    print(f'Project: {sys.argv[1]}')
    print()

    for cat in sorted(weights):
        label = cat_labels[cat]
        w = weights[cat]
        p = cat_pass[cat]
        t = cat_total[cat]
        pct_c = round(p * 100 / t) if t > 0 else 0
        print(f'  Category {cat} ({label}, x{w}):  {p}/{t}  ({pct_c}%)')

    print()
    print('-' * 55)
    print(f'  Unweighted:  {total_pass}/{total}  ({unweighted_pct}%)')
    print(f'  Weighted:    {raw}/{mx}  ({pct}%)')
    print()

    # Show failed probes
    fails = [p for p in probes if p['result'] == 'FAIL']
    if fails:
        print('Failed probes:')
        for p in fails:
            print(f\"  {p['id']}: {p['desc']}\")
        print()

    # Save to results/
    import os
    os.makedirs('results', exist_ok=True)
    with open('results/score.json', 'w') as f:
        json.dump(result, f, indent=2)
    print('  >> results/score.json saved')
" "$DIR" $([ "$JSON_MODE" = true ] && echo "--json" || echo "") <<< "$ALL_OUT"
}

# --- Comparison mode ---
if $COMPARE_MODE; then
  SCORE_A=$(score_project "$COMPARE_A" 3000 2>/dev/null)
  SCORE_B=$(score_project "$COMPARE_B" 3001 2>/dev/null)

  # If not JSON, re-run with JSON for comparison
  if ! $JSON_MODE; then
    JSON_MODE=true
    SCORE_A=$(cd "$COMPARE_A" && score_project "$(pwd)" 3000 2>/dev/null) || SCORE_A="{}"
    SCORE_B=$(cd "$COMPARE_B" && score_project "$(pwd)" 3001 2>/dev/null) || SCORE_B="{}"
  fi

  python3 -c "
import json, sys

try:
    a = json.loads('''$SCORE_A''')
    b = json.loads('''$SCORE_B''')
except:
    print('Error parsing scores. Run each project individually first.')
    sys.exit(1)

weights = {'A': 1, 'B': 2, 'C': 3, 'D': 2, 'E': 3}
labels = {
    'A': 'Code-readable',
    'B': 'Human override',
    'C': 'Debug knowledge',
    'D': 'Architecture',
    'E': 'Stakeholder'
}

print()
print('MemoryProbe v2 Comparison')
print('=' * 60)
print()
print(f'{\"Category\":25s}  {\"Mode A\":>8s}  {\"Mode B\":>8s}  {\"Delta\":>6s}')
print('-' * 60)

for cat in sorted(weights):
    ca = a.get('categories',{}).get(cat,{})
    cb = b.get('categories',{}).get(cat,{})
    pa = ca.get('pass',0); ta = ca.get('total',0)
    pb = cb.get('pass',0); tb = cb.get('total',0)
    w = weights[cat]
    delta = pb - pa
    sign = '+' if delta > 0 else ''
    label = f\"{cat} {labels[cat]} (x{w})\"
    print(f'  {label:23s}  {pa:>3d}/{ta:<3d}    {pb:>3d}/{tb:<3d}   {sign}{delta}')

print('-' * 60)

wa = a.get('weightedScore',{})
wb = b.get('weightedScore',{})
pa = wa.get('percent',0)
pb = wb.get('percent',0)
delta = pb - pa
sign = '+' if delta > 0 else ''

print(f'  {\"Weighted Score\":23s}  {wa.get(\"raw\",0):>3d}/{wa.get(\"max\",0):<3d}    {wb.get(\"raw\",0):>3d}/{wb.get(\"max\",0):<3d}   {sign}{delta}pts')
print(f'  {\"Percentage\":23s}  {pa:>3d}%       {pb:>3d}%      {sign}{delta}%')
print()

# Highlight biggest category deltas
deltas = []
for cat in sorted(weights):
    ca = a.get('categories',{}).get(cat,{})
    cb = b.get('categories',{}).get(cat,{})
    d = cb.get('pass',0) - ca.get('pass',0)
    if d != 0:
        deltas.append((cat, labels[cat], d, weights[cat]))

if deltas:
    deltas.sort(key=lambda x: abs(x[3] * x[2]), reverse=True)
    print('Biggest weighted deltas:')
    for cat, label, d, w in deltas[:3]:
        sign = '+' if d > 0 else ''
        print(f'  {cat} {label}: {sign}{d} probes x{w} weight = {sign}{d*w} weighted points')
    print()
"
  exit 0
fi

# --- Single project scoring ---
if [[ -z "$PROJECT" ]]; then
  echo "Usage: ./score.sh <project-dir> [--json]"
  echo "       ./score.sh --compare <dir-a> <dir-b>"
  exit 1
fi

score_project "$PROJECT"
