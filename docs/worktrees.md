[< Back to README](../README.md)

# Worktree Management

Git worktrees let you work on multiple branches simultaneously — each in its own directory, with its own editor and Claude Code session. wt-tools wraps git worktree commands with editor integration, Claude Code auto-launch, and status tracking.

## CLI Commands

| Command | Description |
|---------|-------------|
| `wt-new <change-id>` | Create new worktree + branch (`change/<change-id>`) |
| `wt-work <change-id>` | Open worktree in editor + start Claude Code |
| `wt-close <change-id>` | Close worktree (removes directory and branch) |
| `wt-merge <change-id>` | Merge worktree branch back to main |
| `wt-add [path]` | Add existing repo or worktree to wt-tools |
| `wt-list` | List all active worktrees |
| `wt-status` | JSON status of all worktrees and agents |
| `wt-focus <change-id>` | Focus editor window for a worktree |

## Claude Code Skills

Every CLI command has a matching slash command — manage worktrees without leaving the agent:

| Skill | CLI Equivalent |
|-------|---------------|
| `/wt:new <change-id>` | `wt-new` |
| `/wt:work <change-id>` | `wt-work` |
| `/wt:list` | `wt-list` |
| `/wt:close <change-id>` | `wt-close` |
| `/wt:merge <change-id>` | `wt-merge` |

## Typical Workflow

```bash
# Create a worktree for a new feature
wt-new add-user-auth

# Open it — editor + Claude Code launch automatically
wt-work add-user-auth

# ... work on the feature ...

# Merge back to main when done
wt-merge add-user-auth

# Clean up
wt-close add-user-auth
```

## Parallel Feature Development

You have a big feature and a bug to fix. Instead of stashing and switching branches, create two worktrees:

```bash
wt-new add-user-auth     # worktree 1: big feature
wt-new fix-login-bug     # worktree 2: quick bugfix
```

Each gets its own directory, branch, and Claude session. Work on the bugfix, merge it, close it — while the auth feature keeps going untouched.

```bash
wt-merge fix-login-bug   # merge bugfix to main
wt-close fix-login-bug   # clean up
# add-user-auth is still there, agent still has context
```

## Stay in the Agent

Every wt-tools operation has a matching Claude Code slash command:

```
> /wt:new fix-payment-bug       # creates worktree, stay in Claude
> /wt:list                       # see all worktrees
> /wt:merge fix-payment-bug      # merge back when done
> /wt:close fix-payment-bug      # clean up
```

The MCP server also lets your agent see what other worktrees and agents are doing — check team status, read other worktrees' task lists, and see Ralph loop progress without leaving the conversation.

## Editor Configuration

```bash
wt-config editor list           # list supported editors
wt-config editor set <name>     # set preferred editor (zed, vscode, cursor, windsurf)
```

`wt-work` and GUI double-click open the worktree in the configured editor and start Claude Code automatically.

---

*See also: [Getting Started](getting-started.md) · [Ralph Loop](ralph.md) · [CLI Reference](cli-reference.md) · [Control Center GUI](gui.md)*
