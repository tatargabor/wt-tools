#!/usr/bin/env bash
# wt-hook-memory session: dedup cache, context ID generation, content tracking
# Dependencies: util.sh must be sourced first

dedup_clear() {
    _dbg "dedup_clear: clearing dedup keys (preserving turn_count, metrics)"
    python3 -c "
import json, sys, os
cache_file = sys.argv[1]
if not os.path.exists(cache_file):
    sys.exit(0)
try:
    with open(cache_file) as f:
        cache = json.load(f)
except:
    sys.exit(0)
# Preserve persistent keys, remove dedup hashes
keep = {}
for k in ('turn_count', 'last_checkpoint_turn', '_metrics', 'frustration_history'):
    if k in cache:
        keep[k] = cache[k]
with open(cache_file, 'w') as f:
    json.dump(keep, f)
" "$CACHE_FILE" 2>/dev/null || rm -f "$CACHE_FILE"
}

dedup_check() {
    [[ ! -f "$CACHE_FILE" ]] && { _dbg "dedup_check: no cache file, miss"; return 1; }
    if python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    cache = json.load(f)
sys.exit(0 if sys.argv[2] in cache else 1)
" "$CACHE_FILE" "$1" 2>/dev/null; then
        _dbg "dedup_check: HIT key=$1"
        return 0
    else
        _dbg "dedup_check: MISS key=$1"
        return 1
    fi
}

dedup_add() {
    _dbg "dedup_add: key=$1"
    python3 -c "
import json, sys, os
cache = {}
if os.path.exists(sys.argv[1]):
    try:
        with open(sys.argv[1]) as f:
            cache = json.load(f)
    except: pass
cache[sys.argv[2]] = 1
with open(sys.argv[1], 'w') as f:
    json.dump(cache, f)
" "$CACHE_FILE" "$1" 2>/dev/null
}

make_dedup_key() {
    echo -n "$1:$2:$3" | md5sum 2>/dev/null | cut -c1-16 || \
    echo -n "$1:$2:$3" | sha256sum 2>/dev/null | cut -c1-16
}

# ============================================================
# Helper: Context ID generation for memory usage tracking
# ============================================================

# Generate a unique 4-char hex context ID within this session.
# Uses /dev/urandom for randomness, checks session cache for collisions.
_gen_context_id() {
    local id
    while true; do
        id=$(head -c 2 /dev/urandom | od -An -tx1 | tr -d ' \n')
        # Check collision in session cache
        if [[ ! -f "$CACHE_FILE" ]] || ! python3 -c "
import json, sys
try:
    cache = json.load(open(sys.argv[1]))
    ids = cache.get('_used_context_ids', [])
    sys.exit(0 if sys.argv[2] in ids else 1)
except Exception:
    sys.exit(1)
" "$CACHE_FILE" "$id" 2>/dev/null; then
            # No collision — register and return
            python3 -c "
import json, sys, os
cache = {}
cf = sys.argv[1]
if os.path.exists(cf):
    try:
        with open(cf) as f:
            cache = json.load(f)
    except Exception:
        pass
ids = cache.get('_used_context_ids', [])
ids.append(sys.argv[2])
cache['_used_context_ids'] = ids
with open(cf, 'w') as f:
    json.dump(cache, f)
" "$CACHE_FILE" "$id" 2>/dev/null
            echo "$id"
            return 0
        fi
    done
}

# Store injected content in session cache for passive matching at Stop time.
# Args: $1=context_id, $2=content_text
_store_injected_content() {
    [[ "$METRICS_ENABLED" -eq 0 ]] && return 0
    python3 -c "
import json, sys, os
cf = sys.argv[1]
cache = {}
if os.path.exists(cf):
    try:
        with open(cf) as f:
            cache = json.load(f)
    except Exception:
        pass
ic = cache.get('_injected_content', {})
ic[sys.argv[2]] = sys.argv[3][:500]
cache['_injected_content'] = ic
with open(cf, 'w') as f:
    json.dump(cache, f)
" "$CACHE_FILE" "$1" "$2" 2>/dev/null || true
}

# ============================================================
# Helper: Load matching rules from .claude/rules.yaml
# Returns formatted MANDATORY RULES block, or empty string.
# Silently skips if file absent, malformed, or yaml unavailable.
# ============================================================

