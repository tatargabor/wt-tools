#!/usr/bin/env bash
# wt-hook-memory utilities: logging, metrics timers, score extraction
# Dependencies: WT_TOOLS_ROOT must be set by the dispatcher before sourcing

# If WT_TOOLS_ROOT not set by dispatcher, resolve from lib/hooks/ location
if [[ -z "${WT_TOOLS_ROOT:-}" ]]; then
    WT_TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

# --- Logging ---
DEBUG_LOG="/tmp/wt-hook-memory.log"
[[ -f /tmp/wt-hook-memory.debug ]] && WT_HOOK_DEBUG=1

# Always-on lightweight log: one line per hook invocation (for prod debugging)
_log() {
    echo "[$(date '+%H:%M:%S')] [$EVENT] $*" >> "$DEBUG_LOG"
}

# Verbose debug log: gated on WT_HOOK_DEBUG=1
_dbg() {
    [[ "${WT_HOOK_DEBUG:-}" == "1" ]] || return 0
    echo "[$(date '+%H:%M:%S')] [$EVENT] DBG $*" >> "$DEBUG_LOG"
}

_dbg "=== START ==="

# --- Checkpoint configuration ---
CHECKPOINT_INTERVAL=10  # Save checkpoint every N user prompts

# --- Metrics collection ---
METRICS_ENABLED_FLAG="${HOME}/.local/share/wt-tools/metrics/.enabled"
METRICS_ENABLED=0
[[ -f "$METRICS_ENABLED_FLAG" ]] && METRICS_ENABLED=1
_METRICS_TIMER_START=0

_metrics_timer_start() {
    [[ "$METRICS_ENABLED" -eq 0 ]] && return 0
    _METRICS_TIMER_START=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
}

_metrics_timer_elapsed() {
    [[ "$METRICS_ENABLED" -eq 0 ]] && { echo 0; return 0; }
    local now
    now=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
    echo $(( now - _METRICS_TIMER_START ))
}

# Append a metrics record to session cache _metrics array.
# Args: layer event query result_count filtered_count relevance_scores_json duration_ms token_estimate dedup_hit [context_ids_csv]
_metrics_append() {
    [[ "$METRICS_ENABLED" -eq 0 ]] && return 0
    local layer="$1" event="$2" query="${3:0:500}" result_count="${4:-0}" filtered_count="${5:-0}"
    local scores_json="${6:-[]}" duration_ms="${7:-0}" token_estimate="${8:-0}" dedup_hit="${9:-0}"
    local context_ids_csv="${10:-}"

    python3 -c "
import json, sys, os
from datetime import datetime, timezone

cache_file = sys.argv[1]
cache = {}
if os.path.exists(cache_file):
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except Exception: pass

metrics = cache.get('_metrics', [])
if len(metrics) >= 500:
    sys.exit(0)

scores = json.loads(sys.argv[8])
avg_r = sum(scores)/len(scores) if scores else None
max_r = max(scores) if scores else None
min_r = min(scores) if scores else None

# Parse context_ids from CSV
cids_csv = sys.argv[11] if len(sys.argv) > 11 else ''
context_ids = [x for x in cids_csv.split(',') if x] if cids_csv else []

metrics.append({
    'ts': datetime.now(timezone.utc).isoformat(),
    'layer': sys.argv[2],
    'event': sys.argv[3],
    'query': sys.argv[4],
    'result_count': int(sys.argv[5]),
    'filtered_count': int(sys.argv[6]),
    'avg_relevance': round(avg_r, 4) if avg_r is not None else None,
    'max_relevance': round(max_r, 4) if max_r is not None else None,
    'min_relevance': round(min_r, 4) if min_r is not None else None,
    'duration_ms': int(sys.argv[7]),
    'token_estimate': int(sys.argv[9]),
    'dedup_hit': int(sys.argv[10]),
    'context_ids': context_ids,
})
cache['_metrics'] = metrics
with open(cache_file, 'w') as f:
    json.dump(cache, f)
" "$CACHE_FILE" "$layer" "$event" "$query" "$result_count" "$filtered_count" \
  "$duration_ms" "$scores_json" "$token_estimate" "$dedup_hit" "$context_ids_csv" 2>/dev/null || true
}

# Extract relevance scores from proactive/recall JSON output.
# Reads from $TMPFILE, outputs JSON array of floats.
_extract_scores() {
    python3 -c "
import json, sys
try:
    memories = json.load(open(sys.argv[1]))
except: memories = []
scores = []
for m in memories:
    s = m.get('relevance_score')
    if s is not None and s != 'N/A':
        try: scores.append(round(float(s), 4))
        except: pass
print(json.dumps(scores))
" "$TMPFILE" 2>/dev/null || echo "[]"
}

# --- Health check (single, shared) ---
if ! command -v wt-memory &>/dev/null; then
    _dbg "SKIP: wt-memory not in PATH"
    exit 0
fi
if ! wt-memory health &>/dev/null; then
    _dbg "SKIP: wt-memory unhealthy"
    exit 0
fi

# --- Store input in temp file (efficient for large PostToolUse payloads) ---
INPUT_FILE=$(mktemp)
TMPFILE=$(mktemp)
trap 'rm -f "$INPUT_FILE" "$TMPFILE"' EXIT
cat > "$INPUT_FILE"

_dbg "input: $(wc -c < "$INPUT_FILE") bytes"

# --- Session ID for dedup cache ---
SESSION_ID=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
CACHE_FILE="/tmp/wt-memory-session-${SESSION_ID}.json"

_dbg "session=$SESSION_ID"

# ============================================================
# Helper: Session dedup cache
# ============================================================

