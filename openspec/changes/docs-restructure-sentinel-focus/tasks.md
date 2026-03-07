## 1. New doc pages (no dependencies, can be done in any order)

- [x] 1.1 Create `docs/getting-started.md` — detailed install, prerequisites with check commands, GUI deps, platform notes (Qt/conda), project registration, first-run tutorial (create worktree, open, start sentinel)
- [x] 1.2 Create `docs/worktrees.md` — worktree CLI commands (wt-new, wt-work, wt-close, wt-merge, wt-list, wt-status, wt-focus, wt-add), skills mapping (/wt:new etc.), "parallel feature development" use case from old README
- [x] 1.3 Create `docs/ralph.md` — Ralph loop commands (wt-loop start/stop/status/list/history/monitor), config, "let the agent work overnight" use case, when to use / when not to use guidance
- [x] 1.4 Create `docs/gui.md` — Control Center features, what GUI shows (agent status, context %, burn rate, Ralph progress, orchestration, team), interaction patterns (double-click, right-click, blink), config (themes, opacity, refresh), system tray, screenshots
- [x] 1.5 Create `docs/team-sync.md` — cross-machine setup (wt-control-init, wt-control-sync), merge in all content from agent-messaging.md (messaging, batch architecture, compaction, encrypted chat), cross-machine use case from old README
- [x] 1.6 Create `docs/mcp-server.md` — MCP tool reference (list_worktrees, get_ralph_status, get_worktree_tasks, get_team_status, memory MCP tools), auto-config notes, manual setup command, agent inter-visibility
- [x] 1.7 Create `docs/plugins.md` — plugin concept, planned `wt-plugin install <repo>` pattern, empty registry table (Name, Repository, Description, Status columns), how to create a plugin (brief)
- [x] 1.8 Create `docs/cli-reference.md` — full CLI command tables from old README organized by category (Worktree, Project, Ralph, Orchestration, Team & Sync, Memory, OpenSpec, Utilities), internal scripts in collapsed section
- [x] 1.9 Create `docs/configuration.md` — all config files (gui-config.json, projects.json, editor, orchestration.yaml, rules.yaml, project-knowledge.yaml) with paths, format, option reference. Cross-link orchestration directive table
- [x] 1.10 Create `docs/architecture.md` — full 4-layer architecture diagram from old README, technology table, "nested agent collaboration" vision (Layer 1/2/3), Agent Teams integration, Future Development content

## 2. Navigation on existing docs

- [x] 2.1 Add navigation header (`[< Back to README](../README.md)`) and "See also" footer to `docs/sentinel.md`
- [x] 2.2 Add navigation header and "See also" footer to `docs/orchestration.md`
- [x] 2.3 Add navigation header and "See also" footer to `docs/developer-memory.md`
- [x] 2.4 Add navigation header and "See also" footer to `docs/project-management.md`

## 3. Content consolidation

- [x] 3.1 Replace `docs/agent-messaging.md` content with redirect note: "This content has moved to [team-sync.md](team-sync.md)"
- [x] 3.2 Rewrite `docs/readme-guide.md` — new 10-section structure matching the new README, updated generation rules, updated checklist

## 4. README rewrite

- [x] 4.1 Rewrite `README.md` — sentinel-first narrative, 10 sections, 150-200 lines, feature links to doc pages, simplified architecture diagram, collapsed Related Projects, plugin section

## 5. Verification

- [x] 5.1 Verify content migration completeness — diff old README sections against new doc pages, confirm no substantive content lost
- [x] 5.2 Verify all navigation links work — every doc page has back-to-README and "See also" links, no broken relative paths
- [x] 5.3 Verify README line count is between 150-200 lines
