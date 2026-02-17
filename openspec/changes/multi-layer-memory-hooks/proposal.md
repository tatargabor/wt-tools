## Why

The current memory hook system has two hooks (UserPromptSubmit recall, Stop save) but recall only fires on "change boundaries" (when a new OpenSpec change name is detected). This means: (1) explore mode gets no automatic recall because there's no change name, (2) intermediate steps like DB queries don't trigger recall even when relevant memories exist, (3) errors that were solved before get repeated because recall doesn't fire mid-conversation, and (4) without OpenSpec the hooks are nearly useless. Users have resorted to manually writing "always use wt:memory" in CLAUDE.md to force the agent to recall. Comparing with shodh-memory's reference implementation (v0.1.80), they use 6 hook types covering the full agent lifecycle with `additionalContext` injection. We need a similar multi-layer approach that works with AND without OpenSpec.

## What Changes

- **New SessionStart hook** (L1): Loads a project-specific "operational cheat sheet" from memory at session start, writes to `.claude/memory-context.md` for automatic context inclusion
- **Rewrite UserPromptSubmit recall hook** (L2): Topic-based recall from prompt text instead of change-boundary detection; uses `additionalContext` JSON output for automatic injection; works without OpenSpec
- **New PreToolUse hook** (L3): Pattern-matches Bash commands against "hot topics" (database, API, deploy, auth); runs background-parallel recall; only fires on matching patterns, zero overhead otherwise
- **New PostToolUse hook** (L4): Fires on Bash errors (non-zero exit); parses error text as recall query; surfaces past fixes for the same error pattern
- **Enhanced Stop hook** (L5): Existing haiku transcript extraction stays; adds interactive cheat sheet curation (asks if recurring patterns should be promoted to L1 cheat sheet); auto-tags errors with hot-topic categories for L3/L4 discoverability
- **Updated wt-deploy-hooks**: Deploys all 5 hook types instead of 2; maintains `--no-memory` flag for baselines
- **Hot topics config**: Static base list (psql, mysql, curl, docker, ssh, etc.) plus memory-tag-learned extensions

## Capabilities

### New Capabilities
- `session-warmstart`: SessionStart hook that loads critical operational memories into a context file at session begin
- `hot-topic-recall`: PreToolUse hook matching Bash commands against configurable hot-topic patterns, triggering parallel memory recall
- `error-recovery-recall`: PostToolUse hook that recalls memories on Bash errors and auto-saves user fixes for future sessions
- `cheat-sheet-curation`: Interactive session-end promotion of recurring patterns to persistent operational cheat sheet

### Modified Capabilities
- `auto-memory-hooks-deploy`: Deploy script must handle 4 new hook types (SessionStart, PreToolUse, PostToolUse, plus enhanced Stop) alongside existing 2
- `smart-memory-recall`: Remove change-boundary limitation; switch to topic-based recall with `additionalContext` output; must work without OpenSpec

## Impact

- **bin/wt-hook-memory-recall**: Full rewrite — topic-based recall with `additionalContext` JSON output
- **bin/wt-hook-memory-save**: Enhanced — cheat sheet curation, hot-topic auto-tagging
- **bin/wt-hook-memory-warmstart**: New script — SessionStart hook
- **bin/wt-hook-memory-pretool**: New script — PreToolUse hot-topic hook
- **bin/wt-hook-memory-posttool**: New script — PostToolUse error recovery hook
- **bin/wt-deploy-hooks**: Updated — deploys all hook types
- **.claude/settings.json**: Updated — 4 new hook event entries
- **install.sh**: Updated — symlinks new hook scripts
- **Latency**: L3 adds ~150ms only on hot-topic Bash commands; all other Bash calls unaffected
- **Dependencies**: No new external dependencies (uses existing wt-memory CLI + shodh-memory server)
