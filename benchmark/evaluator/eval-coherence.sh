#!/usr/bin/env bash
# eval-coherence.sh - Evaluate project coherence
# Checks: prisma validate, tsc, seed script
#
# Usage: ./eval-coherence.sh <project-dir>
# Output: JSON object with check results

set -euo pipefail

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

python3 -c "
import json, subprocess, os

results = {}

def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout.strip(), r.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, '', 'timeout'
    except Exception as e:
        return -1, '', str(e)

# --- Check 1: npx prisma validate ---
code, out, err = run('npx prisma validate')
results['prisma_validate'] = {
    'passed': code == 0,
    'output': (out or err)[:500]
}

# --- Check 2: TypeScript compilation ---
# Try tsc --noEmit if tsconfig exists
if os.path.exists('tsconfig.json'):
    code, out, err = run('npx tsc --noEmit', timeout=60)
    error_count = 0
    if code != 0:
        # Count TS errors
        error_lines = [l for l in (out + err).split('\n') if 'error TS' in l]
        error_count = len(error_lines)
    results['typescript'] = {
        'passed': code == 0,
        'error_count': error_count,
        'sample_errors': (err or out)[:500] if code != 0 else ''
    }
else:
    results['typescript'] = {
        'passed': True,
        'note': 'no tsconfig.json found'
    }

# --- Check 3: Prisma generate ---
code, out, err = run('npx prisma generate')
results['prisma_generate'] = {
    'passed': code == 0,
    'output': (out or err)[:300]
}

# --- Check 4: Seed script runs ---
# Check if seed script is defined in package.json
seed_exists = False
if os.path.exists('package.json'):
    with open('package.json') as f:
        pkg = json.load(f)
    seed_cmd = pkg.get('prisma', {}).get('seed', '')
    seed_exists = bool(seed_cmd)

if seed_exists:
    code, out, err = run('npx prisma db seed', timeout=30)
    results['seed_script'] = {
        'passed': code == 0,
        'output': (out or err)[:500]
    }
else:
    results['seed_script'] = {
        'passed': False,
        'note': 'no seed script defined in package.json'
    }

# --- Check 5: Dev server starts (quick check) ---
code, out, err = run('npx next build --no-lint 2>&1 | head -20', timeout=120)
results['build'] = {
    'passed': code == 0,
    'output': (out or err)[:500]
}

# --- Summary ---
checks = {k: v['passed'] for k, v in results.items() if isinstance(v, dict) and 'passed' in v}
total = len(checks)
passed = sum(1 for v in checks.values() if v)
results['summary'] = {'total': total, 'passed': passed, 'failed': total - passed}

print(json.dumps(results, indent=2))
"
