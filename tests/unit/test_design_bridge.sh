#!/usr/bin/env bash
# Unit tests for lib/design/bridge.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

# Source the module under test
source "$SCRIPT_DIR/../../lib/design/bridge.sh"

# ─── Setup / Teardown ────────────────────────────────────────────────

_TMPDIR=""
setup() {
    _TMPDIR=$(mktemp -d)
    export PROJECT_ROOT="$_TMPDIR"
    unset DESIGN_FILE_REF DESIGN_MCP_CONFIG DESIGN_MCP_NAME
}

teardown() {
    rm -rf "$_TMPDIR"
    unset PROJECT_ROOT DESIGN_FILE_REF DESIGN_MCP_CONFIG DESIGN_MCP_NAME
}

# ─── detect_design_mcp ───────────────────────────────────────────────

test_detect_figma_mcp() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{
  "mcpServers": {
    "wt-tools": {"command": "uv", "args": ["run"]},
    "figma": {"type": "http", "url": "https://mcp.figma.com/mcp"}
  }
}
JSON

    local result
    result=$(detect_design_mcp)
    assert_equals "figma" "$result" "should detect figma"
    teardown
}

test_detect_penpot_mcp() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"penpot": {"command": "node", "args": ["server.js"]}}}
JSON

    local result
    result=$(detect_design_mcp)
    assert_equals "penpot" "$result" "should detect penpot"
    teardown
}

test_detect_no_design_mcp() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"wt-tools": {"command": "uv"}}}
JSON

    local rc=0
    detect_design_mcp > /dev/null 2>&1 || rc=$?
    assert_equals "1" "$rc" "should return 1 when no design MCP"
    teardown
}

test_detect_missing_settings() {
    setup
    # No .claude/settings.json at all
    local rc=0
    detect_design_mcp > /dev/null 2>&1 || rc=$?
    assert_equals "1" "$rc" "should return 1 when settings missing"
    teardown
}

test_detect_multiple_design_mcps() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"figma": {"url": "x"}, "penpot": {"command": "y"}}}
JSON

    local result
    result=$(detect_design_mcp)
    # Should return the first match (alphabetical from jq keys)
    assert_equals "figma" "$result" "should return first match"
    teardown
}

# ─── get_design_mcp_config ───────────────────────────────────────────

test_config_export() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{
  "mcpServers": {
    "figma": {"type": "http", "url": "https://mcp.figma.com/mcp"},
    "wt-tools": {"command": "uv"}
  }
}
JSON

    local config_file
    config_file=$(get_design_mcp_config "figma")

    # Should contain only the figma server
    local server_count
    server_count=$(jq '.mcpServers | keys | length' "$config_file")
    assert_equals "1" "$server_count" "should export only figma config"

    local url
    url=$(jq -r '.mcpServers.figma.url' "$config_file")
    assert_equals "https://mcp.figma.com/mcp" "$url" "should preserve URL"

    rm -f "$config_file"
    teardown
}

# ─── load_design_file_ref ────────────────────────────────────────────

test_load_design_file_ref() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/orchestration.yaml" <<'YAML'
max_parallel: 3
design_file: "https://www.figma.com/file/ABC123/MyDesign"
merge_policy: checkpoint
YAML

    load_design_file_ref
    assert_equals "https://www.figma.com/file/ABC123/MyDesign" "$DESIGN_FILE_REF" "should export ref"
    teardown
}

test_load_design_file_ref_missing() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/orchestration.yaml" <<'YAML'
max_parallel: 3
YAML

    local rc=0
    load_design_file_ref || rc=$?
    assert_equals "1" "$rc" "should return 1 when no design_file"
    teardown
}

# ─── design_prompt_section ───────────────────────────────────────────

test_prompt_section_with_ref() {
    setup
    export DESIGN_FILE_REF="https://figma.com/file/XYZ"

    local output
    output=$(design_prompt_section "figma")

    assert_contains "$output" "figma" "should mention tool name"
    assert_contains "$output" "Design file reference: https://figma.com/file/XYZ" "should include ref"
    assert_contains "$output" "design_gap" "should mention ambiguity type"
    teardown
}

test_prompt_section_without_ref() {
    setup
    unset DESIGN_FILE_REF

    local output
    output=$(design_prompt_section "penpot")

    assert_contains "$output" "penpot" "should mention tool name"
    assert_not_contains "$output" "Design file reference:" "should not include ref line"
    teardown
}

# ─── setup_design_bridge ─────────────────────────────────────────────

test_setup_design_bridge_full() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"figma": {"type": "http", "url": "https://mcp.figma.com/mcp"}}}
JSON
    cat > "$_TMPDIR/.claude/orchestration.yaml" <<'YAML'
design_file: "https://figma.com/file/TEST"
YAML

    setup_design_bridge
    assert_equals "figma" "$DESIGN_MCP_NAME" "should set MCP name"
    assert_file_exists "$DESIGN_MCP_CONFIG" "should create config file"
    assert_equals "https://figma.com/file/TEST" "$DESIGN_FILE_REF" "should load file ref"

    rm -f "$DESIGN_MCP_CONFIG"
    teardown
}

test_setup_design_bridge_no_mcp() {
    setup
    # No settings.json
    local rc=0
    setup_design_bridge || rc=$?
    assert_equals "1" "$rc" "should return 1 without design MCP"
    assert_equals "" "${DESIGN_MCP_CONFIG:-}" "should not set config"
    teardown
}

# ─── Run ──────────────────────────────────────────────────────────────


# ─── check_design_mcp_health ────────────────────────────────────

test_health_check_success() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"figma": {"type": "http", "url": "https://mcp.figma.com/mcp"}}}
JSON
    setup_design_bridge

    # Mock run_claude to return healthy response
    run_claude() { echo "MCP_HEALTHY"; return 0; }
    export -f run_claude
    log_info() { :; }
    log_warn() { :; }

    local rc=0
    check_design_mcp_health || rc=$?
    assert_equals "0" "$rc" "should return 0 when MCP is healthy"

    rm -f "$DESIGN_MCP_CONFIG"
    teardown
}

test_health_check_auth_failure() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"figma": {"type": "http", "url": "https://mcp.figma.com/mcp"}}}
JSON
    setup_design_bridge

    # Mock run_claude to return auth failure
    run_claude() { echo "MCP_AUTH_FAILED: needs authentication"; return 0; }
    export -f run_claude
    log_info() { :; }
    log_warn() { :; }

    local rc=0
    check_design_mcp_health || rc=$?
    assert_equals "1" "$rc" "should return 1 when MCP auth fails"

    rm -f "$DESIGN_MCP_CONFIG"
    teardown
}

test_health_check_timeout() {
    setup
    mkdir -p "$_TMPDIR/.claude"
    cat > "$_TMPDIR/.claude/settings.json" <<'JSON'
{"mcpServers": {"figma": {"type": "http", "url": "https://mcp.figma.com/mcp"}}}
JSON
    setup_design_bridge

    # Mock run_claude to simulate timeout (non-zero exit)
    run_claude() { return 124; }
    export -f run_claude
    log_info() { :; }
    log_warn() { :; }

    local rc=0
    check_design_mcp_health || rc=$?
    assert_equals "1" "$rc" "should return 1 on timeout"

    rm -f "$DESIGN_MCP_CONFIG"
    teardown
}

test_health_check_no_config() {
    setup
    unset DESIGN_MCP_CONFIG DESIGN_MCP_NAME
    log_info() { :; }
    log_warn() { :; }

    local rc=0
    check_design_mcp_health || rc=$?
    assert_equals "1" "$rc" "should return 1 without config"

    teardown
}

run_tests
