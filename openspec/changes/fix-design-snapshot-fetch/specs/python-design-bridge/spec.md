## ADDED Requirements

### Requirement: Design MCP detection in Python planner

The Python planner SHALL detect registered design MCP servers by reading `.claude/settings.json` and checking for known design tool server names (figma, penpot, sketch, zeplin).

#### Scenario: Figma MCP registered in settings
- **WHEN** `_detect_design_mcp()` is called
- **AND** `.claude/settings.json` contains `mcpServers.figma`
- **THEN** the function returns the server name `"figma"`

#### Scenario: No design MCP registered
- **WHEN** `_detect_design_mcp()` is called
- **AND** `.claude/settings.json` has no keys matching design tool names
- **THEN** the function returns `None`

#### Scenario: Settings file missing
- **WHEN** `_detect_design_mcp()` is called
- **AND** `.claude/settings.json` does not exist
- **THEN** the function returns `None`

### Requirement: Design file reference loading in Python planner

The Python planner SHALL read the `design_file` key from the orchestration config (either `wt/orchestration/config.yaml` or `.claude/orchestration.yaml`).

#### Scenario: design_file configured
- **WHEN** `_load_design_file_ref()` is called
- **AND** the orchestration config contains `design_file: https://figma.com/design/ABC123`
- **THEN** the function returns `"https://figma.com/design/ABC123"`

#### Scenario: design_file not configured
- **WHEN** `_load_design_file_ref()` is called
- **AND** the orchestration config has no `design_file` key
- **THEN** the function returns `None`

### Requirement: Design snapshot fetch via subprocess

The Python planner SHALL invoke the design snapshot fetch pipeline via bash bridge subprocess when a design MCP is detected and a design file reference is configured.

#### Scenario: Successful snapshot fetch
- **WHEN** `_fetch_design_context()` is called
- **AND** a design MCP is detected
- **AND** `design_file` is configured
- **THEN** the function calls `setup_design_bridge` and `fetch_design_snapshot` via bash subprocess
- **AND** reads the resulting `design-snapshot.md`
- **AND** returns the snapshot content (first 5000 chars)

#### Scenario: Cached snapshot exists
- **WHEN** `_fetch_design_context()` is called
- **AND** `design-snapshot.md` already exists with `## Design Tokens` content
- **AND** the `force` parameter is `False`
- **THEN** the function reads the cached file without re-fetching
- **AND** returns the snapshot content

#### Scenario: Replan forces re-fetch
- **WHEN** `_fetch_design_context()` is called with `force=True`
- **AND** a cached snapshot exists
- **THEN** the function calls `fetch_design_snapshot` with `force` flag
- **AND** returns the fresh snapshot content

### Requirement: Fail-fast when design configured but fetch fails

The Python planner SHALL raise a `RuntimeError` when a design MCP is registered and `design_file` is configured but the snapshot fetch fails, blocking decomposition.

#### Scenario: Fetch fails with design configured
- **WHEN** `_fetch_design_context()` is called
- **AND** a design MCP is detected
- **AND** `design_file` is configured
- **AND** the bash bridge fetch returns non-zero or produces no snapshot
- **THEN** a `RuntimeError` is raised with message containing "Design snapshot fetch failed"
- **AND** decomposition does not proceed

#### Scenario: Fetch fails but DESIGN_OPTIONAL is set
- **WHEN** `_fetch_design_context()` is called
- **AND** a design MCP is detected
- **AND** `design_file` is configured
- **AND** the fetch fails
- **AND** `DESIGN_OPTIONAL=true` environment variable is set
- **THEN** the function logs a warning "Design snapshot fetch failed (DESIGN_OPTIONAL=true, continuing without design)"
- **AND** returns an empty string
- **AND** decomposition proceeds without design context

#### Scenario: No design MCP — silent skip
- **WHEN** `_fetch_design_context()` is called
- **AND** no design MCP is detected
- **THEN** the function returns an empty string
- **AND** no error is raised

#### Scenario: Design MCP detected but no design_file — skip health check
- **WHEN** `_fetch_design_context()` is called
- **AND** a design MCP is detected (e.g., figma)
- **AND** `design_file` is NOT configured in orchestration config
- **THEN** the function skips health check and fetch (avoids wasting 30s on a Claude probe)
- **AND** returns an empty string
- **AND** no error is raised

### Requirement: Bash bridge subprocess chaining

All bash bridge function calls (`setup_design_bridge`, `check_design_mcp_health`, `fetch_design_snapshot`) SHALL be executed in a single `bash -c` subprocess invocation, because `setup_design_bridge` exports env vars (`DESIGN_MCP_CONFIG`, `DESIGN_MCP_NAME`) that subsequent functions depend on.

#### Scenario: Single chained subprocess call
- **WHEN** `_fetch_design_context()` invokes the bash bridge
- **THEN** it runs a single `bash -c 'source bridge.sh && setup_design_bridge && check_design_mcp_health && fetch_design_snapshot'` command
- **AND** env vars exported by `setup_design_bridge` are available to `check_design_mcp_health` and `fetch_design_snapshot` within the same process
