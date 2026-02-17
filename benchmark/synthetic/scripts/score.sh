#!/bin/bash
# score.sh — MemoryProbe convention scoring
# Usage: ./score.sh <project-dir> [--json] [--compare <dir-a> <dir-b>]

set -euo pipefail

# --- Parse args ---
JSON_MODE=false
COMPARE_MODE=false
PROJECT=""
COMPARE_A=""
COMPARE_B=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --compare) COMPARE_MODE=true; COMPARE_A="$2"; COMPARE_B="$3"; shift 3 ;;
    *) PROJECT="$1"; shift ;;
  esac
done

# --- Comparison mode ---
if $COMPARE_MODE; then
  echo "MemoryProbe Comparison"
  echo "======================"
  echo ""

  # Run scoring for both and parse
  SCORE_A=$("$0" "$COMPARE_A" --json)
  SCORE_B=$("$0" "$COMPARE_B" --json)

  python3 -c "
import json, sys

a = json.loads('''$SCORE_A''')
b = json.loads('''$SCORE_B''')

print(f\"{'':12s} {'Mode A':>8s}  {'Mode B':>8s}  {'Delta':>6s}\")

for trap in ['T1','T2','T3','T4','T5','T6']:
    ta = a['traps'].get(trap, {'pass':0,'total':0})
    tb = b['traps'].get(trap, {'pass':0,'total':0})
    delta = tb['pass'] - ta['pass']
    sign = '+' if delta > 0 else ''
    labels = {'T1':'paging','T2':'errors','T3':'remove','T4':'dates','T5':'IDs','T6':'ok wrap'}
    label = labels.get(trap, trap)
    print(f'{trap} {label:6s}   {ta[\"pass\"]}/{ta[\"total\"]:>2d}      {tb[\"pass\"]}/{tb[\"total\"]:>2d}     {sign}{delta}')

print('─' * 45)
da = a['score']['pass']; ta = a['score']['total']
db = b['score']['pass']; tb = b['score']['total']
delta = db - da
sign = '+' if delta > 0 else ''
print(f\"{'Total':12s}  {da}/{ta:>2d}      {db}/{tb:>2d}    {sign}{delta}\")
pa = a['score']['percent']; pb = b['score']['percent']
dp = pb - pa
sign = '+' if dp > 0 else ''
print(f\"{'Percent':12s}  {pa}%       {pb}%    {sign}{dp}%\")
"
  exit 0
fi

# --- Single project scoring ---
if [[ -z "$PROJECT" ]]; then
  echo "Usage: ./score.sh <project-dir> [--json]"
  echo "       ./score.sh --compare <dir-a> <dir-b>"
  exit 1
fi

PASS=0
FAIL=0
TOTAL=0
declare -a PROBES=()

# Find files flexibly — agent may name files differently
find_files() {
  local dir="$PROJECT/src"
  local pattern="$1"
  find "$dir" -name "*.js" -o -name "*.mjs" -o -name "*.ts" 2>/dev/null | grep -i "$pattern" || true
}

probe() {
  local trap="$1" change="$2" desc="$3"
  local pass_pattern="$4" fail_pattern="$5"
  local file_pattern="$6"

  TOTAL=$((TOTAL + 1))
  local found_pass=false
  local found_fail=false

  local files
  files=$(find_files "$file_pattern")

  if [[ -z "$files" ]]; then
    # File not found — FAIL
    FAIL=$((FAIL + 1))
    PROBES+=("{\"trap\":\"$trap\",\"change\":\"$change\",\"desc\":\"$desc\",\"result\":\"FAIL\",\"reason\":\"no matching files\"}")
    if ! $JSON_MODE; then
      echo "  FAIL  $trap  $change  $desc  (no files matching '$file_pattern')"
    fi
    return
  fi

  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    if grep -qE "$pass_pattern" "$f" 2>/dev/null; then
      found_pass=true
    fi
    if [[ -n "$fail_pattern" ]] && grep -qE "$fail_pattern" "$f" 2>/dev/null; then
      found_fail=true
    fi
  done <<< "$files"

  if $found_pass && ! $found_fail; then
    PASS=$((PASS + 1))
    PROBES+=("{\"trap\":\"$trap\",\"change\":\"$change\",\"desc\":\"$desc\",\"result\":\"PASS\"}")
    if ! $JSON_MODE; then
      echo "  PASS  $trap  $change  $desc"
    fi
  else
    FAIL=$((FAIL + 1))
    local reason="convention not found"
    $found_fail && reason="standard pattern detected"
    ! $found_pass && reason="project convention not found"
    PROBES+=("{\"trap\":\"$trap\",\"change\":\"$change\",\"desc\":\"$desc\",\"result\":\"FAIL\",\"reason\":\"$reason\"}")
    if ! $JSON_MODE; then
      echo "  FAIL  $trap  $change  $desc  ($reason)"
    fi
  fi
}

if ! $JSON_MODE; then
  echo ""
  echo "MemoryProbe Convention Scoring"
  echo "=============================="
  echo "Project: $PROJECT"
  echo ""
  echo "--- C03: Comments & Activity ---"
fi

# C03 probes (4)
probe T1 C03 "comment pagination"   '"paging"'    '"total"[[:space:]]*:|"limit"[[:space:]]*:'   "comment"
probe T2 C03 "comment errors"       '"fault"'     '"error"[[:space:]]*:|"message"[[:space:]]*:'  "comment"
probe T5 C03 "comment ID prefix"    'cmt_'        'AUTO_INCREMENT|autoincrement|\.uuid'          "comment"
probe T6 C03 "comment ok wrapper"   '"ok"'        ''                                             "comment"

if ! $JSON_MODE; then
  echo ""
  echo "--- C04: Dashboard & Export ---"
fi

# C04 probes (5)
probe T1 C04 "dashboard pagination" '"paging"'    '"total"[[:space:]]*:|"limit"[[:space:]]*:'   "dashboard"
probe T2 C04 "export errors"        '"fault"'     '"error"[[:space:]]*:|"message"[[:space:]]*:'  "export\|dashboard"
probe T3 C04 "notification remove"  'removedAt'   'deletedAt|isDeleted|is_deleted'               "dashboard\|notification"
probe T4 C04 "export date format"   'fmtDate'     'toISOString\|formatDate\|dayjs\|moment'       "export"
probe T6 C04 "dashboard ok wrapper" '"ok"'        ''                                             "dashboard\|export"

if ! $JSON_MODE; then
  echo ""
  echo "--- C05: Bulk Operations ---"
fi

# C05 probes (6)
probe T1 C05 "bulk pagination"      '"paging"'    '"total"[[:space:]]*:|"limit"[[:space:]]*:'   "bulk"
probe T2 C05 "bulk errors"          '"fault"'     '"error"[[:space:]]*:|"message"[[:space:]]*:'  "bulk"
probe T3 C05 "bulk soft-delete"     'removedAt'   'deletedAt|isDeleted|is_deleted'               "bulk\|event"
probe T4 C05 "bulk report dates"    'fmtDate'     'toISOString\|formatDate\|dayjs\|moment'       "bulk"
probe T5 C05 "batch ID prefix"      'bat_'        'AUTO_INCREMENT|autoincrement|\.uuid'          "bulk\|batch"
probe T6 C05 "bulk ok wrapper"      '"ok"'        ''                                             "bulk"

# --- Calculate per-trap scores ---
declare -A TRAP_PASS TRAP_TOTAL
for trap in T1 T2 T3 T4 T5 T6; do
  TRAP_PASS[$trap]=0
  TRAP_TOTAL[$trap]=0
done

for p in "${PROBES[@]}"; do
  trap=$(echo "$p" | python3 -c "import json,sys; print(json.load(sys.stdin)['trap'])")
  result=$(echo "$p" | python3 -c "import json,sys; print(json.load(sys.stdin)['result'])")
  TRAP_TOTAL[$trap]=$(( ${TRAP_TOTAL[$trap]} + 1 ))
  if [[ "$result" == "PASS" ]]; then
    TRAP_PASS[$trap]=$(( ${TRAP_PASS[$trap]} + 1 ))
  fi
done

# --- Output ---
if $JSON_MODE; then
  PERCENT=0
  if [[ $TOTAL -gt 0 ]]; then
    PERCENT=$(( PASS * 100 / TOTAL ))
  fi

  TRAP_JSON=""
  for trap in T1 T2 T3 T4 T5 T6; do
    [[ -n "$TRAP_JSON" ]] && TRAP_JSON+=","
    TRAP_JSON+="\"$trap\":{\"pass\":${TRAP_PASS[$trap]},\"total\":${TRAP_TOTAL[$trap]}}"
  done

  PROBE_JSON=$(printf '%s\n' "${PROBES[@]}" | paste -sd, -)

  echo "{\"score\":{\"pass\":$PASS,\"fail\":$FAIL,\"total\":$TOTAL,\"percent\":$PERCENT},\"traps\":{$TRAP_JSON},\"probes\":[$PROBE_JSON]}"
else
  echo ""
  echo "=============================="
  PERCENT=0
  if [[ $TOTAL -gt 0 ]]; then
    PERCENT=$(( PASS * 100 / TOTAL ))
  fi
  echo "MemoryProbe Score: $PASS/$TOTAL ($PERCENT%)"
  echo ""

  echo "Per-trap breakdown:"
  labels=("T1:paging" "T2:errors" "T3:remove" "T4:dates" "T5:IDs" "T6:ok-wrap")
  for entry in "${labels[@]}"; do
    trap="${entry%%:*}"
    label="${entry#*:}"
    printf "  %-10s %d/%d\n" "$trap ($label)" "${TRAP_PASS[$trap]}" "${TRAP_TOTAL[$trap]}"
  done

  # Save score to results
  echo "{\"pass\":$PASS,\"fail\":$FAIL,\"total\":$TOTAL,\"percent\":$PERCENT}" > "$PROJECT/results/score.json" 2>/dev/null || true
fi
