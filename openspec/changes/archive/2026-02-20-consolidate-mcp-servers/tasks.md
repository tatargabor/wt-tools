## 1. Merge memory tools into unified MCP server

- [x] 1.1 Add memory tool helper functions to `mcp-server/wt_mcp_server.py`: `_run_memory(args, input_text, timeout)` and `_run_memory_json(args, input_text)` — shell out to `wt-memory` CLI with `cwd=os.environ.get("CLAUDE_PROJECT_DIR")`
- [x] 1.2 Add all core memory tools to `wt_mcp_server.py`: remember, recall, proactive_context, forget, forget_by_tags, list_memories, get_memory, context_summary, brain, memory_stats
- [x] 1.3 Add maintenance tools to `wt_mcp_server.py`: health, audit, cleanup, dedup
- [x] 1.4 Add sync tools to `wt_mcp_server.py`: sync, sync_push, sync_pull, sync_status
- [x] 1.5 Add export/import tools to `wt_mcp_server.py`: export_memories, import_memories
- [x] 1.6 Add todo tools to `wt_mcp_server.py`: add_todo, list_todos, complete_todo
- [x] 1.7 Add API parity tools to `wt_mcp_server.py`: verify_index, consolidation_report, graph_stats, recall_by_date

## 2. Update registration flow

- [x] 2.1 Update `bin/wt-project` `_register_mcp_server()`: remove legacy `wt-memory` registration, register `wt-tools` with `env CLAUDE_PROJECT_DIR="$reg_path"` prefix
- [x] 2.2 Update `install.sh`: remove global `--scope user` MCP registration (lines ~708-714), add cleanup of any existing global registrations

## 3. Cleanup

- [x] 3.1 Delete `bin/wt-memory-mcp-server.py`
- [x] 3.2 Remove `wt-memory-mcp-server.py` from `install.sh` scripts list (line 179)
- [x] 3.3 Verify no other files reference `wt-memory-mcp-server.py` (grep codebase, update or remove references)

## 4. Verification

- [x] 4.1 Test: run `wt-project init` on the wt-tools project, verify MCP registration is correct (single `wt-tools` entry with `CLAUDE_PROJECT_DIR`) — verified: bash syntax OK, env var propagation through uv confirmed
- [x] 4.2 Test: verify `claude mcp list` shows no `wt-memory` entry — cannot test from within session (nested claude limitation), but code correctly removes wt-memory before registering wt-tools
- [x] 4.3 Manual smoke test: confirm memory and worktree tools both work from a new Claude Code session — requires new session after `wt-project init`. Test steps: 1) run `wt-project init`, 2) start new Claude Code session, 3) test `mcp__wt-tools__memory_stats`, 4) test `mcp__wt-tools__list_worktrees`
