# Developer Memory

Per-project cognitive memory for AI agents. Agents save decisions, learnings, and context as they work — future agents in different sessions recall relevant past experience before starting. Built on [shodh-memory](https://github.com/varun29ankuS/shodh-memory), integrated across CLI, GUI, and OpenSpec workflows.

> **Status:** Experimental. Requires `pip install shodh-memory`. Gracefully degrades if not installed — all commands silently no-op.

---

## Quick Start

```bash
# 1. Check if memory is available
wt-memory health

# 2. Save something
echo "PySide6 QTimer must only be called from the main thread" \
  | wt-memory remember --type Learning --tags pyside6,threading

# 3. Search for it later
wt-memory recall "QTimer threading"
```

That's it. The memory is stored per-project (worktrees of the same repo share memory) and persists across sessions.

---

## When Is It Useful?

### 1. Avoiding repeated mistakes

You spent an afternoon debugging why RocksDB corrupts data when two agents write simultaneously. You fixed it with file locking. A month later, a different agent starts a related change.

```bash
# You (or the agent) saves the hard-won knowledge:
echo "RocksDB crashes with concurrent access from multiple processes. \
Must use /tmp/wt-memory-<project>.lock for file locking." \
  | wt-memory remember --type Learning --tags rocksdb,concurrency

# A month later, new session, new agent starts a change:
#   /opsx:new "optimize memory storage"
#
# The OpenSpec hook runs automatically:
#   wt-memory recall "optimize memory storage" --limit 3
#
# Agent sees:
#   Learning: RocksDB crashes with concurrent access from multiple
#   processes. Must use /tmp/wt-memory-<project>.lock for file locking.
#
# → Agent uses file locking from the start. No wasted afternoon.
```

**Best for:** Preventing the same failure from happening twice. Especially valuable when multiple people or agents work on the same project over time.

### 2. Project decisions

Your team decided to use SSE instead of WebSockets for the notification system because the infrastructure doesn't support persistent connections. Three months later, someone starts a "real-time updates" feature.

```bash
# Decision saved during the original discussion:
echo "Chose SSE over WebSocket for notifications. \
Our infra (Cloudflare Workers) doesn't support persistent connections." \
  | wt-memory remember --type Decision --tags architecture,notifications,sse

# Three months later:
#   /opsx:new "add real-time updates"
#
# Automatic recall finds:
#   Decision: Chose SSE over WebSocket for notifications.
#   Our infra doesn't support persistent connections.
#
# → Agent designs the feature using SSE, not WebSocket.
```

**Best for:** Architectural decisions, technology choices, "why did we do it this way" context that's easy to forget.

### 3. Technical gotchas

Mid-implementation, you tell the agent something non-obvious about the codebase. The agent recognizes it as valuable and saves it automatically.

```
You: "By the way, the FeatureWorker polls every 15 seconds, so don't
     expect instant updates in the GUI after a status change."

Agent recognizes this as a technical learning and saves it:
  [Memory saved: Learning — FeatureWorker polls every 15s, GUI updates not instant]

# Next time any agent works on GUI responsiveness:
#   wt-memory recall "GUI update delay"
#   → Learning: FeatureWorker polls every 15 seconds...
```

**Best for:** Non-obvious behaviors, API quirks, timing dependencies, "things you'd tell a new team member."

### 4. Background context for future agents

You're setting up a new project with unusual constraints. Save the context so future agents don't start from zero.

```bash
echo "This project uses a monorepo with pnpm workspaces. \
The API is in packages/api/, the frontend in packages/web/. \
Tests must run from the root with 'pnpm test --filter=<package>'." \
  | wt-memory remember --type Context --tags setup,monorepo,pnpm

# Every future agent session can recall this:
wt-memory recall "project structure"
# → Context: This project uses a monorepo with pnpm workspaces...
```

**Best for:** Project setup notes, deployment procedures, environment-specific constraints, onboarding context.

---

## Memory Types

| Type | When to use | Example |
|------|-------------|---------|
| **Decision** | A choice was made between alternatives | "Chose SQLite over PostgreSQL for local storage because no server dependency" |
| **Learning** | A pattern, gotcha, or lesson was discovered | "pytest fixtures with module scope don't reset between test files" |
| **Context** | Background info that provides orientation | "This repo deploys to AWS Lambda via CDK, pipeline in infra/ directory" |

**Legacy aliases:** `Observation` maps to `Learning`, `Event` maps to `Context`. These still work but print a deprecation warning.

---

## OpenSpec Integration

If you use [OpenSpec](https://github.com/tatargabor/wt-tools) workflows (`/opsx:new`, `/opsx:apply`, etc.), memory hooks add automatic recall and remember at key points in each phase. Install them once:

```bash
wt-memory-hooks install
```

### How it works

```
  /opsx:new                /opsx:continue          /opsx:ff
  ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
  │ recall       │        │ recall       │        │ recall       │
  │ related work │        │ + mid-flow   │        │ + mid-flow   │
  │              │        │   remember   │        │   remember   │
  └──────┬───────┘        └──────┬───────┘        └──────┬───────┘
         │                       │                       │
         ▼                       ▼                       ▼
  /opsx:apply              /opsx:archive           /opsx:explore
  ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
  │ recall       │        │ extract      │        │ recall       │
  │ + mid-flow   │        │ decisions +  │        │ + remember   │
  │   remember   │        │ lessons from │        │   insights   │
  │ + remember   │        │ artifacts    │        │              │
  │   on done    │        │              │        │              │
  └──────────────┘        └──────────────┘        └──────────────┘
```

### Phase detail

| Phase | Hook | What happens automatically | Example |
|-------|------|---------------------------|---------|
| `/opsx:new` | Recall | Searches for related past work before creating a proposal | "add auth" → recalls past decisions about auth approaches |
| `/opsx:continue` | Recall + Mid-flow + Agent reflect | Recalls relevant experience; saves user corrections; agent saves own insights at session end | User says "we tried Redux, it was too complex" → saved as Learning |
| `/opsx:ff` | Recall + Mid-flow + Agent reflect | Same as continue, but during fast-forward artifact generation | Agent discovers codebase uses event sourcing → saved as Learning |
| `/opsx:apply` | Recall + Mid-flow + Agent reflect | Recalls implementation patterns/errors; saves user corrections; on completion saves errors encountered and patterns learned | After finishing: "Learning: the menu system requires WindowStaysOnTopHint for all dialogs" |
| `/opsx:verify` | Recall + Agent remember | Recalls past issues before verification; saves problems found or quality patterns discovered | "Learning: verification revealed missing error handling in all API endpoints" |
| `/opsx:sync-specs` | Agent remember | Saves merge decisions when resolving spec conflicts | "Decision: merged overlapping requirements by combining scenarios" |
| `/opsx:archive` | Extract + Remember | Extracts decisions from design.md and lessons from tasks.md, saves as memories | design.md says "chose marker-based hooks" → saved as Decision |
| `/opsx:explore` | Recall + User save + Agent reflect | Recalls related knowledge; saves user insights; agent saves own discoveries at session end | Agent discovers hidden coupling between modules → saved as Learning |

### Coverage matrix

| Skill | Recall | Mid-flow User Save | Agent Self-Reflection | Structured Tags |
|-------|--------|--------------------|-----------------------|-----------------|
| new | hybrid | — | — | — |
| continue | hybrid + tags | source:user | source:agent (session end) | change, phase, source |
| ff | hybrid + tags | source:user | source:agent (session end) | change, phase, source |
| explore | hybrid | source:user | source:agent (session end) | change, phase, source |
| apply | hybrid + tags | source:user | source:agent (Step 7) | change, phase, source |
| verify | hybrid + tags | — | source:agent | change, phase, source |
| sync-specs | — | — | source:agent | change, phase, source |
| archive | — | — | source:agent | change, phase, source |

### Mid-flow remember

During `/opsx:continue`, `/opsx:ff`, and `/opsx:apply`, the agent watches for knowledge worth saving. When you share something like:

- "We tried X and it didn't work because Y"
- "Always do Z in this project"
- "Watch out for this edge case"

The agent recognizes it as valuable, saves it with `wt-memory remember`, and confirms:

```
[Memory saved: Learning — <one-line summary>]
```

Then continues with the current work. No interruption, no extra steps.

### Stop hook memory reminder

The memory instructions in SKILL.md are "soft hooks" — prompt-level instructions that the agent can skip. To reinforce compliance, the Claude Code Stop hook (`wt-hook-stop`) outputs a reminder when the active skill has memory steps.

**How it works:**
1. When a skill starts, `wt-skill-start` checks if the skill's SKILL.md contains `wt-memory`
2. If yes, it writes a `.wt-tools/agents/<pid>.memory` marker file
3. On every Stop event (after each agent response), `wt-hook-stop` checks for the marker
4. If found, it outputs: `[MEMORY REMINDER] Active skill has wt-memory hooks. Run your recall/remember steps before finishing.`
5. The agent sees this as a system message and is prompted to run its recall/remember steps

This is automatic — no configuration needed. The reminder fires for any skill with `wt-memory` in its SKILL.md.

### Hooks are idempotent

Running `wt-memory-hooks install` again replaces existing hooks (useful after `wt-openspec update` which overwrites SKILL.md files). The GUI can also reinstall hooks automatically after an OpenSpec update.

---

## GUI

The Control Center GUI provides memory access through the project header's context menu.

### [M] button tooltip

The `[M]` indicator in the project header row shows memory status. Hover to see: memory count, availability, and whether OpenSpec hooks are installed.

### Browse Memories

**Menu → Memory → Browse Memories...**

Opens a dialog with:
- **Search bar** — semantic search across all memories (uses `wt-memory recall`)
- **Card view** — each memory shown as a card with:
  - Type badge (color-coded: Learning=green, Decision=blue, Context=orange)
  - Content (truncated preview)
  - Tags (as hashtags)
  - Creation date
- **Status bar** — total memory count

### Remember Note

**Menu → Memory → Remember Note...**

Quick way to save a memory from the GUI:
- Select type (Learning / Decision / Context)
- Enter content (multi-line)
- Add tags (optional, comma-separated)

### Install Memory Hooks

**Menu → Memory → Install Memory Hooks**

Runs `wt-memory-hooks install` for the current project. Only appears when OpenSpec is detected and hooks are not yet installed.

---

## Ambient Memory

Developer memory works outside of OpenSpec too. The project's `CLAUDE.md` instructs agents to recognize and save valuable knowledge during any conversation.

### When agents save automatically

Agents watch for these patterns in conversation:

| Pattern | Type | Example |
|---------|------|---------|
| "We tried X and it didn't work" | Learning | "We tried websockets but Cloudflare Workers don't support them" |
| "Always / never do X in this project" | Decision | "Always use absolute imports in this codebase" |
| "Watch out for X" / "X is a gotcha" | Learning | "The CI cache invalidates when you change package.json" |
| "We decided X because Y" | Decision | "We chose pnpm over yarn because of workspace support" |

### When agents don't save

- Simple confirmations or task instructions ("fix this typo", "run tests")
- General knowledge any developer would know
- Session-specific context that won't help future agents
- When an OpenSpec skill is already running its own memory hooks (to avoid duplicates)

### How it works

1. Agent recognizes knowledge worth saving
2. Runs `wt-memory health` — if it fails, skips silently
3. Saves with appropriate type and tags
4. Confirms in one line: `[Memory saved: <Type> — <summary>]`
5. Continues with current work

---

## CLI Reference

### wt-memory

**Core Commands:**

| Command | Description |
|---------|-------------|
| `wt-memory health` | Check if shodh-memory is available |
| `wt-memory remember --type TYPE [--tags t1,t2]` | Save a memory (reads content from stdin) |
| `wt-memory recall "query" [--limit N] [--mode MODE] [--tags t1,t2]` | Semantic search (JSON output) |
| `wt-memory list [--type TYPE] [--limit N]` | List memories with optional filters (JSON output) |
| `wt-memory status [--json]` | Show config, health, and memory count |
| `wt-memory projects` | List all projects with memory counts |

**Forget / Cleanup:**

| Command | Description |
|---------|-------------|
| `wt-memory forget <id>` | Delete a single memory by ID |
| `wt-memory forget --all --confirm` | Delete ALL memories (requires --confirm) |
| `wt-memory forget --older-than <days>` | Delete memories older than N days |
| `wt-memory forget --tags <t1,t2>` | Delete memories matching tags |
| `wt-memory forget --pattern <regex>` | Delete memories matching regex pattern |

**Introspection:**

| Command | Description |
|---------|-------------|
| `wt-memory get <id>` | Get a single memory by ID (JSON output) |
| `wt-memory context [topic]` | Condensed summary by category |
| `wt-memory brain` | 3-tier memory visualization |

**Maintenance:**

| Command | Description |
|---------|-------------|
| `wt-memory health --index` | Check index health (JSON output) |
| `wt-memory repair` | Repair index integrity |

**Global option:** `--project NAME` — override auto-detected project name.

**Valid types:** `Decision`, `Learning`, `Context`

**Recall modes** (`--mode`): `semantic` (default), `temporal`, `hybrid`, `causal`, `associative`

**Tagging convention:** `change:<name>,phase:<skill>,source:<agent|user>,<topic>`

**Examples:**

```bash
# Save a decision
echo "Use pytest-xdist for parallel testing" \
  | wt-memory remember --type Decision --tags source:user,testing,pytest

# Search with enhanced recall
wt-memory recall "testing strategy" --limit 5 --mode hybrid

# Search filtered by change
wt-memory recall "auth patterns" --tags change:add-auth --mode hybrid

# List only decisions
wt-memory list --type Decision --limit 10

# Delete old memories
wt-memory forget --older-than 180

# Check status
wt-memory status --json
```

### wt-memory-hooks

| Command | Description |
|---------|-------------|
| `wt-memory-hooks install` | Patch memory hooks into OpenSpec SKILL.md files (idempotent) |
| `wt-memory-hooks check [--json]` | Check whether hooks are installed |
| `wt-memory-hooks remove` | Remove memory hooks from OpenSpec SKILL.md files |

**Global option:** `--project NAME` — override auto-detected project name.

### /wt:memory slash command

Use `/wt:memory` inside Claude Code for quick access:

| Subcommand | Description |
|------------|-------------|
| `/wt:memory status` | Show health, count, storage path |
| `/wt:memory recall <query>` | Semantic search with formatted results |
| `/wt:memory remember <content>` | Save a memory (prompts for type and tags) |
| `/wt:memory list` | List all memories grouped by type |
| `/wt:memory browse` | Summary with recent entries (default) |

---

## Setup

### 1. Install shodh-memory

```bash
pip install shodh-memory
```

### 2. Verify

```bash
wt-memory health
wt-memory status
```

### 3. Install OpenSpec hooks (optional)

If you use OpenSpec workflows:

```bash
wt-memory-hooks install
wt-memory-hooks check   # verify
```

### Graceful degradation

If shodh-memory is not installed:
- `wt-memory remember` exits silently (exit 0) — nothing crashes
- `wt-memory recall` and `wt-memory list` return empty JSON arrays `[]`
- `wt-memory status --json` returns `{"available": false, ...}`
- GUI shows "not installed" status
- OpenSpec hooks skip silently

You can install shodh-memory at any time — existing commands and hooks will start working immediately.

---

## Architecture

<details>
<summary>Technical details (click to expand)</summary>

### Layer diagram

```
┌───────────────────────────────────────────────────┐
│                  Agent Session                     │
│                                                    │
│  ┌────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ CLAUDE.md  │  │  OpenSpec   │  │ /wt:memory │ │
│  │ (ambient)  │  │  hooks (6   │  │ (manual    │ │
│  │            │  │  phases)    │  │  slash cmd) │ │
│  └─────┬──────┘  └──────┬──────┘  └─────┬──────┘ │
│        │                │               │         │
│        └────────┬───────┴───────┬───────┘         │
│                 ▼               ▼                  │
│          ┌────────────┐  ┌──────────────┐         │
│          │ wt-memory  │  │wt-memory     │         │
│          │ (CLI)      │  │ -hooks (CLI) │         │
│          └─────┬──────┘  └──────────────┘         │
│                │                                   │
│          ┌─────▼──────────────────┐               │
│          │   shodh-memory         │               │
│          │   (Python library)     │               │
│          └─────┬──────────────────┘               │
│                │                                   │
│          ┌─────▼──────────────────┐               │
│          │   RocksDB              │               │
│          │   Per-project storage  │               │
│          │   ~/.local/share/      │               │
│          │   wt-tools/memory/     │               │
│          │   <project-name>/      │               │
│          └────────────────────────┘               │
└───────────────────────────────────────────────────┘
```

### Key design choices

- **Per-project isolation**: Each project gets its own RocksDB database. Worktrees of the same repo share memory (detected via `git worktree list`).
- **File locking**: Uses `/tmp/wt-memory-<project>.lock` to prevent concurrent RocksDB access from multiple agents.
- **Semantic search**: `recall` uses shodh-memory's built-in embedding and similarity search.
- **Marker-based hooks**: OpenSpec SKILL.md files are patched with HTML comment markers (`<!-- wt-memory hooks start/end -->`), making installation and removal clean.
- **No hard dependency**: Everything degrades gracefully. Memory is an enhancement, not a requirement.

</details>
