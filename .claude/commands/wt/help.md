When the user asks about wt-tools features, use this quick reference to answer. For deeper details, read the linked files or run `wt-<command> --help`.

## CLI Commands

| Command | Description |
|---------|-------------|
| `wt-new <change-id>` | Create a git worktree for a spec change |
| `wt-list` | List active worktrees for projects |
| `wt-work <change-id>` | Open editor for a worktree (creates if needed) |
| `wt-close <change-id>` | Remove a worktree and optionally its branch |
| `wt-merge <change-id>` | Merge a worktree's branch into a target branch |
| `wt-status` | Display worktree and Claude agent status |
| `wt-loop <command>` | Run autonomous agent loop in a worktree |
| `wt-memory <command>` | Per-project cognitive memory (shodh-memory). Details: `docs/developer-memory.md` |
| `wt-control` | Launch the Control Center GUI |
| `wt-project <command>` | Project management (init, deploy) |
| `wt-openspec <command>` | OpenSpec CLI wrapper (status, init, update) |
| `wt-usage` | Show Claude API usage and burn rate |
| `wt-config <command>` | Configure wt-tools settings |
| `wt-add [path]` | Add an existing git repo to wt-tools |
| `wt-focus <change-id>` | Focus the editor window for a worktree |
| `wt-version` | Display wt-tools version |

## Skills (Slash Commands)

### OpenSpec Workflow (`/opsx:*`)

| Skill | Description |
|-------|-------------|
| `/opsx:new` | Start a new change with structured artifacts (proposal → design → specs → tasks) |
| `/opsx:ff` | Fast-forward: create all artifacts in one go, ready for implementation |
| `/opsx:apply` | Implement tasks from a change |
| `/opsx:continue` | Continue working on a change — create the next artifact |
| `/opsx:verify` | Verify implementation matches change artifacts |
| `/opsx:archive` | Archive a completed change (syncs specs, cleans up) |
| `/opsx:bulk-archive` | Archive multiple completed changes at once |
| `/opsx:explore` | Open-ended thinking/exploration mode (no implementation) |
| `/opsx:sync` | Sync delta specs from a change to main specs |
| `/opsx:onboard` | Guided walkthrough of the OpenSpec workflow |

### Worktree Management (`/wt:*`)

| Skill | Description |
|-------|-------------|
| `/wt:new` | Create a new worktree |
| `/wt:work` | Open a worktree for editing |
| `/wt:list` | List all worktrees |
| `/wt:close` | Close a worktree |
| `/wt:merge` | Merge a worktree into target branch |
| `/wt:push` | Push current branch to remote |
| `/wt:status` | Show agent and worktree status |
| `/wt:loop` | Start autonomous agent loop (Ralph) |
| `/wt:broadcast` | Broadcast what you're working on to other agents |
| `/wt:msg` | Send a directed message to another agent |
| `/wt:inbox` | Read incoming messages |
| `/wt:memory` | Interact with project memory system |
| `/wt:help` | This quick reference |

## MCP Tools

### Memory (`wt-memory`)

| Tool | Description |
|------|-------------|
| `remember(content, type, tags)` | Save a memory (types: Decision, Learning, Context) |
| `recall(query, mode, tags)` | Semantic search for memories |
| `proactive_context(context)` | Context-aware memory retrieval with relevance scores |
| `forget(id)` | Delete a memory |
| `forget_by_tags(tags)` | Bulk delete by tags |
| `list_memories(type)` | List memories, optionally filtered by type |
| `get_memory(id)` | Get full details of a single memory |
| `context_summary(topic)` | Condensed summary by category |
| `brain()` | 3-tier memory visualization (core/active/peripheral) |
| `audit(threshold)` | Duplicate detection report |
| `cleanup(threshold, dry_run)` | Remove low-value memories |
| `dedup(threshold, dry_run)` | Remove duplicate memories |
| `add_todo(content, tags)` | Save a todo for later |
| `list_todos()` | List open todos |
| `complete_todo(id)` | Mark a todo as done |
| `sync()` | Push + pull memory sync (git-based) |
| `export_memories()` | Export all memories to JSON |

### Worktree & Team (`wt-tools`)

| Tool | Description |
|------|-------------|
| `list_worktrees()` | List all git worktrees across projects |
| `get_activity(change_id)` | Get agent activity from local worktrees |
| `get_team_status()` | Show which team members are active and what they're doing |
| `get_ralph_status(change_id)` | Get Ralph loop status for a worktree |
| `send_message(recipient, message)` | Send a directed message to another agent |
| `get_inbox(since)` | Read incoming directed messages |
| `get_worktree_tasks(worktree_path)` | Get tasks.md content from a worktree |

## Common Workflows

**New feature (full workflow):**
`wt-new my-feature` → `/opsx:ff` → `/opsx:apply` → `/opsx:verify` → `/opsx:archive` → `wt-merge my-feature`

**Quick fix (skip artifacts):**
`wt-new quick-fix` → implement → `wt-merge quick-fix`

**Explore before deciding:**
`/opsx:explore` → think/investigate → `/opsx:new` when ready

**Parallel work:**
`wt-new feature-a` + `wt-new feature-b` → work in separate worktrees → merge independently

## Detailed Documentation

| Topic | File |
|-------|------|
| Memory system | `docs/developer-memory.md` |
| Agent messaging | `docs/agent-messaging.md` |
| Configuration | `docs/config.md` |
| README guide | `docs/readme-guide.md` |
