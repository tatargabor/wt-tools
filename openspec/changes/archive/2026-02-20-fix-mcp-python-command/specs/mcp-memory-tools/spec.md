## MODIFIED Requirements

### Requirement: Own MCP server wrapping full wt-memory CLI
A Python MCP server (`bin/wt-memory-mcp-server.py`) SHALL expose the full `wt-memory` CLI as MCP tools. It SHALL shell out to `wt-memory` commands, ensuring all custom logic (branch boosting, auto-tagging, dedup, sync) applies to MCP calls.

#### Scenario: MCP server registration
- **WHEN** `wt-project init` runs on a project
- **THEN** it SHALL register the MCP server via `claude mcp add wt-memory -- <path>/wt-memory-mcp-server.py` (no explicit python interpreter)
- **AND** the server SHALL use stdio transport (standard MCP protocol)
- **AND** the script SHALL be executed directly via its `#!/usr/bin/env python3` shebang

#### Scenario: MCP server re-registration on init
- **WHEN** `wt-project init` runs and wt-memory MCP is already registered
- **THEN** it SHALL re-register (overwrite) to ensure the command is correct
- **AND** this SHALL fix any stale `"command": "python"` entries from previous installs

#### Scenario: LLM can use memory tools
- **WHEN** Claude Code starts a session with the MCP server active
- **THEN** the LLM SHALL have access to ~20 tools covering the full wt-memory interface
- **AND** these tools SHALL operate through the same `wt-memory` CLI path as hooks
