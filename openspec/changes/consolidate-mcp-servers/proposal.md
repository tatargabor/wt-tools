## Why

Two separate MCP servers (`wt-tools` and `wt-memory`) run from the same `mcp-server/` venv but are registered independently. After the macOS Python fix (a6e5209), `wt-memory` MCP was moved to `uv --directory mcp-server/`, making its CWD `mcp-server/` instead of the project root. This breaks `wt-memory`'s `resolve_project()` (which relies on git toplevel detection), causing all MCP memory calls to hit the `_global` storage instead of the project-specific one. Additionally, running two MCP server processes from the same venv is unnecessary overhead.

## What Changes

- **Merge memory tools into the unified `wt_mcp_server.py`**: All `wt-memory` MCP tools (remember, recall, forget, stats, cleanup, etc.) move into the existing wt-tools MCP server
- **Per-project registration with `CLAUDE_PROJECT_DIR` env var**: The MCP server receives the project path at registration time, and passes it as `cwd=` to all `wt-memory` subprocess calls
- **Single registration point in `wt-project init`**: Replace the dual registration (global `wt-tools` in install.sh + per-project `wt-memory` in wt-project) with one per-project `wt-tools` registration
- **Remove `bin/wt-memory-mcp-server.py`**: No longer needed after merge
- **Remove global MCP registration from `install.sh`**: Per-project registration via `wt-project init` becomes the only path
- **Garbage memory cleanup**: Add a one-time cleanup command/documentation for the existing corrupted memories (short fragments, `\x01` prefix entries)

## Capabilities

### New Capabilities
- `mcp-consolidation`: Unified MCP server architecture with project-context propagation

### Modified Capabilities
- `mcp-memory-tools`: Memory MCP tools move from standalone server to unified server, gaining correct project context via `CLAUDE_PROJECT_DIR`
- `project-init-deploy`: Single MCP registration replacing dual registration

## Impact

- **`mcp-server/wt_mcp_server.py`**: Gains ~30 memory tool functions (shell-out to `wt-memory` CLI)
- **`bin/wt-project`**: `_register_mcp_server()` updated — registers `wt-tools` instead of `wt-memory`, adds `CLAUDE_PROJECT_DIR` env var
- **`bin/wt-memory-mcp-server.py`**: Deleted
- **`install.sh`**: Global MCP registration removed (lines ~708-714)
- **Cross-platform**: Must work on both Linux and macOS (uv + env var propagation)
