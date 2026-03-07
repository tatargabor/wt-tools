#!/usr/bin/env bash
# wt-hook-memory ops: recall, proactive, rules matching, output formatting
# Dependencies: util.sh, session.sh must be sourced first

load_matching_rules() {
    local prompt_text="$1"

    local project_root
    project_root=$(git rev-parse --show-toplevel 2>/dev/null) || project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local rules_file="${project_root}/.claude/rules.yaml"

    [[ -f "$rules_file" ]] || { _dbg "rules: no file"; return 0; }

    # Write python to a temp file — avoids heredoc-inside-$() bash parse issues
    local py_tmp
    py_tmp=$(mktemp /tmp/wt-rules.XXXXXX.py)
    # NOTE: no parens/braces inside the heredoc body that bash would misparse
    cat > "$py_tmp" <<'RULES_PY'
import sys
rules_file = sys.argv[1]
prompt_lower = sys.argv[2].lower()
try:
    import yaml
except ImportError:
    sys.exit(0)
try:
    data = yaml.safe_load(open(rules_file))
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
rules = data.get("rules")
if not isinstance(rules, list):
    sys.exit(0)
matched = []
for rule in rules:
    if not isinstance(rule, dict):
        continue
    topics = rule.get("topics") or []
    content = (rule.get("content") or "").strip()
    rid = rule.get("id") or ""
    if not topics or not content:
        continue
    hit = False
    for t in topics:
        if str(t).lower() in prompt_lower:
            hit = True
            break
    if hit:
        matched.append(rid + "\t" + content)
if matched:
    print("=== MANDATORY RULES ===")
    for m in matched:
        rid, cnt = m.split("\t", 1)
        print("[" + rid + "] " + cnt)
    print("===========================")
RULES_PY

    local result
    result=$(python3 "$py_tmp" "$rules_file" "$prompt_text" 2>/dev/null) || true
    rm -f "$py_tmp"

    if [[ -n "$result" ]]; then
        local rule_count
        rule_count=$(printf '%s\n' "$result" | grep -c '^\[' 2>/dev/null || echo "?")
        _log "rules: injecting $rule_count matching rule(s)"
        _dbg "rules block: ${result:0:200}"
        printf '%s\n' "$result"
    else
        _dbg "rules: no matches"
    fi
}

# ============================================================
# Helper: Proactive recall with relevance filtering
# ============================================================

proactive_and_format() {
    local query="$1" limit="${2:-5}"
    _log "proactive: query='${query:0:80}' limit=$limit"

    wt-memory proactive "$query" --limit "$limit" 2>/dev/null > "$TMPFILE" || { _log "proactive: FAILED"; return 1; }

    local result
    result=$(python3 -c "
import sys, json, os, random

# Read used IDs from session cache for uniqueness
cache_file = sys.argv[2]
used_ids = []
try:
    with open(cache_file) as f:
        used_ids = json.load(f).get('_used_context_ids', [])
except Exception:
    pass

def gen_id():
    while True:
        cid = format(random.randint(0, 0xffff), '04x')
        if cid not in used_ids:
            used_ids.append(cid)
            return cid

try:
    memories = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
if not memories: sys.exit(1)
print(f'total={len(memories)}', file=sys.stderr)
filtered = []
for m in memories:
    score = m.get('relevance_score')
    if score is not None and score != 'N/A':
        try:
            if float(score) < 0.3:
                print(f'  skip [{score:.2f}]: {m.get(\"content\",\"\")[:60]}', file=sys.stderr)
                continue
        except (ValueError, TypeError): pass
    filtered.append(m)
if not filtered: sys.exit(1)
seen = set()
emitted = 0
context_ids = []
content_map = {}
for m in filtered:
    c = m.get('content','').replace('\n',' ').strip()
    if len(c) < 20:
        print(f'  skip [short]: {c!r}', file=sys.stderr)
        continue
    key = c[:50]
    if key in seen: continue
    seen.add(key)
    cid = gen_id()
    context_ids.append(cid)
    content_map[cid] = c[:500]
    score = m.get('relevance_score', '?')
    try: score = f'{float(score):.2f}'
    except Exception: pass
    print(f'  [{score}] {c[:100]}', file=sys.stderr)
    print(f'  - [MEM#{cid}] {c}')
    emitted += 1
if not emitted: sys.exit(1)
print(f'filtered={emitted}', file=sys.stderr)

# Write context IDs and content map to side files
ids_file = sys.argv[1] + '.ids'
with open(ids_file, 'w') as f:
    json.dump({'ids': context_ids, 'content': content_map}, f)

# Update session cache with used IDs
try:
    cache = {}
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            cache = json.load(f)
    cache['_used_context_ids'] = used_ids
    with open(cache_file, 'w') as f:
        json.dump(cache, f)
except Exception:
    pass
" "$TMPFILE" "$CACHE_FILE" 2>"$TMPFILE.err")
    local rc=$?
    if [[ -f "$TMPFILE.err" ]]; then
        while IFS= read -r line; do
            _log "proactive: $line"
        done < "$TMPFILE.err"
    fi
    rm -f "$TMPFILE.err"
    [[ $rc -ne 0 ]] && { _log "proactive: no results after filtering"; return 1; }

    # Store injected content for passive matching (reads side file)
    local ids_file="$TMPFILE.ids"
    if [[ -f "$ids_file" ]] && [[ "$METRICS_ENABLED" -eq 1 ]]; then
        python3 -c "
import json, sys, os
ids_file = sys.argv[1]
cache_file = sys.argv[2]
try:
    data = json.load(open(ids_file))
    cache = {}
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            cache = json.load(f)
    ic = cache.get('_injected_content', {})
    ic.update(data.get('content', {}))
    cache['_injected_content'] = ic
    with open(cache_file, 'w') as f:
        json.dump(cache, f)
except Exception:
    pass
" "$ids_file" "$CACHE_FILE" 2>/dev/null
    fi

    # Export IDs for caller
    _LAST_CONTEXT_IDS=""
    if [[ -f "$ids_file" ]]; then
        _LAST_CONTEXT_IDS=$(python3 -c "import json; print(','.join(json.load(open('$ids_file')).get('ids',[])))" 2>/dev/null)
        rm -f "$ids_file"
    fi

    echo "$result"
}

recall_and_format() {
    local query="$1" limit="${2:-3}" mode="${3:-hybrid}"
    _log "recall: query='${query:0:80}' mode=$mode limit=$limit"

    wt-memory recall "$query" --limit "$limit" --mode "$mode" 2>/dev/null > "$TMPFILE" || { _log "recall: FAILED"; return 1; }

    local result
    result=$(python3 -c "
import sys, json, os, random

# Read used IDs from session cache for uniqueness
cache_file = sys.argv[2]
used_ids = []
try:
    with open(cache_file) as f:
        used_ids = json.load(f).get('_used_context_ids', [])
except Exception:
    pass

def gen_id():
    while True:
        cid = format(random.randint(0, 0xffff), '04x')
        if cid not in used_ids:
            used_ids.append(cid)
            return cid

try:
    memories = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
if not memories: sys.exit(1)
print(f'total={len(memories)}', file=sys.stderr)
seen = set()
context_ids = []
content_map = {}
for m in memories:
    score = m.get('relevance_score')
    if score is not None and score != 'N/A':
        try:
            if float(score) < 0.3:
                print(f'  skip [{float(score):.2f}]: {m.get(\"content\",\"\")[:60]}', file=sys.stderr)
                continue
        except (ValueError, TypeError): pass
    c = m.get('content','').replace('\n',' ').strip()
    if len(c) < 20:
        print(f'  skip [short]: {c!r}', file=sys.stderr)
        continue
    key = c[:50]
    if key in seen: continue
    seen.add(key)
    cid = gen_id()
    context_ids.append(cid)
    content_map[cid] = c[:500]
    s = m.get('relevance_score', '?')
    try: s = f'{float(s):.2f}'
    except Exception: pass
    print(f'  [{s}] {c[:100]}', file=sys.stderr)
    print(f'  - [MEM#{cid}] {c}')

# Write context IDs and content map to side files
ids_file = sys.argv[1] + '.ids'
with open(ids_file, 'w') as f:
    json.dump({'ids': context_ids, 'content': content_map}, f)

# Update session cache with used IDs
try:
    cache = {}
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            cache = json.load(f)
    cache['_used_context_ids'] = used_ids
    with open(cache_file, 'w') as f:
        json.dump(cache, f)
except Exception:
    pass
" "$TMPFILE" "$CACHE_FILE" 2>"$TMPFILE.err")
    local rc=$?
    if [[ -f "$TMPFILE.err" ]]; then
        while IFS= read -r line; do
            _log "recall: $line"
        done < "$TMPFILE.err"
    fi
    rm -f "$TMPFILE.err"
    [[ $rc -ne 0 ]] && { _log "recall: no results"; return 1; }

    # Store injected content for passive matching (reads side file)
    local ids_file="$TMPFILE.ids"
    if [[ -f "$ids_file" ]] && [[ "$METRICS_ENABLED" -eq 1 ]]; then
        python3 -c "
import json, sys, os
ids_file = sys.argv[1]
cache_file = sys.argv[2]
try:
    data = json.load(open(ids_file))
    cache = {}
    if os.path.exists(cache_file):
        with open(cache_file) as f:
            cache = json.load(f)
    ic = cache.get('_injected_content', {})
    ic.update(data.get('content', {}))
    cache['_injected_content'] = ic
    with open(cache_file, 'w') as f:
        json.dump(cache, f)
except Exception:
    pass
" "$ids_file" "$CACHE_FILE" 2>/dev/null
    fi

    # Export IDs for caller
    _LAST_CONTEXT_IDS=""
    if [[ -f "$ids_file" ]]; then
        _LAST_CONTEXT_IDS=$(python3 -c "import json; print(','.join(json.load(open('$ids_file')).get('ids',[])))" 2>/dev/null)
        rm -f "$ids_file"
    fi

    echo "$result"
}

# ============================================================
# Helper: Tool-specific query extraction
# ============================================================

extract_query() {
    local result
    result=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
tool = data.get('tool_name', '')
ti = data.get('tool_input', {})
if tool in ('Read', 'Edit', 'Write'):
    fp = ti.get('file_path', '')
    parts = fp.rsplit('/', 2)
    print('/'.join(parts[-2:]) if len(parts) >= 2 else fp)
elif tool == 'Bash':
    print(ti.get('command', '')[:200])
elif tool == 'Task':
    print(ti.get('prompt', '')[:200])
elif tool == 'Grep':
    print(ti.get('pattern', ''))
else:
    print(ti.get('file_path', '') or ti.get('command', '') or ti.get('prompt', '') or ti.get('pattern', '') or '')
" "$INPUT_FILE" 2>/dev/null)
    _dbg "extract_query: '$result'"
    echo "$result"
}

# ============================================================
# Helper: JSON output formatters
# ============================================================

output_hook_context() {
    python3 -c "
import json, sys
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': sys.argv[1],
        'additionalContext': sys.argv[2]
    }
}))" "$1" "$2" 2>/dev/null
}

output_top_context() {
    python3 -c "
import json, sys
print(json.dumps({'additionalContext': sys.argv[1]}))" "$1" 2>/dev/null
}

# ============================================================
# Event: SessionStart
