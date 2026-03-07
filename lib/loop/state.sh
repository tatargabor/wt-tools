#!/usr/bin/env bash
# wt-loop state management: state file paths, init, update, token tracking
# Dependencies: wt-common.sh must be sourced first (provides jq, SCRIPT_DIR)

# Parse ISO 8601 date to epoch seconds (cross-platform)
# Works on both Linux (GNU date) and macOS (BSD date)
parse_date_to_epoch() {
    local date_str="$1"
    local epoch

    if [[ "$(uname)" == "Darwin" ]]; then
        local clean_date
        clean_date=$(echo "$date_str" | sed -E 's/[+-][0-9]{2}:?[0-9]{2}$//')
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean_date" "+%s" 2>/dev/null || echo "0")
    else
        epoch=$(date -d "$date_str" +%s 2>/dev/null || echo "0")
    fi

    echo "$epoch"
}

# Get loop state file path for a worktree
get_loop_state_file() {
    local wt_path="$1"
    echo "$wt_path/.claude/loop-state.json"
}

get_loop_log_dir() {
    local wt_path="$1"
    echo "$wt_path/.claude/logs"
}

get_iter_log_file() {
    local wt_path="$1"
    local iteration="$2"
    local log_dir
    log_dir=$(get_loop_log_dir "$wt_path")
    printf '%s/ralph-iter-%03d.log' "$log_dir" "$iteration"
}

# Get terminal PID file path
get_terminal_pid_file() {
    local wt_path="$1"
    echo "$wt_path/.claude/ralph-terminal.pid"
}

# Initialize loop state
init_loop_state() {
    local wt_path="$1"
    local worktree_name="$2"
    local task="$3"
    local max_iter="$4"
    local done_criteria="$5"
    local capacity_limit="$6"
    local stall_threshold="${7:-$DEFAULT_STALL_THRESHOLD}"
    local iteration_timeout="${8:-45}"
    local label="${9:-}"
    local change="${10:-}"

    local state_file
    state_file=$(get_loop_state_file "$wt_path")

    # Ensure .claude directory exists
    mkdir -p "$wt_path/.claude"

    # Create initial state
    cat > "$state_file" <<EOF
{
  "worktree_name": "$worktree_name",
  "task": $(echo "$task" | jq -Rs .),
  "done_criteria": "$done_criteria",
  "max_iterations": $max_iter,
  "current_iteration": 0,
  "status": "starting",
  "terminal_pid": null,
  "started_at": "$(date -Iseconds)",
  "iterations": [],
  "capacity_limit_pct": $capacity_limit,
  "stall_threshold": $stall_threshold,
  "iteration_timeout_min": $iteration_timeout,
  "total_tokens": 0,
  "token_budget": 0,
  "ff_attempts": 0,
  "max_idle_iterations": 3,
  "idle_count": 0,
  "last_output_hash": null,
  "session_id": null,
  "resume_failures": 0,
  "label": $(if [[ -n "$label" ]]; then echo "\"$label\""; else echo "null"; fi),
  "change": $(if [[ -n "$change" ]]; then echo "\"$change\""; else echo "null"; fi)
}
EOF
}

# Update loop state
update_loop_state() {
    local state_file="$1"
    local field="$2"
    local value="$3"

    local tmp
    tmp=$(mktemp)
    jq ".$field = $value" "$state_file" > "$tmp" && mv "$tmp" "$state_file"
}

# Add iteration to state
add_iteration() {
    local state_file="$1"
    local iteration="$2"
    local started="$3"
    local ended="$4"
    local done_check="$5"
    local commits="$6"
    local tokens_used="${7:-0}"
    local timed_out="${8:-false}"
    local tokens_estimated="${9:-false}"
    local no_op="${10:-false}"
    local ff_exhausted="${11:-false}"
    local log_file="${12:-}"
    local resumed="${13:-false}"
    local ff_recovered="${14:-false}"

    local tmp
    tmp=$(mktemp)
    jq --argjson n "$iteration" \
       --arg started "$started" \
       --arg ended "$ended" \
       --argjson done "$done_check" \
       --argjson commits "$commits" \
       --argjson tokens "$tokens_used" \
       --argjson timed_out "$timed_out" \
       --argjson tokens_estimated "$tokens_estimated" \
       --argjson no_op "$no_op" \
       --argjson ff_exhausted "$ff_exhausted" \
       --arg log_file "$log_file" \
       --argjson resumed "$resumed" \
       --argjson ff_recovered "$ff_recovered" \
       '.iterations += [{
         "n": $n,
         "started": $started,
         "ended": $ended,
         "done_check": $done,
         "commits": $commits,
         "tokens_used": $tokens,
         "timed_out": $timed_out,
         "tokens_estimated": $tokens_estimated,
         "no_op": $no_op,
         "ff_exhausted": $ff_exhausted,
         "log_file": $log_file,
         "resumed": $resumed,
         "ff_recovered": $ff_recovered
       }]' "$state_file" > "$tmp" && mv "$tmp" "$state_file"
}

# Get current token usage from wt-usage
get_current_tokens() {
    local since="${1:-}"
    local usage_json

    if [[ -n "$since" ]]; then
        usage_json=$("$SCRIPT_DIR/wt-usage" --since "$since" --format json 2>/dev/null || echo '{"total_tokens": 0}')
    else
        usage_json=$("$SCRIPT_DIR/wt-usage" --format json 2>/dev/null || echo '{"total_tokens": 0}')
    fi

    # Extract total_tokens, default to 0 if not a valid number
    local tokens
    tokens=$(echo "$usage_json" | jq -r '.total_tokens // 0' 2>/dev/null)
    if [[ "$tokens" =~ ^[0-9]+$ ]]; then
        echo "$tokens"
    else
        echo "0"
    fi
}

# Estimate tokens from session file size growth
# Rough heuristic: ~4 tokens per byte of JSONL
estimate_tokens_from_files() {
    local wt_path="$1"
    local since_epoch="$2"

    local total_bytes=0
    local claude_dir="$HOME/.claude/projects"

    if [[ ! -d "$claude_dir" ]]; then
        echo "0"
        return
    fi

    # Find JSONL files modified since the given epoch
    while IFS= read -r -d '' jsonl_file; do
        local file_mtime
        file_mtime=$(stat -c %Y "$jsonl_file" 2>/dev/null || stat -f %m "$jsonl_file" 2>/dev/null || echo "0")
        if [[ "$file_mtime" -ge "$since_epoch" ]]; then
            local file_size
            file_size=$(stat -c %s "$jsonl_file" 2>/dev/null || stat -f %z "$jsonl_file" 2>/dev/null || echo "0")
            total_bytes=$((total_bytes + file_size))
        fi
    done < <(find "$claude_dir" -name "*.jsonl" -print0 2>/dev/null)

    # Rough estimate: 4 tokens per byte
    echo $((total_bytes / 4))
}

# Update terminal window title
update_terminal_title() {
    local title="$1"
    printf '\033]0;%s\007' "$title"
}
