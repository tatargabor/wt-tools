## Context

The current memory hook system uses 2 Claude Code hook events: `UserPromptSubmit` (recall) and `Stop` (save). Recall only fires on OpenSpec "change boundaries" — when a new change name is detected in the prompt. This means explore mode, non-OpenSpec usage, and intermediate steps (like DB queries triggered mid-task) get zero automatic memory injection.

Comparing with the shodh-memory reference implementation (v0.1.80), they use 6 hook lifecycle events with `additionalContext` injection. Users have had to manually add "always use wt:memory" to CLAUDE.md to compensate.

### Claude Code Hook API (from official docs)

Key capabilities we'll leverage:
- **`additionalContext`**: Available on SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure — injects text into Claude's context
- **`PostToolUseFailure`**: Separate event that fires specifically when tools fail (not PostToolUse) — ideal for error recovery
- **PreToolUse matcher `"Bash"`**: Matches tool name, then script parses `tool_input.command` for patterns
- **Plain text stdout on UserPromptSubmit/SessionStart**: Automatically added as context (exit 0)
- **async hooks**: Available but NOT useful for PreToolUse (can't inject context before tool runs)

## Goals / Non-Goals

**Goals:**
- Memory recall fires on every user prompt (L2), not just change boundaries
- Hot-topic commands (DB, API, deploy) get proactive memory injection before execution (L3)
- Tool failures trigger automatic error-pattern recall (L4)
- Session starts with relevant project context pre-loaded (L1)
- All layers work without OpenSpec — OpenSpec enriches but isn't required
- Existing haiku transcript extraction (L5) enhanced with cheat-sheet curation
- Minimal latency: 0ms for non-hot-topic Bash, ~150ms for hot-topic Bash, ~200ms for prompt recall

**Non-Goals:**
- MCP server for memory (out of scope — keep CLI-based for now)
- Read tool content parsing (detecting DB references in file contents — too complex, too slow)
- Real-time memory streaming during tool execution
- Cross-session cheat sheet sharing (each machine has its own)

## Decisions

### Decision 1: Five-layer hook architecture

**Choice**: Implement 5 layers using 4 new/modified hook events (SessionStart, UserPromptSubmit, PreToolUse/PostToolUseFailure, Stop).

**Alternatives considered**:
- Single omniscient hook on UserPromptSubmit: simpler but can't help mid-task
- MCP server approach (like shodh-memory): more powerful but larger scope, new dependency
- Skill-embedded instructions only: already proven unreliable on fresh installs

**Rationale**: Each layer catches different situations. L2 catches intent ("what does the user want?"), L3 catches action ("what is the agent doing?"), L4 catches outcome ("what went wrong?"). No single layer covers all three.

### Decision 2: Use `PostToolUseFailure` (not `PostToolUse`) for L4

**Choice**: Hook into `PostToolUseFailure` event specifically for error recovery.

**Alternatives considered**:
- PostToolUse with exit code check: PostToolUse only fires on success per docs
- PostToolUse on all Bash: would fire on every successful command too (noisy)

**Rationale**: Claude Code has a dedicated `PostToolUseFailure` event that provides `error` and `is_interrupt` fields. This is the exact trigger we need — fires only on failures, gives us the error text for recall query.

### Decision 3: Synchronous PreToolUse for hot topics (not async)

**Choice**: L3 runs synchronously before Bash execution, blocking for ~150ms on hot-topic matches.

**Alternatives considered**:
- Async PreToolUse: can't inject `additionalContext` before tool runs (per docs: "Async hooks cannot block tool calls or return decisions")
- PostToolUse with preemptive context: too late — tool already ran

**Rationale**: The whole point of L3 is injecting context BEFORE the command runs. 150ms latency is negligible for DB/deploy commands that take seconds. Non-matching Bash calls exit immediately (pattern check is ~1ms).

### Decision 4: Static + learned hot-topic patterns (hybrid)

**Choice**: Ship a hardcoded base pattern list. Extend dynamically from memories tagged `error,<topic>`.

**Base patterns** (compiled into regex):
```
DATABASE: psql|mysql|sqlite3|mongosh|prisma|sequelize|knex|typeorm
API:      curl|wget|httpie|http\s
DEPLOY:   docker|kubectl|terraform|ansible|ssh\s
AUTH:     \.env|credential|secret|password|token|\.pem|\.key
PYTHON:   python|python3|pip\s|uv\s run
NODE:     node\s|npx\s|npm\s run|bun\s run
```

**Learned extensions**: When L5 saves an error memory tagged with a category, that category's recall weight increases. Not a new regex — just broader recall queries.

**Alternatives considered**:
- Fully dynamic (learn from errors): doesn't work on fresh install
- Fully static: can't adapt to project-specific tools

### Decision 5: Topic extraction from prompt (L2) instead of change-boundary detection

**Choice**: Extract keywords from user prompt text for recall query. If OpenSpec change detected, also include change name.

**Algorithm**:
1. Extract prompt text from hook input JSON
2. If prompt contains `opsx:` or `openspec-` skill invocation → extract change name, use as primary query
3. Otherwise → use first 200 chars of prompt as recall query (wt-memory handles semantic matching)
4. Always recall, no debounce/boundary check (wt-memory proactive API handles relevance filtering)

**Alternatives considered**:
- Keep change-boundary detection + add topic fallback: complex, still misses explore
- LLM-based keyword extraction: too slow for a hook (adds 1-2s)

**Rationale**: The current change-boundary detection is the root cause of the problem. Removing it and always recalling is simpler and more reliable. `wt-memory proactive` already handles relevance scoring — low-relevance results are filtered.

### Decision 6: Cheat sheet as tagged memories (not a separate file)

**Choice**: The "operational cheat sheet" (L1) is just memories tagged `cheat-sheet` that get loaded at SessionStart.

**Alternatives considered**:
- Separate `.claude/cheat-sheet.md` file: another thing to maintain, sync issues
- Part of CLAUDE.md: can't be project-specific per machine, gets bloated

**Rationale**: Using tagged memories means: (1) cheat sheet entries are searchable by L2/L3/L4, (2) they sync via `wt-memory sync`, (3) they leverage existing importance/decay mechanics, (4) L5 can promote entries to cheat-sheet by adding the tag.

### Decision 7: L5 interactive cheat-sheet promotion

**Choice**: At session end (Stop hook), if the session had errors that were resolved, the haiku extraction step also evaluates whether the fix should be a cheat-sheet entry. Convention entries already saved as `convention` tag get automatic cheat-sheet promotion.

**Flow**:
1. Existing haiku extraction runs (unchanged)
2. If extracted memories include error→fix patterns, additionally tag with `cheat-sheet`
3. L1 picks these up on next session start

**Alternatives considered**:
- Interactive user prompt ("should this be in your cheat sheet?"): blocks session end, annoying
- Agent-based hook to decide: too slow, too expensive

**Rationale**: The user initially suggested interactive curation, but Stop hooks should be fast and non-blocking. The haiku model can decide cheat-sheet worthiness during extraction at no extra cost.

### Decision 8: Separate scripts per layer

**Choice**: Each layer is a separate script file: `wt-hook-memory-warmstart` (L1), `wt-hook-memory-recall` (L2, rewritten), `wt-hook-memory-pretool` (L3), `wt-hook-memory-posttool` (L4), `wt-hook-memory-save` (L5, enhanced).

**Alternatives considered**:
- Single script with event dispatch (like shodh-memory's memory-hook.ts): harder to debug, test, and maintain
- Inline hooks in settings.json: can't do complex logic

**Rationale**: Separate scripts are testable independently, have clear responsibility boundaries, and match our existing pattern (wt-hook-memory-recall, wt-hook-memory-save).

## Risks / Trade-offs

**[Risk] PreToolUse latency on hot-topic commands** → Mitigation: Pattern check is ~1ms (regex), only recall (~150ms) on match. Non-hot-topic Bash calls have zero overhead. Monitor with `--debug` flag.

**[Risk] Too many memories injected (context bloat)** → Mitigation: Each layer limits results (L1: 5, L2: 3, L3: 2, L4: 3). Use `additionalContext` (discrete) not plain stdout (visible). Total worst case: ~15 short memory lines.

**[Risk] wt-memory server not running** → Mitigation: Every script starts with `command -v wt-memory &>/dev/null || exit 0; wt-memory health &>/dev/null || exit 0`. Silent exit, zero impact.

**[Risk] PostToolUseFailure fires on non-error failures (user interrupt)** → Mitigation: Check `is_interrupt` field, skip if true.

**[Risk] Duplicate recall across L2 and L3** → Mitigation: L2 recalls broadly (prompt-level), L3 recalls narrowly (command-specific). Different query = different results. Even with overlap, Claude deduplicates naturally.

**[Risk] wt-deploy-hooks backwards compatibility** → Mitigation: Upgrade path already exists in deploy-hooks. Add new hook types incrementally. Existing projects get new hooks on next `wt-deploy-hooks` run.

## Open Questions

1. **L3 timeout**: Should PreToolUse have a 5s or 10s timeout? Recall usually takes <500ms but network/server issues could cause hangs. Current: propose 5s.
2. **L4 error dedup**: If the same error repeats 3 times in a session, should L4 recall on every failure or debounce? Current: propose recall every time (memories may have been saved mid-session by L5).
