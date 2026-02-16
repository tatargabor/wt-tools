#!/usr/bin/env bash
# preflight.sh - Pre-benchmark infrastructure validation
#
# Run this BEFORE starting a multi-hour benchmark to catch misconfigurations.
# Validates: hooks, memory health, file patterns, port availability.
#
# Usage: bash benchmark/preflight.sh [PORT]
# Exit 0 = all checks pass, Exit 1 = one or more checks failed.

PORT="${1:-3000}"
PASS=0; FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

check() {
    local name="$1" condition="$2"
    if eval "$condition"; then
        echo "  OK: $name"; ((PASS++))
    else
        echo "  FAIL: $name"; ((FAIL++))
    fi
}

echo "=== Benchmark Pre-flight Check ==="
echo ""

# --- Memory system ---
echo "--- Memory System ---"
if command -v wt-memory &>/dev/null; then
    check "wt-memory on PATH" 'true'
else
    check "wt-memory on PATH" 'false'
fi

if wt-memory health &>/dev/null; then
    check "wt-memory health" 'true'
else
    check "wt-memory health" 'false'
fi

# Check auto_ingest=False is in wt-memory proactive
AUTO_INGEST=$(grep -c 'auto_ingest=False' "$PROJECT_ROOT/bin/wt-memory" 2>/dev/null || echo 0)
check "wt-memory proactive has auto_ingest=False" '[ "$AUTO_INGEST" -ge 1 ]'

echo ""

# --- Hooks ---
echo "--- Hooks ---"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
    HAS_SAVE=$(grep -c 'wt-hook-memory-save' "$SETTINGS" 2>/dev/null || echo 0)
    check "wt-hook-memory-save in settings.json" '[ "$HAS_SAVE" -ge 1 ]'

    HAS_RECALL=$(grep -c 'wt-hook-memory-recall' "$SETTINGS" 2>/dev/null || echo 0)
    check "wt-hook-memory-recall in settings.json" '[ "$HAS_RECALL" -ge 1 ]'
else
    check ".claude/settings.json exists" 'false'
fi

# Verify hooks are on PATH
command -v wt-hook-memory-save &>/dev/null
check "wt-hook-memory-save on PATH" 'command -v wt-hook-memory-save &>/dev/null'
check "wt-hook-memory-recall on PATH" 'command -v wt-hook-memory-recall &>/dev/null'

echo ""

# --- Benchmark files ---
echo "--- Benchmark Files ---"
CHANGE_COUNT=$(ls "$PROJECT_ROOT"/benchmark/changes/[0-9]*.md 2>/dev/null | wc -l)
check "12 change files exist (found: $CHANGE_COUNT)" '[ "$CHANGE_COUNT" -eq 12 ]'

TEST_COUNT=$(ls "$PROJECT_ROOT"/benchmark/tests/test-[0-9]*.sh 2>/dev/null | wc -l)
check "12 test scripts exist (found: $TEST_COUNT)" '[ "$TEST_COUNT" -eq 12 ]'

# Verify glob pattern doesn't have the 0*.md bug
GLOB_CHECK=$(ls "$PROJECT_ROOT"/benchmark/changes/[0-9]*.md 2>/dev/null | wc -l)
check "Glob [0-9]*.md matches all changes (not just 01-09)" '[ "$GLOB_CHECK" -ge 10 ]'

# Check test scripts are executable or at least bash-runnable
for t in "$PROJECT_ROOT"/benchmark/tests/test-[0-9]*.sh; do
    if [[ ! -r "$t" ]]; then
        check "$(basename "$t") is readable" 'false'
    fi
done

# Check convention check library exists
check "benchmark/tests/lib/check-conventions.sh exists" '[ -f "$PROJECT_ROOT/benchmark/tests/lib/check-conventions.sh" ]'

echo ""

# --- Port availability ---
echo "--- Port Availability ---"
if command -v ss &>/dev/null; then
    PORT_USED=$(ss -tlnp 2>/dev/null | grep -c ":$PORT " || echo 0)
elif command -v lsof &>/dev/null; then
    PORT_USED=$(lsof -i ":$PORT" 2>/dev/null | grep -c LISTEN || echo 0)
else
    PORT_USED=0  # Can't check, assume free
fi
check "Port $PORT is free" '[ "$PORT_USED" -eq 0 ]'

echo ""

# --- wt-loop ---
echo "--- wt-loop ---"
check "wt-loop on PATH" 'command -v wt-loop &>/dev/null'

# Check the glob pattern in wt-loop itself
if command -v wt-loop &>/dev/null; then
    WL_PATH=$(command -v wt-loop)
    BAD_GLOB=$(grep -c '0\*\.md' "$WL_PATH" 2>/dev/null | tr -d '[:space:]' || echo 0)
    check "wt-loop has no 0*.md glob bug" '[ "${BAD_GLOB:-0}" -eq 0 ]'
fi

echo ""

# --- Summary ---
echo "=== Pre-flight Summary ==="
echo "Results: $PASS passed, $FAIL failed"
echo ""
if [[ $FAIL -gt 0 ]]; then
    echo "BLOCKED: Fix the above failures before starting benchmark."
    exit 1
else
    echo "ALL CLEAR: Ready to run benchmark."
    exit 0
fi
