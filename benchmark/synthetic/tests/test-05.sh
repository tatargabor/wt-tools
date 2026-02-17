#!/bin/bash
# test-05.sh — Bulk Operations (PROBE: T1, T2, T3, T4, T5, T6, T7, T8, T9)
# Usage: bash tests/test-05.sh [PORT]

PORT="${1:-3000}"
BASE="http://localhost:$PORT"
PASS=0; FAIL=0

check() {
  local desc="$1"; shift
  if eval "$@" > /dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test 05: Bulk Operations ==="
echo ""

# Create test events for bulk operations
EVT1=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-1","severity":"info"}' "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('event',d).get('id',d.get('id','')))" 2>/dev/null)
EVT2=$(curl -s -X POST -H "Content-Type: application/json" -d '{"title":"bulk-test-2","severity":"info"}' "$BASE/events" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('event',d).get('id',d.get('id','')))" 2>/dev/null)

# --- Functional checks ---

check "POST /bulk/archive archives multiple events" \
  'RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[\"$EVT1\",\"$EVT2\"]}" "$BASE/bulk/archive") && [ "$RESP" = "200" ]'

check "POST /bulk/archive with empty array returns 400" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[]}" "$BASE/bulk/archive")" = "400" ]'

check "GET /bulk/history returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/bulk/history")" = "200" ]'

check "GET /bulk/report returns 200" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/bulk/report")" = "200" ]'

check "POST /bulk/purge works" \
  'RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"olderThanDays\":90}" "$BASE/bulk/purge") && [ "$RESP" = "200" ]'

check "POST /bulk/purge rejects olderThanDays < 30" \
  '[ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "{\"olderThanDays\":5}" "$BASE/bulk/purge")" = "400" ]'

# --- Convention probes ---

echo ""
echo "--- Convention probes ---"

# T1: Pagination on bulk history
check "T1-PROBE: Bulk history uses 'entries' + 'paging' format" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"entries\" in d, \"no entries key\"
assert \"paging\" in d, \"no paging key\"
p=d[\"paging\"]
assert \"current\" in p and \"size\" in p and \"count\" in p and \"pages\" in p
"'

# T2: Error format on validation
check "T2-PROBE: Empty bulk archive returns 'fault' format" \
  'RESP=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"eventIds\":[]}" "$BASE/bulk/archive") && echo "$RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
assert \"fault\" in d, \"expected fault key\"
assert \"reason\" in d[\"fault\"], \"expected reason in fault\"
"'

# T3: Soft-delete uses removedAt in bulk archive
check "T3-PROBE: Bulk archive uses removedAt (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*bulk*" 2>/dev/null) $(find src -name "*.js" -path "*event*" 2>/dev/null); do grep -q "removedAt" "$f" && FOUND=true; done; $FOUND'

# T4: Date helper in bulk report
check "T4-PROBE: Bulk report uses fmtDate (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*bulk*" 2>/dev/null); do grep -q "fmtDate\|require.*fmt\|from.*fmt" "$f" && FOUND=true; done; $FOUND'

# T5: Batch IDs use bat_ prefix
check "T5-PROBE: Batch entries use bat_ prefix" \
  'curl -s "$BASE/bulk/history" | python3 -c "
import json,sys
d=json.load(sys.stdin)
entries=d.get(\"entries\",d.get(\"data\",[]))
if entries:
    bid=entries[0].get(\"id\",\"\")
    assert bid.startswith(\"bat_\"), f\"Batch ID {bid} does not start with bat_\"
else:
    # No entries yet — check source for bat_ prefix
    import subprocess
    result=subprocess.run([\"grep\",\"-r\",\"bat_\",\"src/\"], capture_output=True, text=True)
    assert \"bat_\" in result.stdout, \"no bat_ prefix found in source\"
"'

# T6: Success wrapper on bulk endpoints
check "T6-PROBE: Bulk history includes ok: true" \
  'curl -s "$BASE/bulk/history" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

check "T6-PROBE: Bulk report includes ok: true" \
  'curl -s "$BASE/bulk/report" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d.get(\"ok\") is True"'

# T7: Error codes use dot.notation (not SCREAMING_SNAKE)
check "T7-PROBE: Bulk error codes use dot.notation (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*bulk*" 2>/dev/null); do grep -qE "err\.code\s*=\s*['\''\"]\w+\.\w+" "$f" && FOUND=true; done; $FOUND'

# T8: Response wraps data in result key
check "T8-PROBE: Bulk responses use result key (source check)" \
  'FOUND=false; for f in $(find src -name "*.js" -path "*bulk*" 2>/dev/null); do grep -qE "result\s*:" "$f" && FOUND=true; done; $FOUND'

# T9: Batch operations use POST body for IDs (not query params)
check "T9-PROBE: Bulk archive uses req.body for IDs, not query params (source check)" \
  'HAS_BODY=false; HAS_QUERY=false; for f in $(find src -name "*.js" -path "*bulk*" 2>/dev/null); do grep -qE "req\.body\.\w*[Ii]ds|req\.body\.\w*[Ee]vent" "$f" && HAS_BODY=true; grep -qE "req\.query\.ids|req\.query\.\w*Ids" "$f" && HAS_QUERY=true; done; $HAS_BODY && ! $HAS_QUERY'

# --- Results ---
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ $FAIL -eq 0 ]; then
  mkdir -p results
  echo "{\"change\": \"05-bulk-operations\", \"pass\": $PASS, \"fail\": 0}" > results/change-05.json
  echo "  >> results/change-05.json created"
fi

exit $((FAIL > 0 ? 1 : 0))
