#!/usr/bin/env bash
# Unit tests for complexity-aware dispatch ordering
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# ─── Tests ───────────────────────────────────────────────────────────

test_l_dispatches_before_m() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local state_file="$tmp_dir/state.json"
    local plan_file="$tmp_dir/plan.json"

    # State: two pending changes, M and L complexity, no deps
    cat > "$state_file" <<'EOF'
{
  "status": "running",
  "changes": [
    {"name": "small-change", "status": "pending", "complexity": "M", "depends_on": []},
    {"name": "big-change", "status": "pending", "complexity": "L", "depends_on": []}
  ]
}
EOF

    cat > "$plan_file" <<'EOF'
{
  "changes": [
    {"name": "small-change", "depends_on": []},
    {"name": "big-change", "depends_on": []}
  ]
}
EOF

    # Track dispatch order
    local dispatch_log="$tmp_dir/dispatch.log"
    touch "$dispatch_log"

    # Stub all dependencies
    export STATE_FILENAME="$state_file"
    export PLAN_FILENAME="$plan_file"
    count_changes_by_status() {
        jq -r --arg s "$1" '[.changes[] | select(.status == $s)] | length' "$STATE_FILENAME"
    }
    get_change_status() {
        jq -r --arg n "$1" '.changes[] | select(.name == $n) | .status' "$STATE_FILENAME"
    }
    deps_satisfied() {
        local deps
        deps=$(jq -r --arg n "$1" '.changes[] | select(.name == $n) | .depends_on[]?' "$STATE_FILENAME" 2>/dev/null)
        [[ -z "$deps" ]]
    }
    dispatch_change() {
        echo "$1" >> "$dispatch_log"
    }

    # Source topological_sort and dispatch_ready_changes
    source <(sed -n '/^topological_sort()/,/^}/p' "$SCRIPT_DIR/../../lib/orchestration/state.sh")
    source <(sed -n '/^dispatch_ready_changes()/,/^}/p' "$SCRIPT_DIR/../../lib/orchestration/dispatcher.sh")

    dispatch_ready_changes 2

    local first_dispatched
    first_dispatched=$(head -1 "$dispatch_log")
    assert_equals "big-change" "$first_dispatched" "L-complexity should dispatch before M"

    local count
    count=$(wc -l < "$dispatch_log")
    assert_equals "2" "$count" "both changes should be dispatched"

    rm -rf "$tmp_dir"
}

test_missing_complexity_defaults_to_m() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local state_file="$tmp_dir/state.json"
    local plan_file="$tmp_dir/plan.json"

    # One change has no complexity field
    cat > "$state_file" <<'EOF'
{
  "status": "running",
  "changes": [
    {"name": "no-complexity", "status": "pending", "depends_on": []},
    {"name": "large-one", "status": "pending", "complexity": "L", "depends_on": []}
  ]
}
EOF

    cat > "$plan_file" <<'EOF'
{
  "changes": [
    {"name": "no-complexity", "depends_on": []},
    {"name": "large-one", "depends_on": []}
  ]
}
EOF

    local dispatch_log="$tmp_dir/dispatch.log"
    touch "$dispatch_log"

    export STATE_FILENAME="$state_file"
    export PLAN_FILENAME="$plan_file"
    count_changes_by_status() {
        jq -r --arg s "$1" '[.changes[] | select(.status == $s)] | length' "$STATE_FILENAME"
    }
    get_change_status() {
        jq -r --arg n "$1" '.changes[] | select(.name == $n) | .status' "$STATE_FILENAME"
    }
    deps_satisfied() {
        local deps
        deps=$(jq -r --arg n "$1" '.changes[] | select(.name == $n) | .depends_on[]?' "$STATE_FILENAME" 2>/dev/null)
        [[ -z "$deps" ]]
    }
    dispatch_change() {
        echo "$1" >> "$dispatch_log"
    }

    source <(sed -n '/^topological_sort()/,/^}/p' "$SCRIPT_DIR/../../lib/orchestration/state.sh")
    source <(sed -n '/^dispatch_ready_changes()/,/^}/p' "$SCRIPT_DIR/../../lib/orchestration/dispatcher.sh")

    dispatch_ready_changes 2

    local first_dispatched
    first_dispatched=$(head -1 "$dispatch_log")
    assert_equals "large-one" "$first_dispatched" "L should dispatch before default-M"

    rm -rf "$tmp_dir"
}

run_tests
