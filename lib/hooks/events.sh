#!/usr/bin/env bash
# wt-hook-memory event handlers: SessionStart, UserPrompt, PostTool, Stop, etc.
# Dependencies: util.sh, session.sh, memory-ops.sh, stop.sh must be sourced first

handle_session_start() {
    _metrics_timer_start
    local SOURCE
    SOURCE=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('source',''))" 2>/dev/null)
    _dbg "source=$SOURCE"

    # Clear dedup cache on new session or explicit clear
    if [[ "$SOURCE" == "startup" || "$SOURCE" == "clear" ]]; then
        dedup_clear
    fi

    # --- Cheat sheet recall ---
    local CHEAT_SHEET=""
    if wt-memory recall "cheat-sheet operational" --tags "cheat-sheet" --limit 5 2>/dev/null > "$TMPFILE"; then
        CHEAT_SHEET=$(python3 -c "
import sys, json
try:
    memories = json.load(open(sys.argv[1]))
except: sys.exit(0)
if not memories: sys.exit(0)
seen = set()
for m in memories:
    c = m.get('content','').replace('\n',' ').strip()
    if len(c) < 20: continue
    key = c[:50]
    if key in seen: continue
    seen.add(key)
    print(f'  - {c}')
" "$TMPFILE" 2>/dev/null)
    fi

    # --- Proactive project context (using git changed files, not commit messages) ---
    local PROJECT_CONTEXT=""
    local PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local PROJECT_NAME
    PROJECT_NAME=$(basename "$PROJECT_DIR")

    local RECENT_FILES=""
    if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
        RECENT_FILES=$(git -C "$PROJECT_DIR" diff --name-only HEAD~5 HEAD 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/,$//')
        [[ -z "$RECENT_FILES" ]] && RECENT_FILES=$(git -C "$PROJECT_DIR" diff --name-only 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/,$//')
    fi

    local PROACTIVE_QUERY="Project: $PROJECT_NAME. Changed files: $RECENT_FILES"
    _dbg "proactive query: '${PROACTIVE_QUERY:0:120}'"
    PROJECT_CONTEXT=$(proactive_and_format "$PROACTIVE_QUERY" 5) || true

    # --- Build output ---
    local OUTPUT=""
    if [[ -n "$CHEAT_SHEET" ]]; then
        OUTPUT="=== OPERATIONAL CHEAT SHEET ===\n$CHEAT_SHEET"
        _dbg "cheat_sheet: $(echo "$CHEAT_SHEET" | wc -l) lines"
    else
        _dbg "cheat_sheet: empty"
    fi
    if [[ -n "$PROJECT_CONTEXT" ]]; then
        [[ -n "$OUTPUT" ]] && OUTPUT="$OUTPUT\n\n"
        OUTPUT="${OUTPUT}=== PROJECT CONTEXT ===\n$PROJECT_CONTEXT"
        _dbg "project_context: $(echo "$PROJECT_CONTEXT" | wc -l) lines"
    else
        _dbg "project_context: empty"
    fi

    if [[ -z "$OUTPUT" ]]; then
        _dbg "no output, exiting"
        local _dur; _dur=$(_metrics_timer_elapsed)
        _metrics_append "L1" "SessionStart" "$PROACTIVE_QUERY" 0 0 "[]" "$_dur" 0 0 ""
        exit 0
    fi

    local _output_text
    _output_text=$(echo -e "$OUTPUT")
    local _tok_est=$(( ${#_output_text} / 4 ))
    local _dur; _dur=$(_metrics_timer_elapsed)
    local _scores; _scores=$(_extract_scores)
    local _res_count; _res_count=$(echo "$PROJECT_CONTEXT" | grep -c '^  - ' 2>/dev/null || echo 0)
    _metrics_append "L1" "SessionStart" "$PROACTIVE_QUERY" "$_res_count" "$_res_count" "$_scores" "$_dur" "$_tok_est" 0 "$_LAST_CONTEXT_IDS"

    _dbg "=== OUTPUT ($(echo -e "$OUTPUT" | wc -c) bytes) ==="
    output_hook_context "SessionStart" "$_output_text"
}

# ============================================================
# Helper: Mid-session checkpoint save
# ============================================================

_checkpoint_save() {
    local turn_count="$1" last_checkpoint="$2"
    _log "checkpoint: saving turns $((last_checkpoint + 1))-$turn_count"

    local SUMMARY
    SUMMARY=$(python3 -c "
import json, sys, os

cache_file = sys.argv[1]
last_cp = int(sys.argv[2])
current = int(sys.argv[3])

cache = {}
if os.path.exists(cache_file):
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except: pass

metrics = cache.get('_metrics', [])

# Collect activity since last checkpoint
# Count L2 (UserPromptSubmit) entries to map metrics to turns
files_read = set()
commands_run = 0
topics = []
l2_count = 0

for m in metrics:
    # Only process metrics recorded after last checkpoint turn
    if m.get('event') == 'UserPromptSubmit':
        l2_count += 1
        if l2_count <= last_cp:
            continue
        q = m.get('query', '')
        if q and len(q) > 10:
            # Extract meaningful topic (skip change name prefix)
            words = q.split()[:6]
            topics.append(' '.join(words))
    elif m.get('event') == 'PostToolUse' and l2_count > last_cp:
        q = m.get('query', '')
        if '/' in q and not q.startswith('git '):
            files_read.add(q)
        elif q:
            commands_run += 1

# Build summary
parts = []
if files_read:
    flist = ', '.join(sorted(files_read)[:8])
    if len(files_read) > 8:
        flist += f' (+{len(files_read)-8} more)'
    parts.append(f'Files: {flist}')
if commands_run:
    parts.append(f'Commands: {commands_run}')
if topics:
    # Deduplicate and limit topics
    seen = set()
    unique_topics = []
    for t in topics:
        key = t[:30].lower()
        if key not in seen:
            seen.add(key)
            unique_topics.append(t[:60])
    if unique_topics:
        parts.append(f'Topics: {chr(10).join(unique_topics[:5])}')

if not parts:
    parts.append('(conversation-only, no tool activity)')

summary = f'[session checkpoint, turns {last_cp+1}-{current}] ' + ' | '.join(parts)
print(summary[:800])
" "$CACHE_FILE" "$last_checkpoint" "$turn_count" 2>/dev/null)

    if [[ -n "$SUMMARY" ]]; then
        echo "$SUMMARY" | wt-memory remember --type Context --tags "phase:checkpoint,source:hook" 2>/dev/null || true
        _log "checkpoint: saved"

        # Update last_checkpoint_turn in cache
        python3 -c "
import json, sys, os
cache_file = sys.argv[1]
new_turn = int(sys.argv[2])
cache = {}
if os.path.exists(cache_file):
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except: pass
cache['last_checkpoint_turn'] = new_turn
with open(cache_file, 'w') as f:
    json.dump(cache, f)
" "$CACHE_FILE" "$turn_count" 2>/dev/null || true
    else
        _dbg "checkpoint: empty summary, skipped"
    fi
}

# ============================================================
# Event: UserPromptSubmit
# ============================================================

handle_user_prompt() {
    _metrics_timer_start
    local PROMPT
    PROMPT=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('prompt',''))" 2>/dev/null)
    _dbg "prompt='${PROMPT:0:120}'"
    [[ -z "$PROMPT" ]] && { _dbg "empty prompt, exiting"; exit 0; }

    # --- Turn counter ---
    local TURN_COUNT LAST_CHECKPOINT_TURN
    read -r TURN_COUNT LAST_CHECKPOINT_TURN < <(python3 -c "
import json, sys, os
cache_file = sys.argv[1]
cache = {}
if os.path.exists(cache_file):
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except: pass
tc = cache.get('turn_count', 0) + 1
lct = cache.get('last_checkpoint_turn', 0)
cache['turn_count'] = tc
cache['last_checkpoint_turn'] = lct
with open(cache_file, 'w') as f:
    json.dump(cache, f)
print(tc, lct)
" "$CACHE_FILE" 2>/dev/null) || { TURN_COUNT=1; LAST_CHECKPOINT_TURN=0; }
    _dbg "turn=$TURN_COUNT last_checkpoint=$LAST_CHECKPOINT_TURN"

    # --- Checkpoint trigger ---
    if (( TURN_COUNT - LAST_CHECKPOINT_TURN >= CHECKPOINT_INTERVAL )); then
        _checkpoint_save "$TURN_COUNT" "$LAST_CHECKPOINT_TURN"
    fi

    # --- Emotion detection ---
    local EMOTION_RESULT=""
    EMOTION_RESULT=$(python3 -c "
import json, sys
sys.path.insert(0, '$WT_TOOLS_ROOT')
from lib.frustration import detect

prompt = json.load(open(sys.argv[1])).get('prompt', '')

# Load session frustration history from dedup cache
cache_file = sys.argv[2]
history = {'count': 0, 'last_level': 'none'}
try:
    with open(cache_file) as f:
        cache = json.load(f)
        history = cache.get('frustration_history', history)
except: pass

result = detect(prompt, session_history=history)

# Save updated history back to cache
try:
    cache = {}
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except: pass
    cache['frustration_history'] = history
    with open(cache_file, 'w') as f:
        json.dump(cache, f)
except: pass

print(json.dumps(result))
" "$INPUT_FILE" "$CACHE_FILE" 2>/dev/null) || true

    local EMOTION_LEVEL="none"
    local EMOTION_INJECT=false
    local EMOTION_SAVE=false
    local EMOTION_TRIGGERS=""
    if [[ -n "$EMOTION_RESULT" ]]; then
        EMOTION_LEVEL=$(echo "$EMOTION_RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('level','none'))" 2>/dev/null || echo "none")
        EMOTION_INJECT=$(echo "$EMOTION_RESULT" | python3 -c "import json,sys; print(str(json.load(sys.stdin).get('inject',False)).lower())" 2>/dev/null || echo "false")
        EMOTION_SAVE=$(echo "$EMOTION_RESULT" | python3 -c "import json,sys; print(str(json.load(sys.stdin).get('save',False)).lower())" 2>/dev/null || echo "false")
        EMOTION_TRIGGERS=$(echo "$EMOTION_RESULT" | python3 -c "import json,sys; print(', '.join(json.load(sys.stdin).get('triggers',[])))" 2>/dev/null || echo "")
    fi
    _dbg "emotion: level=$EMOTION_LEVEL triggers=$EMOTION_TRIGGERS save=$EMOTION_SAVE inject=$EMOTION_INJECT"

    # Save memory on moderate/high
    if [[ "$EMOTION_SAVE" == "true" ]]; then
        local SAVE_TAGS="frustration,recurring,source:emotion-detect"
        local SAVE_PREFIX="⚠️ User frustrated (moderate)"
        if [[ "$EMOTION_LEVEL" == "high" ]]; then
            SAVE_TAGS="frustration,high-priority,source:emotion-detect"
            SAVE_PREFIX="🔴 User frustrated (high)"
        fi
        local SAVE_CONTENT="$SAVE_PREFIX: ${PROMPT:0:500}"
        _log "remember: frustration type=Learning tags=$SAVE_TAGS"
        echo "$SAVE_CONTENT" | wt-memory remember --type Learning --tags "$SAVE_TAGS" 2>/dev/null || true
    fi

    # Extract change name from opsx/openspec skill invocation (not explore)
    local CHANGE_NAME=""
    CHANGE_NAME=$(echo "$PROMPT" | python3 -c "
import sys, re
prompt = sys.stdin.read()
CHANGE_SKILLS = r'(?:opsx:(?:apply|continue|verify|archive|sync|ff|new)|openspec-(?:apply|continue|verify|archive|sync|ff|new)[\w-]*)'
m = re.search(CHANGE_SKILLS + r'\s+(\S+)', prompt)
if m: print(m.group(1))
" 2>/dev/null)

    local QUERY=""
    if [[ -n "$CHANGE_NAME" ]]; then
        QUERY="$CHANGE_NAME ${PROMPT:0:200}"
    else
        QUERY="${PROMPT:0:200}"
    fi

    _dbg "change_name='$CHANGE_NAME' query='${QUERY:0:100}'"

    # Proactive recall (no MEMORY_COUNT==0 guard — fresh projects benefit from proactive)
    local FORMATTED=""
    FORMATTED=$(proactive_and_format "$QUERY" 5) || true

    # Load mandatory rules (deterministic, topic-matched, no shodh-memory dependency)
    local RULES_BLOCK=""
    RULES_BLOCK=$(load_matching_rules "$PROMPT") || true

    # Build output — mandatory rules + emotion warning + proactive recall
    local CONTEXT_TEXT=""

    # Inject mandatory rules first (highest priority)
    if [[ -n "$RULES_BLOCK" ]]; then
        CONTEXT_TEXT="$RULES_BLOCK"
    fi

    # Inject emotion warning if detected
    if [[ "$EMOTION_INJECT" == "true" ]]; then
        local EMOTION_WARNING=""
        if [[ "$EMOTION_LEVEL" == "high" ]]; then
            EMOTION_WARNING="⚠ EMOTION DETECTED: The user appears strongly frustrated (triggers: $EMOTION_TRIGGERS). Acknowledge their concern directly. Be extra careful and avoid repeating previous mistakes."
        elif [[ "$EMOTION_LEVEL" == "moderate" ]]; then
            EMOTION_WARNING="⚠ EMOTION DETECTED: The user appears frustrated (triggers: $EMOTION_TRIGGERS). Acknowledge their concern. Be extra careful with this task."
        else
            EMOTION_WARNING="Note: The user may be slightly frustrated (triggers: $EMOTION_TRIGGERS). Pay attention to their concern."
        fi
        if [[ -n "$CONTEXT_TEXT" ]]; then
            CONTEXT_TEXT="$CONTEXT_TEXT\n$EMOTION_WARNING"
        else
            CONTEXT_TEXT="$EMOTION_WARNING"
        fi
        _dbg "injected emotion warning"
    fi

    if [[ -n "$FORMATTED" ]]; then
        local MEMORY_SECTION="=== PROJECT MEMORY — If any memory below directly answers the user's question, cite it in your response ==="
        [[ -n "$CHANGE_NAME" ]] && MEMORY_SECTION="$MEMORY_SECTION\nChange: $CHANGE_NAME"
        MEMORY_SECTION="$MEMORY_SECTION\nRelevant past experience:\n$FORMATTED\n=== END ==="

        if [[ -n "$CONTEXT_TEXT" ]]; then
            CONTEXT_TEXT="$CONTEXT_TEXT\n$MEMORY_SECTION"
        else
            CONTEXT_TEXT="$MEMORY_SECTION"
        fi
    fi

    if [[ -z "$CONTEXT_TEXT" ]]; then
        _dbg "no output, exiting"
        local _dur; _dur=$(_metrics_timer_elapsed)
        _metrics_append "L2" "UserPromptSubmit" "${QUERY:0:200}" 0 0 "[]" "$_dur" 0 0 ""
        exit 0
    fi

    local _tok_est=$(( ${#CONTEXT_TEXT} / 4 ))
    local _dur; _dur=$(_metrics_timer_elapsed)
    local _scores; _scores=$(_extract_scores)
    local _res_count; _res_count=$(echo "$FORMATTED" | grep -c '^  - ' 2>/dev/null || echo 0)
    _metrics_append "L2" "UserPromptSubmit" "${QUERY:0:200}" "$_res_count" "$_res_count" "$_scores" "$_dur" "$_tok_est" 0 "$_LAST_CONTEXT_IDS"

    _dbg "=== OUTPUT ($(echo -e "$CONTEXT_TEXT" | wc -c) bytes) ==="
    output_hook_context "UserPromptSubmit" "$CONTEXT_TEXT"
}

# ============================================================
# Event: PreToolUse (disabled — memory recall removed)
# ============================================================

handle_pre_tool() {
    _dbg "PreToolUse disabled, exiting"
    exit 0
}

# ============================================================
# Helper: Write-save after file modifications
# ============================================================

_commit_save() {
    local SAVE_CONTENT KEY

    local py_tmp
    py_tmp=$(mktemp /tmp/wt-write-save.XXXXXX.py)
    cat > "$py_tmp" <<'WRITE_SAVE_PY'
import json, sys, re

data = json.load(open(sys.argv[1]))
ti = data.get('tool_input', {})
cmd = ti.get('command', '')
desc = ti.get('description', '')

# 1. Heredoc pattern: git commit -m "$(cat <<'EOF'\n message \n EOF)"
heredoc_m = re.search(r"cat\s*<<\s*['\"]?(\w+)['\"]?", cmd)
if heredoc_m:
    marker = heredoc_m.group(1)
    lines = cmd.split('\n')
    in_heredoc = False
    msg_lines = []
    for line in lines:
        if in_heredoc:
            stripped = line.strip()
            if stripped == marker or stripped in (f'{marker})', f"'{marker}'", f'{marker}"'):
                break
            if stripped and stripped not in (')', ')"', ")'"):
                msg_lines.append(stripped)
        elif re.search(r"cat\s*<<", line):
            in_heredoc = True
    if msg_lines:
        print(f'Committed: {msg_lines[0][:200]}')
        sys.exit(0)

# 2. Simple -m "message" or -m 'message'
q = chr(34) + chr(39)
m = re.search(r'git commit.*?-m\s+[' + q + r']([^' + q + r']+)[' + q + r']', cmd)
if m:
    print(f'Committed: {m.group(1)[:200]}')
    sys.exit(0)

# 3. Fallback to description
if desc:
    print(f'Committed: {desc[:200]}')
    sys.exit(0)

print('Committed: (message not parsed)')
WRITE_SAVE_PY
    SAVE_CONTENT=$(python3 "$py_tmp" "$INPUT_FILE" 2>/dev/null)
    rm -f "$py_tmp"

    [[ -z "$SAVE_CONTENT" ]] && { _dbg "write_save: empty content, skipping"; return 0; }

    # Dedup by commit content
    KEY=$(make_dedup_key "WriteSave" "commit" "$SAVE_CONTENT")
    if dedup_check "$KEY"; then
        _dbg "write_save: dedup hit"
        return 0
    fi

    echo "$SAVE_CONTENT" | wt-memory remember --type Learning --tags "phase:commit-save,source:hook" 2>/dev/null || true
    dedup_add "$KEY"
    _log "commit_save: ${SAVE_CONTENT:0:80}"
}

# ============================================================
# Event: PostToolUse (Read/Bash recall + commit save)
# ============================================================

handle_post_tool() {
    _metrics_timer_start
    local TOOL_NAME
    TOOL_NAME=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('tool_name',''))" 2>/dev/null)
    _dbg "tool=$TOOL_NAME"

    # Only Read and Bash are in scope
    if [[ "$TOOL_NAME" != "Read" && "$TOOL_NAME" != "Bash" ]]; then
        _dbg "tool=$TOOL_NAME not in scope, exiting"
        exit 0
    fi

    # Bash → check for git commit (save commit message as memory)
    if [[ "$TOOL_NAME" == "Bash" ]]; then
        local BASH_CMD
        BASH_CMD=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('tool_input',{}).get('command','')[:300])" 2>/dev/null)
        if [[ "$BASH_CMD" == *"git commit"* ]]; then
            _commit_save
        fi
    fi

    local QUERY
    QUERY=$(extract_query)
    if [[ -z "$QUERY" ]]; then
        _dbg "empty query, exiting"
        exit 0
    fi

    # Recall with dedup check
    local KEY
    KEY=$(make_dedup_key "PostToolUse" "$TOOL_NAME" "$QUERY")
    if dedup_check "$KEY"; then
        _dbg "dedup hit, exiting"
        local _dur; _dur=$(_metrics_timer_elapsed)
        _metrics_append "L3" "PostToolUse" "${QUERY:0:200}" 0 0 "[]" "$_dur" 0 1 ""
        exit 0
    fi

    local FORMATTED=""
    FORMATTED=$(recall_and_format "$QUERY" 2 hybrid) || true
    if [[ -z "$FORMATTED" ]]; then
        _dbg "no recall results, exiting"
        local _dur; _dur=$(_metrics_timer_elapsed)
        local _scores; _scores=$(_extract_scores)
        _metrics_append "L3" "PostToolUse" "${QUERY:0:200}" 0 0 "$_scores" "$_dur" 0 0 ""
        exit 0
    fi

    dedup_add "$KEY"
    local _output_text="=== MEMORY: Context for this file/command ===\n$FORMATTED"
    local _tok_est=$(( ${#_output_text} / 4 ))
    local _dur; _dur=$(_metrics_timer_elapsed)
    local _scores; _scores=$(_extract_scores)
    local _res_count; _res_count=$(echo "$FORMATTED" | grep -c '^  - ' 2>/dev/null || echo 0)
    _metrics_append "L3" "PostToolUse" "${QUERY:0:200}" "$_res_count" "$_res_count" "$_scores" "$_dur" "$_tok_est" 0 "$_LAST_CONTEXT_IDS"

    _dbg "=== OUTPUT ==="
    output_hook_context "PostToolUse" "$_output_text"
}

# ============================================================
# Event: PostToolUseFailure (error recall)
# ============================================================

handle_post_tool_failure() {
    _metrics_timer_start
    local PARSED
    PARSED=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
is_int = str(data.get('is_interrupt', False))
error = data.get('error', '')
print(f'{is_int}')
print(error[:300])
" "$INPUT_FILE" 2>/dev/null)

    local IS_INTERRUPT ERROR_TEXT
    IS_INTERRUPT=$(echo "$PARSED" | head -1)
    ERROR_TEXT=$(echo "$PARSED" | tail -n +2)

    _dbg "is_interrupt=$IS_INTERRUPT error='${ERROR_TEXT:0:80}'"

    if [[ "$IS_INTERRUPT" == "True" || "$IS_INTERRUPT" == "true" ]]; then
        _dbg "interrupt, exiting"
        exit 0
    fi
    if [[ ${#ERROR_TEXT} -lt 10 ]]; then
        _dbg "error too short (${#ERROR_TEXT} chars), exiting"
        exit 0
    fi

    local FORMATTED=""
    FORMATTED=$(recall_and_format "$ERROR_TEXT" 3 hybrid) || true
    if [[ -z "$FORMATTED" ]]; then
        _dbg "no recall results for error, exiting"
        local _dur; _dur=$(_metrics_timer_elapsed)
        local _scores; _scores=$(_extract_scores)
        _metrics_append "L4" "PostToolUseFailure" "${ERROR_TEXT:0:200}" 0 0 "$_scores" "$_dur" 0 0 ""
        exit 0
    fi

    local _output_text="=== MEMORY: Past fix for this error ===\n$FORMATTED"
    local _tok_est=$(( ${#_output_text} / 4 ))
    local _dur; _dur=$(_metrics_timer_elapsed)
    local _scores; _scores=$(_extract_scores)
    local _res_count; _res_count=$(echo "$FORMATTED" | grep -c '^  - ' 2>/dev/null || echo 0)
    _metrics_append "L4" "PostToolUseFailure" "${ERROR_TEXT:0:200}" "$_res_count" "$_res_count" "$_scores" "$_dur" "$_tok_est" 0 "$_LAST_CONTEXT_IDS"

    _dbg "=== OUTPUT ==="
    output_hook_context "PostToolUseFailure" "$_output_text"
}

# ============================================================
# Event: SubagentStart
# ============================================================

handle_subagent_start() {
    # Extract task description from SubagentStart input
    local TASK_DESC
    TASK_DESC=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
# SubagentStart provides task description in tool_input.prompt or tool_input.description
ti = data.get('tool_input', {})
desc = ti.get('prompt', '') or ti.get('description', '') or ''
print(desc[:300])
" "$INPUT_FILE" 2>/dev/null)
    _dbg "subagent_task='${TASK_DESC:0:100}'"
    if [[ -z "$TASK_DESC" ]]; then
        _dbg "no task description, exiting"
        exit 0
    fi

    # Proactive recall based on task description
    local FORMATTED=""
    FORMATTED=$(proactive_and_format "$TASK_DESC" 3) || true
    if [[ -z "$FORMATTED" ]]; then
        _dbg "no proactive results, exiting"
        exit 0
    fi

    _dbg "=== OUTPUT ==="
    output_hook_context "SubagentStart" "=== MEMORY: Context for subagent ===\n$FORMATTED"
}

# ============================================================
# Event: SubagentStop
# ============================================================

handle_subagent_stop() {
    local AGENT_PATH
    AGENT_PATH=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('agent_transcript_path',''))" 2>/dev/null)
    _dbg "agent_path='$AGENT_PATH'"
    if [[ -z "$AGENT_PATH" ]]; then
        _dbg "no agent path, exiting"
        exit 0
    fi

    # Expand ~ in path
    AGENT_PATH="${AGENT_PATH/#\~/$HOME}"
    if [[ ! -f "$AGENT_PATH" ]]; then
        _dbg "agent transcript not found: $AGENT_PATH"
        exit 0
    fi

    # Extract last few assistant text entries as query
    local SUMMARY
    SUMMARY=$(python3 -c "
import json, sys
entries = []
try:
    with open(sys.argv[1]) as f:
        for line in f:
            try:
                obj = json.loads(line)
                if obj.get('type') == 'assistant':
                    for block in (obj.get('message',{}).get('content',[]) or []):
                        if isinstance(block, dict) and block.get('type') == 'text':
                            entries.append(block.get('text','')[:200])
            except: pass
except: pass
print(' '.join(entries[-3:])[:500])
" "$AGENT_PATH" 2>/dev/null)
    _dbg "summary='${SUMMARY:0:100}'"
    if [[ -z "$SUMMARY" ]]; then
        _dbg "empty summary, exiting"
        exit 0
    fi

    local FORMATTED=""
    FORMATTED=$(proactive_and_format "$SUMMARY" 2) || true
    if [[ -z "$FORMATTED" ]]; then
        _dbg "no proactive results, exiting"
        exit 0
    fi

    _dbg "=== OUTPUT ==="
    output_hook_context "SubagentStop" "=== MEMORY: Context from subagent ===\n$FORMATTED"
}

# ============================================================
# Event: Stop (transcript extraction + commit-based extraction)
# ============================================================

handle_stop() {
    local STOP_ACTIVE
    STOP_ACTIVE=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('stop_hook_active',False))" 2>/dev/null)
    _dbg "stop_active=$STOP_ACTIVE"
    if [[ "$STOP_ACTIVE" == "True" || "$STOP_ACTIVE" == "true" ]]; then
        _dbg "stop hook already active, exiting"
        exit 0
    fi

    # Check for Ralph loop no-op marker — skip memory extraction if present and fresh
    local noop_marker=".claude/loop-iteration-noop"
    if [[ -f "$noop_marker" ]]; then
        local marker_ts
        marker_ts=$(cat "$noop_marker" 2>/dev/null)
        local marker_epoch now_epoch age_secs
        marker_epoch=$(date -d "$marker_ts" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        age_secs=$((now_epoch - marker_epoch))
        if [[ "$marker_epoch" -gt 0 && "$age_secs" -lt 3600 ]]; then
            _log "Skipping memory save — no-op loop iteration (age: ${age_secs}s)"
            rm -f "$noop_marker"
            # Still flush metrics (lightweight), but skip transcript/commit extraction
            _stop_flush_metrics
            dedup_clear
            exit 0
        fi
        # Stale marker (>1 hour) — ignore and proceed normally
        _dbg "no-op marker stale (${age_secs}s), proceeding normally"
        rm -f "$noop_marker"
    fi

    # Flush metrics to SQLite before clearing dedup cache
    _stop_flush_metrics

    # Clear metrics from cache (already flushed) to avoid double-flush on continued sessions
    python3 -c "
import json, sys, os
cf = sys.argv[1]
if not os.path.exists(cf): sys.exit(0)
try:
    with open(cf) as f: cache = json.load(f)
except: sys.exit(0)
cache.pop('_metrics', None)
with open(cf, 'w') as f: json.dump(cache, f)
" "$CACHE_FILE" 2>/dev/null || true

    # Clean up dedup cache (preserves turn_count, frustration_history)
    dedup_clear

    local TRANSCRIPT_PATH
    TRANSCRIPT_PATH=$(python3 -c "import json; print(json.load(open('$INPUT_FILE')).get('transcript_path',''))" 2>/dev/null)
    TRANSCRIPT_PATH="${TRANSCRIPT_PATH/#\~/$HOME}"
    _dbg "transcript='$TRANSCRIPT_PATH'"

    mkdir -p .wt-tools

    # Clean up RocksDB LOG.old files (once per session, before extraction)
    wt-memory cleanup-logs 2>/dev/null || true

    # Background transcript extraction
    if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
        _dbg "launching background extraction"
        _stop_run_extraction_bg "$TRANSCRIPT_PATH" &
        disown
    else
        _dbg "no transcript file, skipping extraction"
    fi

    # Synchronous: commit-based extraction
    _dbg "running commit extraction"
    _stop_commit_extraction
    _dbg "=== DONE ==="
}

# --- Stop: Flush metrics to SQLite ---
