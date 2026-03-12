#!/usr/bin/env bash
# lib/design/bridge.sh — Design tool abstraction layer
# Detects registered design MCP servers, exports config for run_claude --mcp-config,
# and generates design-aware prompt sections for planner/verifier/dispatcher.
#
# Usage: source this file after config.sh. All functions are non-fatal.
# If no design MCP is detected, functions return 1 silently.

# ─── Detection ────────────────────────────────────────────────────────

# Detect a registered design MCP server from .claude/settings.json.
# Prints the server name (e.g., "figma") and returns 0, or returns 1 if none found.
detect_design_mcp() {
    local project_root="${PROJECT_ROOT:-.}"
    local settings="$project_root/.claude/settings.json"
    [[ -f "$settings" ]] || return 1

    local design_server
    design_server=$(jq -r '
      .mcpServers // {} | keys[] |
      select(test("^(figma|penpot|sketch|zeplin)"))
    ' "$settings" 2>/dev/null | head -1)

    [[ -n "$design_server" ]] && echo "$design_server" || return 1
}

# ─── Config Export ────────────────────────────────────────────────────

# Extract a design MCP server's config into a temp JSON file for --mcp-config.
# Args: $1 = server name (from detect_design_mcp)
# Prints the temp file path to stdout.
get_design_mcp_config() {
    local server_name="$1"
    local project_root="${PROJECT_ROOT:-.}"
    local settings="$project_root/.claude/settings.json"
    [[ -f "$settings" ]] || return 1

    local config_file
    config_file=$(mktemp --suffix=.json)

    if ! jq --arg name "$server_name" '{
      mcpServers: { ($name): .mcpServers[$name] }
    }' "$settings" > "$config_file" 2>/dev/null; then
        rm -f "$config_file"
        return 1
    fi

    echo "$config_file"
}

# ─── Design File Reference ───────────────────────────────────────────

# Read design_file from .claude/orchestration.yaml and export as DESIGN_FILE_REF.
# Returns 1 if no design_file configured.
load_design_file_ref() {
    local project_root="${PROJECT_ROOT:-.}"
    local config="$project_root/.claude/orchestration.yaml"
    [[ -f "$config" ]] || return 1

    local ref
    # Try yq first (YAML-native), fall back to grep for simple key: value
    if command -v yq &>/dev/null; then
        ref=$(yq -r '.design_file // empty' "$config" 2>/dev/null)
    else
        ref=$(grep -E '^design_file:' "$config" 2>/dev/null | sed 's/^design_file:[[:space:]]*//' | tr -d '"'"'")
    fi

    if [[ -n "$ref" ]]; then
        export DESIGN_FILE_REF="$ref"
        return 0
    fi
    return 1
}

# ─── Prompt Enrichment ────────────────────────────────────────────────

# Generate a design-aware prompt section for planner/verifier prompts.
# Args: $1 = server name (e.g., "figma")
# Uses DESIGN_FILE_REF env var if set.
design_prompt_section() {
    local server_name="$1"
    local design_file_ref="${DESIGN_FILE_REF:-}"

    cat <<EOF
## Design Context

A design tool ($server_name) is available via MCP. You can query it for:
- Frame/page inventory: what screens/views are designed
- Component details: properties, variants, states
- Design tokens: colors, spacing, typography, shadows
- Layout information: auto-layout, constraints, dimensions
EOF

    if [[ -n "$design_file_ref" ]]; then
        echo ""
        echo "Design file reference: $design_file_ref"
    fi

    cat <<'EOF'

When planning changes that involve UI:
- Query the design tool to understand what frames exist
- Map each change to specific design frames
- If a required frame/page is MISSING from the design, flag it as an ambiguity with type "design_gap"
- Include design frame references in change scope descriptions
EOF
}

# ─── Convenience ──────────────────────────────────────────────────────

# One-call setup: detect, load config, export DESIGN_MCP_CONFIG.
# Returns 0 if design MCP is available and config exported, 1 otherwise.
# After this call, DESIGN_MCP_CONFIG is set (or empty).
setup_design_bridge() {
    local server_name
    server_name=$(detect_design_mcp) || return 1

    local config_file
    config_file=$(get_design_mcp_config "$server_name") || return 1

    load_design_file_ref || true  # non-fatal, file ref is optional

    export DESIGN_MCP_CONFIG="$config_file"
    export DESIGN_MCP_NAME="$server_name"
    return 0
}
