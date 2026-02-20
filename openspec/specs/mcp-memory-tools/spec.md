## ADDED Requirements

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

### Requirement: Core memory tools
The MCP server SHALL expose core memory operations as tools.

#### Scenario: remember tool
- **WHEN** the LLM calls `remember(content, type, tags)`
- **THEN** the server SHALL execute `echo <content> | wt-memory remember --type <type> --tags <tags>`
- **AND** SHALL return the result (memory ID or error)

#### Scenario: recall tool
- **WHEN** the LLM calls `recall(query, limit, mode, tags)`
- **THEN** the server SHALL execute `wt-memory recall "<query>" --limit <limit> --mode <mode> --tags <tags>`
- **AND** SHALL return the JSON result array

#### Scenario: proactive_context tool
- **WHEN** the LLM calls `proactive_context(context, limit)`
- **THEN** the server SHALL execute `wt-memory proactive "<context>" --limit <limit>`
- **AND** SHALL return the JSON result array with relevance scores

#### Scenario: forget tool
- **WHEN** the LLM calls `forget(id)`
- **THEN** the server SHALL execute `wt-memory forget <id>`

#### Scenario: forget_by_tags tool
- **WHEN** the LLM calls `forget_by_tags(tags)`
- **THEN** the server SHALL execute `wt-memory forget --tags <tags>`

#### Scenario: list_memories tool
- **WHEN** the LLM calls `list_memories(type, limit)`
- **THEN** the server SHALL execute `wt-memory list --type <type> --limit <limit>`

#### Scenario: get_memory tool
- **WHEN** the LLM calls `get_memory(id)`
- **THEN** the server SHALL execute `wt-memory get <id>`

#### Scenario: context_summary tool
- **WHEN** the LLM calls `context_summary(topic)`
- **THEN** the server SHALL execute `wt-memory context <topic>`

#### Scenario: brain tool
- **WHEN** the LLM calls `brain()`
- **THEN** the server SHALL execute `wt-memory brain`

#### Scenario: memory_stats tool
- **WHEN** the LLM calls `memory_stats()`
- **THEN** the server SHALL execute `wt-memory stats --json`

### Requirement: Maintenance tools
The MCP server SHALL expose memory maintenance operations.

#### Scenario: health tool
- **WHEN** the LLM calls `health()`
- **THEN** the server SHALL execute `wt-memory health`

#### Scenario: audit tool
- **WHEN** the LLM calls `audit(threshold)`
- **THEN** the server SHALL execute `wt-memory audit --threshold <threshold> --json`

#### Scenario: cleanup tool
- **WHEN** the LLM calls `cleanup(threshold, dry_run)`
- **THEN** the server SHALL execute `wt-memory cleanup --threshold <threshold>` with optional `--dry-run`

#### Scenario: dedup tool
- **WHEN** the LLM calls `dedup(threshold, dry_run)`
- **THEN** the server SHALL execute `wt-memory dedup --threshold <threshold>` with optional `--dry-run`

### Requirement: Sync tools
The MCP server SHALL expose git-based memory sync operations.

#### Scenario: sync tool
- **WHEN** the LLM calls `sync()`
- **THEN** the server SHALL execute `wt-memory sync`

#### Scenario: sync_push tool
- **WHEN** the LLM calls `sync_push()`
- **THEN** the server SHALL execute `wt-memory sync push`

#### Scenario: sync_pull tool
- **WHEN** the LLM calls `sync_pull(from_source)`
- **THEN** the server SHALL execute `wt-memory sync pull --from <from_source>`

#### Scenario: sync_status tool
- **WHEN** the LLM calls `sync_status()`
- **THEN** the server SHALL execute `wt-memory sync status`

### Requirement: Export/Import tools
The MCP server SHALL expose memory export and import operations.

#### Scenario: export tool
- **WHEN** the LLM calls `export_memories()`
- **THEN** the server SHALL execute `wt-memory export` and return the JSON

#### Scenario: import_memories tool
- **WHEN** the LLM calls `import_memories(file_path, dry_run)`
- **THEN** the server SHALL execute `wt-memory import <file_path>` with optional `--dry-run`

### Requirement: CLAUDE.md documents MCP tools alongside hooks
The CLAUDE.md Persistent Memory section SHALL document both automatic (hooks) and active (MCP) memory access.

#### Scenario: CLAUDE.md content
- **WHEN** a project's CLAUDE.md is deployed
- **THEN** it SHALL explain that memory context is injected automatically via system-reminders
- **AND** SHALL explain that MCP tools are available for deeper memory interactions
- **AND** SHALL list the key MCP tool names: remember, recall, proactive_context

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
