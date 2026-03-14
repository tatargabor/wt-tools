#\!/usr/bin/env bash
# wt-hook-memory stop internals: metrics flush, transcript extraction, commit save
# Dependencies: util.sh, session.sh must be sourced first

_stop_flush_metrics() {
    [[ "$METRICS_ENABLED" -eq 0 ]] && return 0
    [[ ! -f "$CACHE_FILE" ]] && { _dbg "metrics: no cache file"; return 0; }

    local TRANSCRIPT_PATH
    TRANSCRIPT_PATH=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('transcript_path',''))" 2>/dev/null)
    TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"

    python3 -c "
import sys, json, os
sys.path.insert(0, '$WT_TOOLS_ROOT')
from lib.metrics import flush_session, scan_transcript_citations

cache_file = sys.argv[1]
session_id = sys.argv[2]
transcript_path = sys.argv[3]

# Read metrics from session cache
try:
    with open(cache_file) as f:
        cache = json.load(f)
except Exception:
    sys.exit(0)

metrics = cache.get('_metrics', [])
if not metrics:
    sys.exit(0)

# Read injected content for passive matching
injected_content = cache.get('_injected_content', {})

# Resolve project name
project = 'unknown'
try:
    import subprocess
    result = subprocess.run(['git', 'rev-parse', '--show-toplevel'],
                          capture_output=True, text=True, timeout=5)
    if result.returncode == 0:
        project = os.path.basename(result.stdout.strip())
except Exception:
    pass

# Scan transcript for citations + passive matches
citations = []
mem_matches = []
if transcript_path and os.path.exists(transcript_path):
    results = scan_transcript_citations(transcript_path, session_id, injected_content)
    # Split into legacy citations and mem_matches
    for r in results:
        if r.get('context_id'):
            mem_matches.append(r)
        else:
            citations.append(r)

# Flush to SQLite
flush_session(session_id, project, metrics, citations, mem_matches)
match_info = f', {len(mem_matches)} passive matches' if mem_matches else ''
print(f'Flushed {len(metrics)} metrics, {len(citations)} citations{match_info}', file=sys.stderr)
" "$CACHE_FILE" "$SESSION_ID" "$TRANSCRIPT_PATH" 2>/dev/null || true
    _log "metrics: flushed to SQLite"
}

# --- Stop: Background raw transcript filter ---

_STOP_PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
STOP_LOCK_FILE="$_STOP_PROJECT_ROOT/.wt-tools/.transcript-extraction.lock"
STOP_LOG_FILE="$_STOP_PROJECT_ROOT/.wt-tools/transcript-extraction.log"

_stop_extract_change_names() {
    local transcript="$1"
    python3 -c "
import json, sys
names = set()
with open(sys.argv[1]) as f:
    for line in f:
        try:
            obj = json.loads(line)
            if obj.get('type') != 'assistant': continue
            for block in (obj.get('message',{}).get('content',[]) or []):
                if not isinstance(block, dict): continue
                if block.get('type') == 'tool_use' and block.get('name') == 'Skill':
                    inp = block.get('input',{})
                    skill = inp.get('skill','')
                    if 'opsx:' in skill or 'openspec-' in skill:
                        args = inp.get('args','').strip()
                        if args:
                            names.add(args.split()[0])
        except: pass
print(','.join(sorted(names)[:5]) if names else '')
" "$transcript" 2>/dev/null
}

_stop_raw_filter() {
    local transcript="$1"
    [[ ! -f "$transcript" ]] && return 1

    # Extract change names (reuse existing logic)
    local change_names
    change_names=$(_stop_extract_change_names "$transcript")
    local first_change="unknown"
    [[ -n "$change_names" ]] && first_change="${change_names%%,*}"

    # Parse and filter transcript — returns JSON array of {type, content} objects
    local filtered_json
    filtered_json=$(TRANSCRIPT_PATH="$transcript" python3 << 'PYEOF'
import json, sys, os

transcript = os.environ['TRANSCRIPT_PATH']
entries = []
file_read_counts = {}

def sanitize_surrogates(s):
    """Replace lone surrogate codepoints with U+FFFD to ensure valid UTF-8."""
    if not isinstance(s, str):
        return s
    return s.encode('utf-8', errors='surrogateescape').decode('utf-8', errors='replace')

with open(transcript) as f:
    for line in f:
        try:
            obj = json.loads(line)
            t = obj.get('type', '')

            if t == 'user':
                msg = obj.get('message', {})
                content = msg.get('content', '')
                if isinstance(content, str):
                    content = sanitize_surrogates(content)
                    # Filter system/command noise
                    import re
                    if '<system-reminder>' in content:
                        content = re.sub(r'<system-reminder>.*?</system-reminder>', '', content, flags=re.DOTALL).strip()
                    if '<local-command' in content or '<command-name>' in content or '<command-message>' in content:
                        content = re.sub(r'<(?:local-command[\w-]*|command-name|command-message|command-args)>.*?</(?:local-command[\w-]*|command-name|command-message|command-args)>', '', content, flags=re.DOTALL).strip()
                    if len(content) >= 15:
                        entries.append({'role': 'user', 'content': content[:2000]})

            elif t == 'assistant':
                msg = obj.get('message', {})
                content_blocks = msg.get('content', [])
                if isinstance(content_blocks, list):
                    for block in content_blocks:
                        if not isinstance(block, dict):
                            continue
                        if block.get('type') == 'text':
                            text = sanitize_surrogates(block.get('text', '')).strip()
                            if len(text) >= 50:
                                entries.append({'role': 'assistant', 'content': text[:2000]})
                        elif block.get('type') == 'tool_use':
                            name = block.get('name', '')
                            inp = block.get('input', {})
                            # Track file reads for dedup
                            if name == 'Read':
                                fp = inp.get('file_path', '')
                                file_read_counts[fp] = file_read_counts.get(fp, 0) + 1
                                if file_read_counts[fp] > 2:
                                    continue
                            # Keep Bash commands with output context
                            if name == 'Bash':
                                cmd = inp.get('command', '')[:200]
                                if cmd:
                                    entries.append({'role': 'assistant', 'content': f'[Bash] {cmd}'})

            elif t == 'tool_result':
                content = obj.get('content', '')
                if isinstance(content, str):
                    content = sanitize_surrogates(content)
                    cl = content.lower()
                    if ('error' in cl or 'failed' in cl or 'traceback' in cl) and len(content) >= 15:
                        entries.append({'role': 'assistant', 'content': f'[Error] {content[:500]}'})
        except:
            pass

print(json.dumps(entries))
PYEOF
    )

    [[ -z "$filtered_json" || "$filtered_json" == "[]" ]] && return 0

    # Write filtered entries to temp file to avoid shell quoting issues
    local entries_file
    entries_file=$(mktemp)
    echo "$filtered_json" > "$entries_file"

    # Save filtered turns with context prefix and tags
    python3 -c "
import json, sys, subprocess, re

HEURISTIC_PATTERNS = [
    'false positive', 'same pattern', 'known pattern', 'known issue',
    'was a false', 'unlike previous', 'same issue as', 'this is not a real',
]
_HEURISTIC_RE = re.compile('|'.join(re.escape(p) for p in HEURISTIC_PATTERNS), re.IGNORECASE)

entries = json.load(open(sys.argv[1]))
if not entries:
    sys.exit(0)

change_name = sys.argv[2]
total = len(entries)
change_tags = f'change:{change_name}' if change_name != 'unknown' else ''
base_tags = 'raw,phase:auto-extract,source:hook'
if change_tags:
    base_tags = f'{base_tags},{change_tags}'

saved = 0
for i, entry in enumerate(entries, 1):
    role = entry['role']
    content = entry['content']
    prefix = f'[session:{change_name}, turn {i}/{total}] '
    full_content = prefix + content

    mem_type = 'Context' if role == 'user' else 'Learning'
    tags = base_tags
    if _HEURISTIC_RE.search(content):
        tags = f'{tags},volatile'

    try:
        subprocess.run(
            ['wt-memory', 'remember', '--type', mem_type, '--tags', tags],
            input=full_content, text=True, capture_output=True, timeout=5
        )
        saved += 1
    except UnicodeEncodeError as e:
        print(f'UnicodeEncodeError at entry {i}/{total}: {e}', file=sys.stderr)
    except Exception as e:
        print(f'Error at entry {i}/{total}: {e}', file=sys.stderr)

print(f'saved={saved}/{total}', file=sys.stderr)
" "$entries_file" "$first_change" 2>> "$STOP_LOG_FILE" || true
    rm -f "$entries_file"

    _log "raw-filter: saved entries for change=$first_change from transcript"
    return 0
}

# One-time migration: commit any existing staged files from Haiku era
_stop_migrate_staged() {
    local found=0
    for staged in .wt-tools/.staged-extract-*; do
        [[ -f "$staged" ]] || continue
        [[ "$staged" == *.ts ]] && continue
        found=1

        local first_change=""
        local first_line
        first_line=$(head -1 "$staged")
        [[ "$first_line" == "#CHANGE:"* ]] && first_change="${first_line#\#CHANGE:}"

        local count=0 conv_count=0 cheat_count=0
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            [[ "$line" == "NONE" ]] && continue
            [[ "$line" == "#CHANGE:"* ]] && continue
            [[ "$line" != *"|"*"|"* ]] && continue

            local mem_type="${line%%|*}"
            local rest="${line#*|}"
            local tags="${rest%%|*}"
            local content="${rest#*|}"

            if [[ "$mem_type" == "Convention" ]]; then
                (( conv_count >= 2 )) && continue
                mem_type="Learning"
                tags="convention,cheat-sheet,$tags"
                (( conv_count++ )) || true
            elif [[ "$mem_type" == "CheatSheet" ]]; then
                (( cheat_count >= 2 )) && continue
                mem_type="Learning"
                tags="cheat-sheet,$tags"
                (( cheat_count++ )) || true
            else
                (( count >= 5 )) && continue
                case "$mem_type" in
                    Learning|Decision|Context) ;;
                    *) continue ;;
                esac
                (( count++ )) || true
            fi

            [[ -z "$content" ]] && continue

            local full_tags="phase:auto-extract,source:hook,$tags"
            [[ -n "$first_change" ]] && full_tags="change:$first_change,$full_tags"

            _log "migrate: committing staged type=$mem_type content='${content:0:80}'"
            echo "$content" | iconv -c -t utf-8 | wt-memory remember --type "$mem_type" --tags "$full_tags" 2>/dev/null || true
        done < "$staged"

        local ts_file="${staged}.ts"
        rm -f "$staged" "$ts_file"
    done
    [[ "$found" -eq 1 ]] && _log "migrate: staged files committed"
}

_stop_run_extraction_bg() {
    local transcript="$1"

    # Lockfile check
    if [[ -f "$STOP_LOCK_FILE" ]]; then
        local existing_pid
        existing_pid=$(cat "$STOP_LOCK_FILE" 2>/dev/null)
        if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$STOP_LOCK_FILE"
    fi

    echo ${BASHPID:-$$} > "$STOP_LOCK_FILE"
    trap 'rm -f "$STOP_LOCK_FILE"' EXIT

    # One-time migration of old Haiku staged files
    _stop_migrate_staged

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting raw filter for: $transcript" >> "$STOP_LOG_FILE"
    _stop_raw_filter "$transcript" 2>> "$STOP_LOG_FILE" || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Raw filter complete" >> "$STOP_LOG_FILE"

    rm -f "$STOP_LOCK_FILE"
}

# --- Stop: Synchronous commit-based extraction ---

_stop_commit_extraction() {
    local MARKER_FILE=".wt-tools/.last-memory-commit"
    local DESIGN_MARKER=".wt-tools/.saved-designs"
    local CODEMAP_MARKER=".wt-tools/.saved-codemaps"

    local LAST_HASH=""
    [[ -f "$MARKER_FILE" ]] && LAST_HASH=$(cat "$MARKER_FILE" 2>/dev/null)

    local CURRENT_HASH
    CURRENT_HASH=$(git rev-parse HEAD 2>/dev/null) || return 0
    [[ "$CURRENT_HASH" == "$LAST_HASH" ]] && return 0

    local COMMITS
    if [[ -n "$LAST_HASH" ]] && git cat-file -t "$LAST_HASH" &>/dev/null; then
        COMMITS=$(git log --oneline "$LAST_HASH..HEAD" 2>/dev/null)
    else
        COMMITS=$(git log --oneline -1 2>/dev/null)
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local hash="${line%% *}"
        local msg="${line#* }"

        local change_name="general"
        [[ "$msg" == *:* ]] && change_name="${msg%%:*}"

        if [[ "$change_name" == "general" ]] && [[ -d "openspec/changes" ]]; then
            for d in openspec/changes/*/; do
                local dname
                dname=$(basename "$d")
                [[ "$dname" == "archive" ]] && continue
                change_name="$dname"
                break
            done
        fi

        # Code map safety net
        touch "$CODEMAP_MARKER" 2>/dev/null
        if ! grep -qx "$change_name" "$CODEMAP_MARKER" 2>/dev/null; then
            local has_codemap
            has_codemap=$(wt-memory recall "$change_name code map" --limit 1 --mode semantic 2>/dev/null \
                | python3 -c "import sys,json; r=json.load(sys.stdin); print('yes' if any('code-map' in ','.join(m.get('tags',[])) for m in r) else 'no')" 2>/dev/null)

            if [[ "$has_codemap" != "yes" ]]; then
                local all_hashes
                all_hashes=$(echo "$COMMITS" | awk '{print $1}')
                local changed_files
                changed_files=$(echo "$all_hashes" | while read -r h; do
                    [[ -z "$h" ]] && continue
                    git diff-tree --no-commit-id --name-only -r "$h" 2>/dev/null
                done \
                    | sort -u \
                    | grep -vE '(package\.json|package-lock|\.config\.|tsconfig|\.test\.|\.spec\.|__test__)' \
                    | head -8 \
                    | tr '\n' ', ' \
                    | sed 's/,$//')

                if [[ -n "$changed_files" ]]; then
                    local codemap_content="$change_name code map (auto): $changed_files"
                    [[ ${#codemap_content} -gt 400 ]] && codemap_content="${codemap_content:0:397}..."
                    _log "remember: codemap change=$change_name files=${changed_files:0:80}"
                    echo "$codemap_content" | wt-memory remember --type Context --tags "change:$change_name,phase:apply,source:hook,code-map" 2>/dev/null || true
                fi
            fi
            echo "$change_name" >> "$CODEMAP_MARKER"
        fi

        # Design choice extraction
        touch "$DESIGN_MARKER" 2>/dev/null
        grep -qx "$change_name" "$DESIGN_MARKER" 2>/dev/null && continue

        local design_file="openspec/changes/$change_name/design.md"
        if [[ -f "$design_file" ]]; then
            local choices
            choices=$(grep '^\*\*Choice\*\*' "$design_file" 2>/dev/null \
                | sed 's/^\*\*Choice\*\*: //' \
                | sed 's/^\*\*Choice\*\*://' \
                | tr '\n' '.' \
                | sed 's/\.\./\. /g; s/\.$//')

            if [[ -n "$choices" ]]; then
                local content="$change_name: $choices"
                [[ ${#content} -gt 300 ]] && content="${content:0:297}..."
                _log "remember: design-choices change=$change_name content='${content:0:80}'"
                echo "$content" | wt-memory remember --type Decision --tags "change:$change_name,phase:apply,source:hook,decisions" 2>/dev/null || true
            fi
        fi
        echo "$change_name" >> "$DESIGN_MARKER"
    done <<< "$COMMITS"

    echo "$CURRENT_HASH" > "$MARKER_FILE"
}
