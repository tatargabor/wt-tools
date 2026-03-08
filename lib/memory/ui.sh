#!/usr/bin/env bash
# wt-memory UI: metrics, tui, dashboard, seed
# Dependencies: sourced by bin/wt-memory after infra setup
# Requires: _wt_memory_bin_dir, SHODH_PYTHON, run_with_lock, run_shodh_python — set by bin/wt-memory

cmd_metrics() {
    local since_days=7
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --enable)
                local py
                py=$(find_python)
                "$py" -c "
import sys
sys.path.insert(0, '$_wt_memory_bin_dir/..')
from lib.metrics import enable
enable()
print('Metrics collection enabled.')
print('Injection data will be recorded in session caches and flushed to SQLite on session end.')
"
                return 0
                ;;
            --disable)
                local py
                py=$(find_python)
                "$py" -c "
import sys
sys.path.insert(0, '$_wt_memory_bin_dir/..')
from lib.metrics import disable
disable()
print('Metrics collection disabled.')
"
                return 0
                ;;
            --since)
                shift
                since_days="${1%d}"  # strip trailing 'd' if present
                shift
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    local py
    py=$(find_python)
    "$py" -c "
import sys, json
sys.path.insert(0, '$_wt_memory_bin_dir/..')
from lib.metrics import query_report, format_tui_report, is_enabled

data = query_report(since_days=$since_days)

if data is None:
    if not is_enabled():
        print('Metrics collection is disabled.')
        print('Enable with: wt-memory metrics --enable')
    else:
        print('No metrics data yet. Data is collected after sessions end.')
    sys.exit(0)

if $([[ "$json_output" == "true" ]] && echo "True" || echo "False"):
    print(json.dumps(data, indent=2))
else:
    print(format_tui_report(data))
"
}

cmd_tui() {
    local since_days=7
    local json_output=false
    local live_mode=true
    local poll_interval=10
    local tui_project=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --since)
                shift
                since_days="${1%d}"
                shift
                ;;
            --json)
                json_output=true
                live_mode=false
                shift
                ;;
            --once)
                live_mode=false
                shift
                ;;
            --interval)
                shift
                poll_interval="$1"
                shift
                ;;
            --project)
                shift
                tui_project="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    # Auto-detect project from global --project flag or git root
    if [[ -z "$tui_project" && -n "$PROJECT" ]]; then
        tui_project="$PROJECT"
    fi
    if [[ -z "$tui_project" ]]; then
        tui_project=$(git -C "$(pwd)" rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || true)
    fi

    local py
    py=$(find_python)

    _tui_render() {
        "$py" -c "
import sys, json, os, subprocess
from datetime import datetime
sys.path.insert(0, '$_wt_memory_bin_dir/..')
from lib.metrics import query_report, is_enabled

json_mode = $( [[ "$json_output" == "true" ]] && echo "True" || echo "False" )
live_mode = $( [[ "$live_mode" == "true" ]] && echo "True" || echo "False" )
since_days = $since_days
project_filter = '$tui_project' or None

# ANSI colors
use_color = sys.stdout.isatty()
if use_color:
    BOLD = '\033[1m'
    DIM  = '\033[2m'
    RST  = '\033[0m'
    CYN  = '\033[36m'
    GRN  = '\033[32m'
    YEL  = '\033[33m'
    RED  = '\033[31m'
    BLU  = '\033[34m'
    MAG  = '\033[35m'
    WHT  = '\033[37m'
else:
    BOLD = DIM = RST = CYN = GRN = YEL = RED = BLU = MAG = WHT = ''

# --- Gather data ---
mem_stats = None
try:
    cmd = ['wt-memory', 'stats', '--json']
    if project_filter:
        cmd = ['wt-memory', '--project', project_filter, 'stats', '--json']
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        mem_stats = json.loads(result.stdout)
except Exception:
    pass

report = query_report(since_days=since_days, project=project_filter)

# --- JSON output ---
if json_mode:
    output = {
        'memory_db': mem_stats,
        'hook_metrics': report,
        'since_days': since_days,
        'project': project_filter,
    }
    print(json.dumps(output, indent=2))
    sys.exit(0)

# --- Detect terminal width ---
try:
    term_width = os.get_terminal_size().columns
except Exception:
    term_width = int(os.environ.get('COLUMNS', '160'))
wide_mode = term_width >= 120

# --- Helper: strip ANSI for length calculation ---
import re
_ansi_re = re.compile(r'\033\[[0-9;]*m')
def visible_len(s):
    return len(_ansi_re.sub('', s))

def pad(s, width):
    \"\"\"Pad string to width accounting for ANSI codes.\"\"\"
    return s + ' ' * max(0, width - visible_len(s))

def sparkline(values, color=WHT):
    if not values:
        return ''
    mn, mx = min(values), max(values)
    rng = mx - mn if mx > mn else 1
    chars = ' ▁▂▃▄▅▆▇█'
    return color + ''.join(chars[min(8, int((v - mn) / rng * 8))] for v in values) + RST

def shorten_project(name, base):
    \"\"\"Strip base project prefix for worktree display.\"\"\"
    if not base or name == base:
        return '(main)'
    prefix = base + '-'
    if name.startswith(prefix):
        short = name[len(prefix):]
    else:
        short = name
    if len(short) > 22:
        short = short[:20] + '..'
    return short

def fmt_count(n):
    \"\"\"Format large numbers compactly: 16932 -> 16.9K\"\"\"
    if n >= 10000:
        return f'{n/1000:.1f}K'
    if n >= 1000:
        return f'{n:,}'
    return str(n)

# --- Build header ---
proj_label = project_filter if project_filter else 'all projects'
now = datetime.now().strftime('%H:%M:%S')

if not wide_mode:
    # === NARROW LAYOUT (< 120 cols) — original single-column ===
    lines = []
    title = f'  Memory Dashboard — {proj_label}'
    lines.append(f'{BOLD}{CYN}{title}{RST}  {DIM}(last {since_days}d, updated {now}){RST}')
    sep = '━' * min(66, term_width - 2)
    lines.append(f'{CYN}{sep}{RST}')
    lines.append('')

    # Memory Database
    lines.append(f'  {BOLD}{BLU}MEMORY DATABASE{RST}')
    if mem_stats:
        total = mem_stats.get('total', mem_stats.get('total_memories', 0))
        noise_raw = mem_stats.get('noise_ratio', 0)
        try:
            noise_val = float(noise_raw) if not isinstance(noise_raw, str) else float(noise_raw.rstrip('%'))
        except (ValueError, TypeError):
            noise_val = 0
        noise_color = GRN if noise_val < 15 else (YEL if noise_val < 30 else RED)
        types = mem_stats.get('type_distribution', {})
        type_parts = []
        for t, clr in [('Learning', GRN), ('Context', BLU), ('Decision', MAG)]:
            c = types.get(t, 0)
            if c > 0:
                type_parts.append(f'{clr}{t}: {c}{RST}')
        lines.append(f'  {BOLD}{total}{RST} memories    Noise: {noise_color}{noise_val:.0f}%{RST}    {\"  \".join(type_parts)}')
    else:
        lines.append(f'  {DIM}Memory DB: unavailable{RST}')
    lines.append('')

    if not report:
        if not is_enabled():
            lines.append(f'  {YEL}No metrics data. Enable with: wt-memory metrics --enable{RST}')
        else:
            lines.append(f'  {DIM}No metrics data yet.{RST}')
        if live_mode:
            lines.append(f'{DIM}  Refreshing every $poll_interval seconds... (Ctrl+C to exit){RST}')
        print('\n'.join(lines))
        sys.exit(0)

    # Hook Overhead
    lines.append(f'  {BOLD}{BLU}HOOK OVERHEAD{RST}')
    sessions_cnt = report['session_count']
    tokens = report['total_tokens']
    lines.append(f'  Sessions: {BOLD}{sessions_cnt}{RST}    Tokens: {BOLD}{tokens:,}{RST}')
    avg_tok = tokens / sessions_cnt if sessions_cnt > 0 else 0
    budget_pct = avg_tok / 200000 * 100
    budget_color = GRN if budget_pct < 3 else (YEL if budget_pct < 5 else RED)
    lines.append(f'  Avg/session: {avg_tok:,.0f} tok    Budget: {budget_color}{budget_pct:.2f}%{RST}')
    lines.append('')

    # Usage Signals
    lines.append(f'  {BOLD}{BLU}USAGE SIGNALS{RST}')
    usage_rate = report.get('usage_rate')
    if usage_rate is not None:
        u_color = GRN if usage_rate >= 30 else (YEL if usage_rate >= 10 else RED)
        lines.append(f'  Usage rate:    {u_color}{BOLD}{usage_rate:>5.1f}%{RST}')
    else:
        lines.append(f'  Usage rate:    {DIM}N/A{RST}')
    lines.append(f'  Cites:  {report[\"citation_rate\"]:>5.1f}%    Dedup: {report[\"dedup_rate\"]:>5.1f}%    Empty: {report[\"empty_rate\"]:>5.1f}%')
    lines.append('')

    if live_mode:
        lines.append(f'{DIM}  Refreshing every $poll_interval seconds... (Ctrl+C to exit){RST}')
    print('\n'.join(lines))
    sys.exit(0)

# === WIDE LAYOUT (>= 120 cols) — 3-column ===

# Column widths: distribute available space
sep_chars = 4  # 2 separators with padding
col_total = term_width - sep_chars
col_l = max(44, col_total * 30 // 100)
col_c = max(44, col_total * 34 // 100)
col_r = col_total - col_l - col_c

# --- Build LEFT column ---
left = []
left.append(f'{BOLD}{BLU}DATABASE{RST}')
if mem_stats:
    total = mem_stats.get('total', mem_stats.get('total_memories', 0))
    noise_raw = mem_stats.get('noise_ratio', 0)
    try:
        noise_val = float(noise_raw) if not isinstance(noise_raw, str) else float(noise_raw.rstrip('%'))
    except (ValueError, TypeError):
        noise_val = 0
    noise_color = GRN if noise_val < 15 else (YEL if noise_val < 30 else RED)
    types = mem_stats.get('type_distribution', {})
    left.append(f'{BOLD}{total}{RST} memories  Noise: {noise_color}{noise_val:.0f}%{RST}')
    type_parts = []
    for t, clr in [('L', GRN), ('C', BLU), ('D', MAG)]:
        full = {'L': 'Learning', 'C': 'Context', 'D': 'Decision'}[t]
        c = types.get(full, 0)
        if c > 0:
            type_parts.append(f'{clr}{t}:{c}{RST}')
    left.append('  '.join(type_parts))
    tags = mem_stats.get('tag_distribution', mem_stats.get('top_tags', {}))
    if tags:
        tag_items = list(tags.items())[:4]
        for k, v in tag_items:
            # Shorten long tag names
            short_k = k if len(k) <= col_l - 8 else k[:col_l - 11] + '..'
            left.append(f'{DIM}{short_k}: {v}{RST}')
else:
    left.append(f'{DIM}unavailable{RST}')
left.append('')

# Usage Signals
left.append(f'{BOLD}{BLU}USAGE SIGNALS{RST}')
if report:
    usage_rate = report.get('usage_rate')
    inj_ids = report.get('total_injected_ids', 0)
    mat_ids = report.get('total_matched_ids', 0)
    if usage_rate is not None:
        u_color = GRN if usage_rate >= 30 else (YEL if usage_rate >= 10 else RED)
        left.append(f'Usage:  {u_color}{BOLD}{usage_rate:>5.1f}%{RST} ({mat_ids}/{inj_ids})')
    else:
        left.append(f'Usage:  {DIM}N/A{RST}')
    cite_rate = report['citation_rate']
    c_color = GRN if cite_rate >= 2 else (YEL if cite_rate >= 0.5 else DIM)
    left.append(f'Cites:  {c_color}{cite_rate:>5.1f}%{RST} ({report[\"total_citations\"]})')
    dedup_rate = report['dedup_rate']
    d_color = GRN if dedup_rate >= 10 else DIM
    left.append(f'Dedup:  {d_color}{dedup_rate:>5.1f}%{RST} ({report[\"dedup_hits\"]})')
    empty_rate = report['empty_rate']
    e_color = GRN if empty_rate < 5 else (YEL if empty_rate < 15 else RED)
    left.append(f'Empty:  {e_color}{empty_rate:>5.1f}%{RST} ({report[\"empty_count\"]})')
    left.append('')

    # Relevance histogram
    rel = report.get('relevance', {})
    total_rel = rel.get('strong', 0) + rel.get('partial', 0) + rel.get('weak', 0)
    if total_rel > 0:
        left.append(f'{BOLD}{BLU}RELEVANCE{RST}')
        bar_max = col_l - 22
        for label, key, bar_color in [('strong', 'strong', GRN), ('partial', 'partial', YEL), ('weak', 'weak', RED)]:
            val = rel.get(key, 0)
            pct = val / total_rel * 100
            bar_len = int(pct / 100 * bar_max)
            filled = '█' * bar_len
            dots = '·' * (bar_max - bar_len)
            left.append(f'{label:<8} {bar_color}{filled}{RST}{dots} {pct:>4.0f}%')
else:
    if not is_enabled():
        left.append(f'{YEL}No data. Enable with:{RST}')
        left.append(f'wt-memory metrics --enable')
    else:
        left.append(f'{DIM}No metrics data yet.{RST}')

# --- Build CENTER column ---
center = []
if report:
    center.append(f'{BOLD}{BLU}HOOK OVERHEAD{RST}')
    sessions_cnt = report['session_count']
    injections = report['total_injections']
    tokens = report['total_tokens']
    center.append(f'{BOLD}{sessions_cnt}{RST} sessions  {BOLD}{fmt_count(injections)}{RST} inj')
    avg_tok = tokens / sessions_cnt if sessions_cnt > 0 else 0
    budget_pct = avg_tok / 200000 * 100
    budget_color = GRN if budget_pct < 3 else (YEL if budget_pct < 5 else RED)
    center.append(f'{BOLD}{tokens:,}{RST} tok  Avg: {avg_tok:,.0f}/sess')
    center.append(f'Budget: {budget_color}{budget_pct:.2f}%{RST}')
    center.append('')

    # Layer table
    center.append(f'{BOLD}{BLU}LAYERS{RST}')
    center.append(f'{DIM}Name       Count  Avg tok  Avg rel{RST}')
    for layer in report.get('layers', []):
        avg_rel = layer.get('avg_rel', 0)
        layer_name = layer['layer']
        cnt = layer['cnt']
        a_tok = layer['avg_tok']
        rel_color = GRN if avg_rel >= 0.5 else (YEL if avg_rel >= 0.3 else (RED if avg_rel > 0 else DIM))
        center.append(
            f'{CYN}{layer_name:<10}{RST} {fmt_count(cnt):>5}x {a_tok:>7.0f}  {rel_color}{avg_rel:>6.2f}{RST}'
        )
    center.append('')

    # Daily Trend (sparklines)
    daily_tokens = report.get('daily_tokens', [])
    daily_relevance = report.get('daily_relevance', [])
    if len(daily_tokens) >= 3:
        center.append(f'{BOLD}{BLU}DAILY TREND{RST}')
        tok_values = [d['tokens'] for d in daily_tokens]
        tok_spark = sparkline(tok_values, CYN)
        center.append(f'tok {tok_spark}')
        center.append(f'    {DIM}({fmt_count(min(tok_values))} — {fmt_count(max(tok_values))}){RST}')
        if daily_relevance:
            rel_values = [d['avg_relevance'] for d in daily_relevance]
            rel_spark = sparkline(rel_values, GRN)
            center.append(f'rel {rel_spark}')
            center.append(f'    {DIM}({min(rel_values):.3f} — {max(rel_values):.3f}){RST}')

# --- Build RIGHT column (session list) ---
right = []
if report:
    sess_list = report.get('sessions', [])[:15]
    right.append(f'{BOLD}{BLU}RECENT SESSIONS{RST} ({report[\"session_count\"]})')
    right.append(f'{DIM}Date        Worktree              Inj   Tokens  C{RST}')
    wt_max = max(12, col_r - 38)
    for s in sess_list:
        ended = s.get('ended_at', '')
        try:
            dt = datetime.fromisoformat(ended.replace('Z', '+00:00'))
            date_str = dt.strftime('%m-%d %H:%M')
        except Exception:
            date_str = ended[:10] if ended else '?'
        wt_name = shorten_project(s.get('project', ''), project_filter)
        if len(wt_name) > wt_max:
            wt_name = wt_name[:wt_max - 2] + '..'
        inj = s.get('total_injections', 0)
        tok = s.get('total_tokens', 0)
        cit = s.get('citation_count', 0)
        cit_str = f'{CYN}{cit}{RST}' if cit > 0 else f'{DIM}{cit}{RST}'
        right.append(f'{date_str}  {wt_name:<{wt_max}}  {inj:>3}  {fmt_count(tok):>7}  {cit_str}')

# --- Merge columns into output ---
# Ensure all columns have the same number of rows
max_rows = max(len(left), len(center), len(right))
while len(left) < max_rows:
    left.append('')
while len(center) < max_rows:
    center.append('')
while len(right) < max_rows:
    right.append('')

# Header
header_text = f' Memory Dashboard — {proj_label}'
header_right = f'last {since_days}d, updated {now} '
header_pad = term_width - len(header_text) - len(header_right) - 2
header = f'{BOLD}{CYN}┌{\"─\" * (term_width - 2)}┐{RST}'
header_content = f'{BOLD}{CYN}│{RST}{BOLD}{CYN}{header_text}{RST}{\" \" * max(1, header_pad)}{DIM}{header_right}{RST}{BOLD}{CYN}│{RST}'
header_sep = f'{CYN}├{\"─\" * col_l}┬{\"─\" * (col_c + 2)}┬{\"─\" * col_r}┤{RST}'

output_lines = [header, header_content, header_sep]

for i in range(max_rows):
    l = pad(f' {left[i]}', col_l)
    c = pad(f' {center[i]}', col_c + 2)
    r = pad(f' {right[i]}', col_r)
    output_lines.append(f'{CYN}│{RST}{l}{CYN}│{RST}{c}{CYN}│{RST}{r}{CYN}│{RST}')

# Footer
footer = f'{CYN}└{\"─\" * col_l}┴{\"─\" * (col_c + 2)}┴{\"─\" * col_r}┘{RST}'
output_lines.append(footer)

if live_mode:
    output_lines.append(f'{DIM} Refreshing every $poll_interval seconds... (Ctrl+C to exit){RST}')

print('\n'.join(output_lines))
"
    }

    if [[ "$json_output" == "true" ]]; then
        _tui_render
        return 0
    fi

    if [[ "$live_mode" == "true" ]]; then
        trap 'printf "\033[?25h"; exit 0' INT TERM
        printf "\033[?25h"  # ensure cursor visible on exit
        while true; do
            clear
            _tui_render
            sleep "$poll_interval"
        done
    else
        _tui_render
    fi
}

cmd_dashboard() {
    local since_days=30

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --since)
                shift
                since_days="${1%d}"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    local py
    py=$(find_python)
    local html_file="/tmp/wt-memory-dashboard.html"

    "$py" -c "
import sys, json, os
sys.path.insert(0, '$_wt_memory_bin_dir/..')
from lib.metrics import query_report, query_session_injections, is_enabled
from lib.dashboard import generate_dashboard

data = query_report(since_days=$since_days)
if data is None:
    if not is_enabled():
        print('Metrics collection is disabled. Enable with: wt-memory metrics --enable')
    else:
        print('No metrics data yet.')
    sys.exit(0)

# Enrich with per-session injection details for drill-down
for session in data.get('sessions', []):
    session['injections'] = query_session_injections(session['id'])

html = generate_dashboard(data)
with open('$html_file', 'w') as f:
    f.write(html)
print(f'Dashboard written to: $html_file')
"

    # Open in browser
    if [[ -f "$html_file" ]]; then
        if command -v xdg-open &>/dev/null; then
            xdg-open "$html_file" 2>/dev/null &
        elif command -v open &>/dev/null; then
            open "$html_file" 2>/dev/null &
        else
            echo "Open in browser: $html_file"
        fi
    fi
}

# Import memory seeds from wt/knowledge/memory-seed.yaml.
# Uses content-hash duplicate detection to avoid re-importing existing memories.
cmd_seed() {
    local seed_file="wt/knowledge/memory-seed.yaml"
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) seed_file="$2"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -h|--help)
                echo "Usage: wt-memory seed [--file <path>] [--dry-run]"
                echo "Import memory seeds from wt/knowledge/memory-seed.yaml"
                return 0
                ;;
            *) shift ;;
        esac
    done

    if [[ ! -f "$seed_file" ]]; then
        echo "Error: Seed file not found: $seed_file" >&2
        return 1
    fi

    # Parse seeds from YAML
    if ! command -v yq &>/dev/null; then
        echo "Error: yq is required for seed import" >&2
        return 1
    fi

    local seed_count
    seed_count=$(yq -r '.seeds | length // 0' "$seed_file" 2>/dev/null)
    if [[ "$seed_count" -eq 0 ]]; then
        echo "No seeds found in $seed_file"
        return 0
    fi

    local imported=0
    local skipped=0

    for i in $(seq 0 $((seed_count - 1))); do
        local content type tags
        content=$(yq -r ".seeds[$i].content // empty" "$seed_file" 2>/dev/null)
        type=$(yq -r ".seeds[$i].type // \"Context\"" "$seed_file" 2>/dev/null)
        tags=$(yq -r ".seeds[$i].tags // \"\"" "$seed_file" 2>/dev/null)

        [[ -z "$content" ]] && continue

        # Content-hash duplicate detection
        local content_hash
        content_hash=$(echo -n "$content" | sha256sum | cut -c1-16)

        # Check if a memory with this content already exists (search by hash prefix in content)
        local existing
        existing=$(cmd_recall "$content" --limit 1 --mode semantic 2>/dev/null | head -1 || true)

        # More precise: check if exact content exists
        local exact_match=false
        if [[ -n "$existing" ]]; then
            local existing_id
            existing_id=$(echo "$existing" | grep -oP '^[0-9a-f]+' || true)
            if [[ -n "$existing_id" ]]; then
                local existing_content
                existing_content=$(cmd_get "$existing_id" 2>/dev/null | grep -A999 "Content:" | tail -n+2 | head -5 || true)
                if [[ "$existing_content" == *"$content"* || "$content" == *"$existing_content"* ]]; then
                    exact_match=true
                fi
            fi
        fi

        if $exact_match; then
            skipped=$((skipped + 1))
            $dry_run && echo "  SKIP (duplicate): $content"
            continue
        fi

        # Append source:seed tag
        if [[ -n "$tags" ]]; then
            tags="$tags,source:seed"
        else
            tags="source:seed"
        fi

        if $dry_run; then
            echo "  IMPORT: [$type] $content (tags: $tags)"
        else
            echo "$content" | cmd_remember --type "$type" --tags "$tags" 2>/dev/null || true
        fi
        imported=$((imported + 1))
    done

    local verb="Imported"
    $dry_run && verb="Would import"
    echo "$verb $imported seed(s), skipped $skipped duplicate(s) from $seed_file"
}

# Main dispatch — parse global --project flag before command
