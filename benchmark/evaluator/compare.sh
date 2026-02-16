#!/usr/bin/env bash
# compare.sh - Compare results from two benchmark runs
#
# Usage: ./compare.sh <run-a-results.json> <run-b-results.json>
# Output: Comparison report to stdout

set -euo pipefail

RUN_A="${1:-}"
RUN_B="${2:-}"

if [ -z "$RUN_A" ] || [ -z "$RUN_B" ]; then
  echo "Usage: $0 <run-a-results.json> <run-b-results.json>"
  exit 1
fi

if [ ! -f "$RUN_A" ] || [ ! -f "$RUN_B" ]; then
  echo "ERROR: One or both result files not found"
  exit 1
fi

python3 -c "
import json, sys

with open('$RUN_A') as f:
    a = json.load(f)
with open('$RUN_B') as f:
    b = json.load(f)

print('=' * 70)
print('BENCHMARK COMPARISON REPORT')
print('=' * 70)
print()
print(f'Run A: {a.get(\"run_label\", \"unknown\")}')
print(f'Run B: {b.get(\"run_label\", \"unknown\")}')
print()

# --- Commit comparison ---
print('--- Commits ---')
print(f'  Run A: {a.get(\"commit_count\", 0)} commits')
print(f'  Run B: {b.get(\"commit_count\", 0)} commits')
print()

# --- Agent status files ---
print('--- Changes Completed ---')
a_status = a.get('agent_status_files', {})
b_status = b.get('agent_status_files', {})
a_complete = sum(1 for v in a_status.values() if isinstance(v, dict) and v.get('completed'))
b_complete = sum(1 for v in b_status.values() if isinstance(v, dict) and v.get('completed'))
print(f'  Run A: {a_complete}/{len(a_status)} changes completed')
print(f'  Run B: {b_complete}/{len(b_status)} changes completed')
print()

# --- Test results comparison ---
print('--- Test Results ---')
a_tests = a.get('test_results', {})
b_tests = b.get('test_results', {})
all_tests = sorted(set(list(a_tests.keys()) + list(b_tests.keys())))

print(f'  {\"Test\":<16} {\"Run A\":>12} {\"Run B\":>12} {\"Delta\":>8}')
print(f'  {\"-\" * 16} {\"-\" * 12} {\"-\" * 12} {\"-\" * 8}')

a_total_pass = 0
b_total_pass = 0
a_total_fail = 0
b_total_fail = 0

for t in all_tests:
    a_t = a_tests.get(t, {})
    b_t = b_tests.get(t, {})
    a_p = a_t.get('passed', 0)
    a_f = a_t.get('failed', 0)
    b_p = b_t.get('passed', 0)
    b_f = b_t.get('failed', 0)
    a_total_pass += a_p
    b_total_pass += b_p
    a_total_fail += a_f
    b_total_fail += b_f

    a_str = f'{a_p}P/{a_f}F' if a_t else 'N/A'
    b_str = f'{b_p}P/{b_f}F' if b_t else 'N/A'
    delta = (b_p - b_f) - (a_p - a_f) if a_t and b_t else 'N/A'
    delta_str = f'+{delta}' if isinstance(delta, int) and delta > 0 else str(delta)
    print(f'  {t:<16} {a_str:>12} {b_str:>12} {delta_str:>8}')

print(f'  {\"-\" * 16} {\"-\" * 12} {\"-\" * 12} {\"-\" * 8}')
print(f'  {\"TOTAL\":<16} {a_total_pass}P/{a_total_fail}F {b_total_pass}P/{b_total_fail}F')
print()

# --- Evaluator comparison ---
for ev in ['eval-schema', 'eval-api', 'eval-behavior', 'eval-coherence']:
    a_ev = a.get(ev, {})
    b_ev = b.get(ev, {})
    if a_ev or b_ev:
        a_sum = a_ev.get('summary', {})
        b_sum = b_ev.get('summary', {})
        print(f'--- {ev} ---')
        if a_sum:
            print(f'  Run A: {a_sum.get(\"passed\", 0)}/{a_sum.get(\"total\", 0)} checks passed')
        else:
            print(f'  Run A: N/A')
        if b_sum:
            print(f'  Run B: {b_sum.get(\"passed\", 0)}/{b_sum.get(\"total\", 0)} checks passed')
        else:
            print(f'  Run B: N/A')
        print()

# --- Memory metrics (Run B only) ---
mem_status = b.get('memory_status', {})
memories = b.get('memories', [])
if mem_status or memories:
    print('--- Memory Metrics (Run B) ---')
    if mem_status:
        print(f'  Total memories: {mem_status.get(\"count\", 0)}')
    if isinstance(memories, list):
        types = {}
        for m in memories:
            t = m.get('type', 'unknown')
            types[t] = types.get(t, 0) + 1
        for t, c in sorted(types.items()):
            print(f'  {t}: {c}')
    print()

# --- Overall verdict ---
print('=' * 70)
print('VERDICT')
print('=' * 70)

a_score = a_total_pass - a_total_fail
b_score = b_total_pass - b_total_fail

if b_score > a_score:
    print(f'Run B (memory) scored higher: {b_score} vs {a_score} (delta: +{b_score - a_score})')
elif a_score > b_score:
    print(f'Run A (baseline) scored higher: {a_score} vs {b_score} (delta: +{a_score - b_score})')
else:
    print(f'Tie: both scored {a_score}')
print()
"
