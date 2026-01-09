# Change: Add Claude Code Skill for Worktree Management

JIRA Key: EXAMPLE-525
Story: EXAMPLE-466

## Why
A Claude Code agent needs to manage worktrees programmatically - both from a central "control" agent that orchestrates multiple work items, and from within a specific worktree where the agent can manage its own lifecycle (push, close, merge).

Currently wt-* commands are bash scripts that require manual invocation. A Claude Skill would enable agent-to-agent coordination and self-management.

## What Changes
- Add new skill definition file `.claude/skills/wt.md`
- Skill exposes all wt-* commands with structured prompts
- Two usage modes:
  1. **Central control**: Agent in main worktree manages other worktrees
  2. **Self-control**: Agent in a worktree manages its own state
- Context-aware behavior (detects if running in worktree)

## Impact
- Affected specs: New `wt-skill` capability
- Affected code: `.claude/skills/wt.md` (new file)
- No changes to existing wt-* scripts
