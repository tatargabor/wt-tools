## Why

`wt-project init` registers the wt-memory MCP server with `claude mcp add wt-memory -- python <path>`, hardcoding `python` as the interpreter. On systems where only `python3` exists (common on Linux), the MCP server fails to start. The script already has `#!/usr/bin/env python3` — we should use it directly instead of specifying an interpreter.

## What Changes

- Remove the hardcoded `python` from MCP registration — run the script directly via its shebang
- Add migration in `_register_mcp_server()` to detect and fix existing stale `"command": "python"` configs
- Update the mcp-memory-tools spec to reflect the new registration command

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `mcp-memory-tools`: MCP server registration scenario changes from `-- python <path>` to `-- <path>` (shebang-based execution)

## Impact

- `bin/wt-project`: `_register_mcp_server()` function
- `~/.claude.json`: existing per-project MCP configs with `"command": "python"` get migrated
- No API changes, no new dependencies
