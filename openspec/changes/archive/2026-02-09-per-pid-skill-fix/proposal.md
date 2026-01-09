## Why

When multiple Claude agents run on the same worktree, skill tracking shows incorrect information. The legacy `current_skill` file is a single shared file — whichever agent writes last "wins", and `get_agent_skill()` falls back to this file for all agents. The result: all agents show the same skill (the last-written one) instead of their actual skill. Additionally, the `wt-skill-start` call is an LLM instruction in SKILL.md prompts, not an automatic hook — so the LLM may skip it entirely.

## What Changes

- Remove legacy `current_skill` fallback from `get_agent_skill()` in `wt-status` — only use per-PID skill files
- Remove legacy `current_skill` write from `wt-skill-start` (per-PID file is the only source of truth)
- Remove legacy `current_skill` refresh from `wt-hook-stop` (only refresh per-PID file)
- Convert skill registration from LLM instruction to automatic Claude Code hook (UserPromptSubmit) — extracts `/skill-name` from user prompt text, fires reliably on every prompt
- Clean up stale `current_skill` files (no longer used)

## Capabilities

### New Capabilities
- `skill-hook-automation`: Automatic skill registration via Claude Code hook instead of manual LLM instruction

### Modified Capabilities
- `control-center`: Skill column no longer falls back to legacy shared file; only shows per-PID skill data

## Impact

- `bin/wt-status`: `get_agent_skill()` removes `current_skill` fallback
- `bin/wt-skill-start`: Removes `current_skill` write, only writes per-PID file
- `bin/wt-hook-stop`: Removes `current_skill` refresh logic
- `.claude/settings.json` (project-level): New UserPromptSubmit hook for skill tracking (replaces failed PreToolUse/Skill approach — Skill is not in PreToolUse supported tool list)
- `.claude/skills/*/SKILL.md`: Remove manual `wt-skill-start` instruction blocks (hook handles it now)
