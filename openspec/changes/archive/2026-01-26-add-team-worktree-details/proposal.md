# Proposal: Add Team Worktree Details

JIRA Key: EXAMPLE-575
Story: EXAMPLE-466

## Summary

Team worktree rows should be selectable and more informative. Especially important for managing worktrees running on the current user's other machines.

## Motivation

Currently team worktree rows:
- Are not interactive (no click, no context menu)
- Show only minimal info (member name, change-id, status icon)
- Don't distinguish the current user's other machines

**Use case:** I want to see what the agent on my other machine is doing, or what's running there that I forgot about.

## Proposed Features

### 1. Team Row Selection
- Team rows are clickable (selection)
- Tooltip with detailed info
- Read-only context menu (only "View Details")

### 2. "My Other Machines" Filter
- Separate filter option: show only current user's other machines
- States: All Team / My Machines Only / Hide Team
- Own machines highlighted (different color/icon)

### 3. Team Row Details
- Last activity timestamp
- Full member name (not abbreviated)
- Agent status details (if available)

## UI Design

### Filter Button States

```
[All Team] (current)
[My Machines Only] (new)
[Hide Team]
```

### Team Row Tooltip

```
┌────────────────────────────────┐
│ john@laptop                    │
│ Change: add-feature            │
│ Status: running                │
│ Last seen: 2 min ago           │
└────────────────────────────────┘
```

### Context Menu (Read-only)

```
┌─────────────────┐
│ View Details... │
│ ─────────────── │
│ Copy Change ID  │
└─────────────────┘
```

## Scope

### In Scope
- Team row selection/tooltip
- My machines filter
- Last seen timestamp display
- Read-only context menu

### Out of Scope
- Remote actions (stop agent, etc.)
- Full worktree details dialog
- Chat from context menu
