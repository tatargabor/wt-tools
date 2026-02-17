#!/bin/bash
# score.sh — MemoryProbe v8 convention scoring (weighted)
# Usage: ./score.sh <project-dir> [--json] [--compare <dir-a> <dir-b>]
#
# Trap categories:
#   A (code-readable, weight 1): T1, T3, T5
#   B (human override, weight 2): T2, T4, T6, T7, T8, T10
#   C (forward-looking, weight 3): T9

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

# --- Trap category definitions ---
# Category A: code-readable (weight 1) — visible in C01/C02 code
# Category B: code + memory nuance (weight 2) — base pattern in code, nuance in memory
# Category C: memory-only (weight 3) — only C02 Developer Notes carry this, code shows OLD pattern
declare -A TRAP_CAT
TRAP_CAT[T1]=A; TRAP_CAT[T2]=A; TRAP_CAT[T3]=A; TRAP_CAT[T5]=A; TRAP_CAT[T6]=A
TRAP_CAT[T4]=B
TRAP_CAT[T7]=C; TRAP_CAT[T8]=C; TRAP_CAT[T9]=C; TRAP_CAT[T10]=C

declare -A CAT_WEIGHT
CAT_WEIGHT[A]=1; CAT_WEIGHT[B]=2; CAT_WEIGHT[C]=3

# --- Comparison mode ---
if $COMPARE_MODE; then
  SCORE_A=$("$0" "$COMPARE_A" --json)
  SCORE_B=$("$0" "$COMPARE_B" --json)

  python3 -c "
import json, sys

a = json.loads('''$SCORE_A''')
b = json.loads('''$SCORE_B''')

cats = {
    'A': {'label': 'Code-readable', 'traps': ['T1','T2','T3','T5','T6'], 'weight': 1},
    'B': {'label': 'Code + memory nuance', 'traps': ['T4'], 'weight': 2},
    'C': {'label': 'Memory-only', 'traps': ['T7','T8','T9','T10'], 'weight': 3},
}

labels = {'T1':'paging','T2':'errors','T3':'remove','T4':'dates','T5':'IDs','T6':'ok wrap',
          'T7':'err.code','T8':'result-key','T9':'batch-POST','T10':'order'}

print('MemoryProbe v9 Comparison')
print('=' * 50)

for cat_id, cat in cats.items():
    print(f\"\\nCategory {cat_id} ({cat['label']}, weight x{cat['weight']}):\")
    print(f\"{'':14s} {'Mode A':>8s}  {'Mode B':>8s}  {'Delta':>6s}\")
    cat_a = 0; cat_b = 0; cat_t_a = 0; cat_t_b = 0
    for trap in cat['traps']:
        ta = a['traps'].get(trap, {'pass':0,'total':0})
        tb = b['traps'].get(trap, {'pass':0,'total':0})
        delta = tb['pass'] - ta['pass']
        sign = '+' if delta > 0 else ''
        label = labels.get(trap, trap)
        print(f'  {trap:4s} {label:10s} {ta[\"pass\"]}/{ta[\"total\"]:>2d}      {tb[\"pass\"]}/{tb[\"total\"]:>2d}     {sign}{delta}')
        cat_a += ta['pass']; cat_b += tb['pass']
        cat_t_a += ta['total']; cat_t_b += tb['total']
    delta = cat_b - cat_a
    sign = '+' if delta > 0 else ''
    print(f'  {\"Subtotal\":14s} {cat_a}/{cat_t_a:>2d}      {cat_b}/{cat_t_b:>2d}     {sign}{delta}')

print()
print('─' * 50)

wa = a.get('weightedScore', a['score'])
wb = b.get('weightedScore', b['score'])
da = wa.get('raw', wa.get('pass',0))
db = wb.get('raw', wb.get('pass',0))
ma = wa.get('max', wa.get('total',0))
mb = wb.get('max', wb.get('total',0))
pa = wa.get('percent', 0)
pb = wb.get('percent', 0)

delta_p = pb - pa
sign = '+' if delta_p > 0 else ''

print(f'Weighted Score:')
print(f'  Mode A:  {da}/{ma} ({pa}%)')
print(f'  Mode B:  {db}/{mb} ({pb}%)')
print(f'  Delta:   {sign}{delta_p}%')

# Also show unweighted for reference
ua = a['score']; ub = b['score']
print(f\"\\nUnweighted:  {ua['pass']}/{ua['total']} vs {ub['pass']}/{ub['total']}\")
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

# ===== CATEGORY A: Code-readable (weight 1) =====

if ! $JSON_MODE; then
  echo ""
  echo "MemoryProbe v9 Convention Scoring"
  echo "================================="
  echo "Project: $PROJECT"
  echo ""
  echo "=== Category A: Code-readable (weight x1) ==="
  echo ""
  echo "--- C03: Comments & Activity ---"
fi

# T1 probes (pagination: entries + paging)
probe T1 C03 "comment pagination"   'paging[[:space:]]*[:{]|"paging"'    'total[[:space:]]*:|"total"[[:space:]]*:|limit[[:space:]]*:|"limit"[[:space:]]*:'   "comment"
probe T1 C04 "dashboard pagination" 'paging[[:space:]]*[:{]|"paging"'    'total[[:space:]]*:|"total"[[:space:]]*:|limit[[:space:]]*:|"limit"[[:space:]]*:'   "dashboard"
probe T1 C05 "bulk pagination"      'paging[[:space:]]*[:{]|"paging"'    'total[[:space:]]*:|"total"[[:space:]]*:|limit[[:space:]]*:|"limit"[[:space:]]*:'   "bulk"

# T3 probes (soft-delete: removedAt)
probe T3 C04 "notification remove"  'removedAt'   'deletedAt|isDeleted|is_deleted'   "dashboard\|notification"
probe T3 C05 "bulk soft-delete"     'removedAt'   'deletedAt|isDeleted|is_deleted'   "bulk\|event"

# T2 probes (error format: fault wrapper — visible in C01 code)
probe T2 C03 "comment errors"       'fault[[:space:]]*[:{]|"fault"'     'error[[:space:]]*[:=].*message|"error"[[:space:]]*:|"message"[[:space:]]*:'  "comment\|error"
probe T2 C04 "export errors"        'fault[[:space:]]*[:{]|"fault"'     'error[[:space:]]*[:=].*message|"error"[[:space:]]*:|"message"[[:space:]]*:'  "export\|dashboard\|error"
probe T2 C05 "bulk errors"          'fault[[:space:]]*[:{]|"fault"'     'error[[:space:]]*[:=].*message|"error"[[:space:]]*:|"message"[[:space:]]*:'  "bulk\|error"

# T5 probes (prefixed IDs)
probe T5 C03 "comment ID prefix"    "cmt_|makeId.*['\"]cmt['\"]"   'AUTO_INCREMENT|autoincrement|\.uuid'   "comment\|id"
probe T5 C05 "batch ID prefix"      "bat_|makeId.*['\"]bat['\"]"   'AUTO_INCREMENT|autoincrement|\.uuid'   "bulk\|batch\|id"

# T6 probes (ok wrapper — visible in C01 code)
probe T6 C03 "comment ok wrapper"   'ok[[:space:]]*:[[:space:]]*true|"ok"[[:space:]]*:'   ''   "comment"
probe T6 C04 "dashboard ok wrapper" 'ok[[:space:]]*:[[:space:]]*true|"ok"[[:space:]]*:'   ''   "dashboard\|export"
probe T6 C05 "bulk ok wrapper"      'ok[[:space:]]*:[[:space:]]*true|"ok"[[:space:]]*:'   ''   "bulk"

# ===== CATEGORY B: Code + memory nuance (weight 2) =====

if ! $JSON_MODE; then
  echo ""
  echo "=== Category B: Code + memory nuance (weight x2) ==="
  echo ""
fi

# T4 probes (date format: fmtDate — base pattern in code, "ALL dates" nuance in memory)
probe T4 C04 "export date format"   'fmtDate'     'toISOString\|formatDate\|dayjs\|moment'   "export"
probe T4 C05 "bulk report dates"    'fmtDate'     'toISOString\|formatDate\|dayjs\|moment'   "bulk"

# ===== CATEGORY C: Memory-only (weight 3) =====

if ! $JSON_MODE; then
  echo ""
  echo "=== Category C: Memory-only (weight x3) ==="
  echo ""
fi

# T7 probes (error codes: dot.notation — C02 says "starting C03", code shows SCREAMING_SNAKE)
probe T7 C03 "comment err.code dot" "err\.code.*['\"][a-z]+\.[a-z_]+['\"]|code.*['\"][a-z]+\.[a-z_]+['\"]"   "err\.code.*['\"][A-Z]{2,}_[A-Z]"   "comment"
probe T7 C04 "export err.code dot"  "err\.code.*['\"][a-z]+\.[a-z_]+['\"]|code.*['\"][a-z]+\.[a-z_]+['\"]"   "err\.code.*['\"][A-Z]{2,}_[A-Z]"   "export\|dashboard"
probe T7 C05 "bulk err.code dot"    "err\.code.*['\"][a-z]+\.[a-z_]+['\"]|code.*['\"][a-z]+\.[a-z_]+['\"]"   "err\.code.*['\"][A-Z]{2,}_[A-Z]"   "bulk"

# T8 probes (response nesting: result key — C02 says "starting C03", code uses flat format)
probe T8 C03 "comment result key"   'result[[:space:]]*:[[:space:]]*\{'   ''   "comment"
probe T8 C04 "dashboard result key" 'result[[:space:]]*:[[:space:]]*\{'   ''   "dashboard"
probe T8 C05 "bulk result key"      'result[[:space:]]*:[[:space:]]*\{'   ''   "bulk"

# T9 probes (batch ops: POST body for IDs — forward-looking advice from C02)
# Handles both dot access (req.body.eventIds) and destructuring ({ eventIds } = req.body)
probe T9 C05 "batch POST body"    'req\.body\.\w*[Ii]ds|req\.body\.\w*[Ee]vent|\w*[Ii]ds.*=.*req\.body|=\s*req\.body'   'req\.query\.ids|req\.query\.\w*[Ii]ds'   "bulk"

# T10 probes (order parameter — C02 says use ?order=, no code implements this before C04)
probe T10 C04 "dashboard order param" 'req\.query\.order\b|order.*newest|order.*oldest'   'req\.query\.sort\b'   "dashboard\|activity"
probe T10 C05 "bulk order param"      'req\.query\.order\b|order.*newest|order.*oldest'   'req\.query\.sort\b'   "bulk"

# --- Calculate per-trap and per-category scores ---
ALL_TRAPS="T1 T2 T3 T4 T5 T6 T7 T8 T9 T10"
declare -A TRAP_PASS TRAP_TOTAL
for trap in $ALL_TRAPS; do
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

# Calculate weighted score
WEIGHTED_RAW=0
WEIGHTED_MAX=0
for trap in $ALL_TRAPS; do
  cat="${TRAP_CAT[$trap]}"
  w="${CAT_WEIGHT[$cat]}"
  WEIGHTED_RAW=$(( WEIGHTED_RAW + TRAP_PASS[$trap] * w ))
  WEIGHTED_MAX=$(( WEIGHTED_MAX + TRAP_TOTAL[$trap] * w ))
done

WEIGHTED_PERCENT=0
if [[ $WEIGHTED_MAX -gt 0 ]]; then
  WEIGHTED_PERCENT=$(( WEIGHTED_RAW * 100 / WEIGHTED_MAX ))
fi

# --- Output ---
if $JSON_MODE; then
  PERCENT=0
  if [[ $TOTAL -gt 0 ]]; then
    PERCENT=$(( PASS * 100 / TOTAL ))
  fi

  TRAP_JSON=""
  for trap in $ALL_TRAPS; do
    [[ -n "$TRAP_JSON" ]] && TRAP_JSON+=","
    TRAP_JSON+="\"$trap\":{\"pass\":${TRAP_PASS[$trap]},\"total\":${TRAP_TOTAL[$trap]}}"
  done

  # Category scores
  CAT_JSON=""
  for cat in A B C; do
    [[ -n "$CAT_JSON" ]] && CAT_JSON+=","
    cat_pass=0; cat_total=0
    for trap in $ALL_TRAPS; do
      if [[ "${TRAP_CAT[$trap]}" == "$cat" ]]; then
        cat_pass=$(( cat_pass + TRAP_PASS[$trap] ))
        cat_total=$(( cat_total + TRAP_TOTAL[$trap] ))
      fi
    done
    CAT_JSON+="\"$cat\":{\"weight\":${CAT_WEIGHT[$cat]},\"pass\":$cat_pass,\"total\":$cat_total}"
  done

  PROBE_JSON=$(printf '%s\n' "${PROBES[@]}" | paste -sd, -)

  echo "{\"score\":{\"pass\":$PASS,\"fail\":$FAIL,\"total\":$TOTAL,\"percent\":$PERCENT},\"weightedScore\":{\"raw\":$WEIGHTED_RAW,\"max\":$WEIGHTED_MAX,\"percent\":$WEIGHTED_PERCENT},\"traps\":{$TRAP_JSON},\"categories\":{$CAT_JSON},\"probes\":[$PROBE_JSON]}"
else
  echo ""
  echo "================================="
  PERCENT=0
  if [[ $TOTAL -gt 0 ]]; then
    PERCENT=$(( PASS * 100 / TOTAL ))
  fi
  echo "Unweighted: $PASS/$TOTAL ($PERCENT%)"
  echo "Weighted:   $WEIGHTED_RAW/$WEIGHTED_MAX ($WEIGHTED_PERCENT%)"
  echo ""

  echo "Per-trap breakdown:"
  labels=("T1:paging" "T2:errors" "T3:remove" "T4:dates" "T5:IDs" "T6:ok-wrap" "T7:err.code" "T8:result" "T9:batch" "T10:order")
  for entry in "${labels[@]}"; do
    trap="${entry%%:*}"
    label="${entry#*:}"
    cat="${TRAP_CAT[$trap]}"
    printf "  %-12s [%s x%d]  %d/%d\n" "$trap ($label)" "$cat" "${CAT_WEIGHT[$cat]}" "${TRAP_PASS[$trap]}" "${TRAP_TOTAL[$trap]}"
  done

  # Save score to results
  echo "{\"pass\":$PASS,\"total\":$TOTAL,\"weighted_raw\":$WEIGHTED_RAW,\"weighted_max\":$WEIGHTED_MAX,\"weighted_percent\":$WEIGHTED_PERCENT}" > "$PROJECT/results/score.json" 2>/dev/null || true
fi
