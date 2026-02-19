## MODIFIED Requirements

### Requirement: Own MCP server wrapping full wt-memory CLI
The unified MCP server (`mcp-server/wt_mcp_server.py`) SHALL expose the full `wt-memory` CLI as MCP tools. It SHALL shell out to `wt-memory` commands with `cwd=CLAUDE_PROJECT_DIR`, ensuring all custom logic (branch boosting, auto-tagging, dedup, sync) applies to MCP calls and resolves to the correct project storage.

#### Scenario: MCP server registration
- **WHEN** `wt-project init` runs on a project
- **THEN** it SHALL register the unified MCP server via `claude mcp add wt-tools -- env CLAUDE_PROJECT_DIR="<project-path>" uv --directory "<mcp-server-dir>" run python wt_mcp_server.py`
- **AND** the server SHALL use stdio transport (standard MCP protocol)

#### Scenario: MCP server re-registration on init
- **WHEN** `wt-project init` runs and a `wt-tools` MCP is already registered
- **THEN** it SHALL re-register (overwrite) to ensure the command and CLAUDE_PROJECT_DIR are correct
- **AND** it SHALL remove any legacy `wt-memory` MCP registration

#### Scenario: LLM can use memory tools
- **WHEN** Claude Code starts a session with the unified MCP server active
- **THEN** the LLM SHALL have access to all memory tools covering the full wt-memory interface
- **AND** these tools SHALL operate through the same `wt-memory` CLI path as hooks
- **AND** `wt-memory` SHALL run with CWD set to the project root

### Requirement: Hooks and MCP share the same path
Both the hook system (via `wt-memory` CLI) and the unified MCP server (via `wt-memory` CLI with `cwd=CLAUDE_PROJECT_DIR`) SHALL use the identical code path and resolve to the same project storage.

#### Scenario: Memory saved via hook, recalled via MCP
- **WHEN** the Stop hook saves a memory via `wt-memory remember` (CWD = project root)
- **AND** the LLM later calls the MCP `recall` tool (CWD = CLAUDE_PROJECT_DIR = project root)
- **THEN** the saved memory SHALL be findable via MCP recall

#### Scenario: Memory saved via MCP, surfaced via hook
- **WHEN** the LLM calls the MCP `remember` tool to save an insight
- **AND** a subsequent hook fires and recalls memory
- **THEN** the MCP-saved memory SHALL be surfaceable via hook injection

#### Scenario: Branch boosting works in both paths
- **WHEN** the LLM calls MCP `recall` while on branch `feature-x`
- **THEN** branch boosting SHALL apply (dual-query: branch-filtered + unfiltered)
- **AND** the behavior SHALL be identical to hook-initiated recall
