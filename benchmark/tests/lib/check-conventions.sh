#!/usr/bin/env bash
# check-conventions.sh - Shared convention compliance checks for benchmark tests
#
# Source this file from any test-NN.sh to add convention trap checks.
# Usage: source "$(dirname "$0")/lib/check-conventions.sh"
#
# Requires: check() function and PORT/BASE already defined by the test script.
# Each check_* function increments PASS/FAIL via the existing check() function.

# Detect project root (where prisma/, src/ etc. live)
# Tests run from the CraftBazaar worktree, so we look relative to CWD or script dir
_find_project_root() {
    local dir="${1:-.}"
    # Walk up from CWD to find src/ directory
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/src" ]]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo "."
}

PROJECT_ROOT=$(_find_project_root)

# TRAP-H: formatPrice convention
# Checks that .toFixed() is NOT used outside formatPrice.ts for price formatting
check_convention_format_price() {
    local leaks
    leaks=$(grep -r '\.toFixed(' "$PROJECT_ROOT/src/" 2>/dev/null \
        | grep -v 'formatPrice' \
        | grep -v 'node_modules' \
        | grep -v '.next/' \
        | wc -l)
    check "TRAP-H: No .toFixed() leaks outside formatPrice" '[ "$leaks" -eq 0 ]'
}

# TRAP-I: Pagination convention
# Checks that list API endpoints return { data, total, page, limit } envelope
check_convention_pagination() {
    local port="${1:-$PORT}"
    local base="http://localhost:$port"
    local endpoints=("$base/api/products" "$base/api/vendors")

    for endpoint in "${endpoints[@]}"; do
        local resp
        resp=$(curl -s "$endpoint" 2>/dev/null)
        local has_envelope
        has_envelope=$(echo "$resp" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    keys = set(d.keys()) if isinstance(d, dict) else set()
    print('yes' if {'data','total','page','limit'}.issubset(keys) else 'no')
except:
    print('skip')
" 2>/dev/null)
        if [[ "$has_envelope" != "skip" ]]; then
            check "TRAP-I: $endpoint uses {data,total,page,limit} envelope" '[ "$has_envelope" = "yes" ]'
        fi
    done
}

# TRAP-J: Error codes convention
# Checks that error responses use constants from errors.ts, not hardcoded strings
check_convention_error_codes() {
    # Check if errors.ts or errors.js exists
    local errors_file
    errors_file=$(find "$PROJECT_ROOT/src" -name 'errors.ts' -o -name 'errors.js' 2>/dev/null | head -1)

    if [[ -n "$errors_file" ]]; then
        # Count hardcoded error strings in API routes (rough heuristic)
        local hardcoded
        hardcoded=$(grep -r '"error":\s*"' "$PROJECT_ROOT/src/app/api/" 2>/dev/null \
            | grep -v 'node_modules' \
            | grep -v '.next/' \
            | grep -v 'import' \
            | wc -l)
        # Some hardcoded is OK (edge cases), but flag if excessive (>5)
        check "TRAP-J: Error constants used (hardcoded error strings <= 5)" '[ "$hardcoded" -le 5 ]'
    else
        check "TRAP-J: errors.ts exists" 'false'
    fi
}

# TRAP-K: Soft delete convention
# Checks that product queries filter deletedAt
check_convention_soft_delete() {
    # Find product query files (API routes, pages)
    local product_files
    product_files=$(grep -rl 'product' "$PROJECT_ROOT/src/" 2>/dev/null \
        | grep -v 'node_modules' \
        | grep -v '.next/')

    # Count files that query products (findMany/findFirst/findUnique) without deletedAt filter
    local missing_filter=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        # Check if file has Prisma product queries
        if grep -q 'product.*find\|findMany.*product\|findFirst.*product\|findUnique.*product' "$f" 2>/dev/null; then
            # Check if it also has deletedAt filter
            if ! grep -q 'deletedAt' "$f" 2>/dev/null; then
                ((missing_filter++))
            fi
        fi
    done <<< "$product_files"

    check "TRAP-K: All product queries filter deletedAt (missing: $missing_filter)" '[ "$missing_filter" -eq 0 ]'
}
