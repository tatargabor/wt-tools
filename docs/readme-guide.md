# README Generation Guide

This document defines the structure, content rules, and style for `README.md`. It serves as the authoritative source of truth for both manual edits and AI-assisted README generation.

---

## Mandatory Sections (in order)

The README MUST contain these sections in this exact order:

### 1. Header
- Project name: `# wt-tools`
- One-line tagline describing the project
- "Latest update" date badge

### 2. Overview
- 3-5 sentences explaining what wt-tools is and who it's for
- Screenshot of Control Center GUI (`docs/images/control-center.gif`)
- Keep it high-level — details come later

### 3. Platform & Editor Support
- Table format with status indicators
- Required entries:

| Platform/Tool | Status | Notes column |
|---------------|--------|--------------|
| Linux | Primary | |
| macOS | Supported | |
| Windows | Not supported | |
| Zed | Primary editor | |
| VS Code | Basic support | |
| Claude Code | Integrated | |

- Update this table when platform support changes

### 4. How It Works
- Architecture diagram (CLI + GUI + MCP layers)
- Technologies table (Bash, PySide6, Python, JSON/git, NaCl)
- "What the GUI shows you" — agent status, context %, burn rate, Ralph progress, team
- Interactive walkthrough: double-click, blinking rows, right-click context menu

### 5. Quick Start
- 5 steps maximum: install → register project → launch GUI → create worktree → work
- Each step: one command + one-line explanation
- Must be copy-pasteable

### 6. Features
- Brief overview of each major feature area:
  - **Control Center GUI** — status table, shortcuts, themes
  - **CLI Tools** — worktree commands, project management
  - **Ralph Loop** — autonomous agent loop
  - **Team Sync & Messaging** — cross-machine coordination
  - **Developer Memory** (see detailed instructions below)
  - **MCP Server** — Claude Code tool integration
- Keep each to 2-4 lines, link to detail sections below
- **Developer Memory subsection detailed instructions:**
  - One paragraph overview: per-project cognitive memory powered by shodh-memory, agents save decisions/learnings/context, future agents recall relevant past experience
  - Three concrete inline examples (one sentence each):
    1. Negative experience recall: "An agent saves that RocksDB crashes without file locking → months later, another agent avoids the same mistake"
    2. OpenSpec automatic hooks: "When starting a new change, memory hooks recall past decisions about the same topic"
    3. Mid-flow learning: "During implementation, the agent saves non-obvious constraints the user shares"
  - **OpenSpec memory hook coverage matrix**: Include a table showing which OpenSpec skills have which memory integration. Columns: Skill, Recall, Mid-flow User Save, Agent Self-Reflection, Structured Tags. Rows: new, continue, ff, explore, apply, verify, sync-specs, archive. Use checkmarks for coverage, dashes for n/a. This helps users understand that agent insights are captured across the entire OpenSpec lifecycle — not just at archive time.
  - CLI quick-start: mention `wt-memory remember`, `wt-memory recall`, `wt-memory status`, `wt-memory forget`, `wt-memory context`
  - GUI: mention [M] button for browsing and saving memories
  - Link to `docs/developer-memory.md` for full documentation
  - Mark as **(Experimental)** — note graceful degradation if shodh-memory not installed

### 7. Installation
- Prerequisites table (Git, Python 3.10+, jq, Node.js)
- Clone + install.sh commands
- GUI dependencies (`pip install PySide6 ...`)
- Platform-specific notes (Qt/conda on Linux)

### 8. CLI Reference
- Categorized tables of all user-facing `bin/wt-*` commands
- Categories: Worktree Management, Project Management, Ralph Loop, Team & Sync, Developer Memory, Utilities
- Internal/hook scripts (wt-common.sh, wt-hook-*) get a brief note, not full table entries
- Each command: name + one-line description
- **Developer Memory category must include:** `wt-memory remember`, `wt-memory recall`, `wt-memory list`, `wt-memory status`, `wt-memory forget`, `wt-memory context`, `wt-memory brain`, `wt-memory get`, `wt-memory repair`, `wt-memory-hooks install`, `wt-memory-hooks check`

### 9. Configuration
- Config file locations table
- GUI settings JSON example
- Color profiles list

### 10. Known Issues & Limitations
- Table or bullet list format
- Must cover: platform quirks, editor-specific issues, areas in active development
- Each entry: issue + workaround (if any)
- Update when issues are resolved or new ones discovered

### 11. Claude Code Integration
- Auto-launch behavior
- Claude slash commands (skills)
- MCP server setup
- Status line integration

### 12. Contributing
- Brief paragraph + link to `CONTRIBUTING.md`
- Do NOT duplicate CONTRIBUTING.md content

### 13. Use Cases
- Practical examples showing when and why each feature is useful
- Start from basics (why the GUI?) and build up to advanced (Ralph Loop, Team Sync, Developer Memory)
- Include CLI examples and ASCII sketches where helpful
- End with a "When to use what" summary table
- Keep it grounded — honest about what works well and what's experimental
- **Developer Memory use case instructions:**
  - Title: "Developer Memory: agents that learn across sessions"
  - Scenario 1: Cross-session recall — an agent saves a failure or decision, months later a different agent recalls it and avoids the same mistake. Show `wt-memory remember` and `wt-memory recall` commands with realistic content.
  - Scenario 2: OpenSpec integration — when starting a new change (`/opsx:new`), memory hooks automatically recall related past work. Show what the agent sees and how it changes behavior.
  - Include a "Best for" line: projects with multiple agents or contributors over time, where institutional knowledge matters.
  - Mark as experimental. Link to `docs/developer-memory.md`.
  - Add entry to the "When to use what" summary table: "Want agents to learn from past sessions" → "Developer Memory (`wt-memory remember/recall`)"

### 14. Related Projects
- Categorized tables: Worktree+Agent Managers, Multi-Agent Orchestration, Desktop Apps & Monitoring
- Include star counts for context
- Feature comparison matrix (ASCII table): GUI, Worktree, Ralph Loop, Team Sync, MCP, Cross-Platform
- Update periodically — this space moves fast

### 15. Future Development
- Agent Teams integration diagram (outer loop = wt-tools, inner loop = Agent Teams)
- Planned integrations table with status (Available now / Experimental / Future)
- Vision diagram: layered collaboration (Layer 1: within worktree, Layer 2: cross-worktree MCP, Layer 3: cross-machine sync)
- Keep honest about what's available now vs speculative

### 16. License
- One line + link to LICENSE file

---

## Project Context & Messaging

These points define how to describe the project's purpose, status, and direction. Use them in the Overview, Features, and Known Issues sections as appropriate.

### Purpose
wt-tools aims to elevate the Claude Code experience — reducing technical friction between context switches and making multi-project, multi-agent usage pleasant with a minimal, cross-platform UI.

### Development Approach
- wt-tools is workflow-agnostic — users can use any task tracking approach (tasks.md, issue trackers, etc.)
- The project is useful today, though its long-term role is hard to predict — AI tooling evolves fast and something may eventually replace it, but right now it fills a real gap

### Team Sync
- Team features (wt-control branch, messaging, cross-machine sync) are **experimental**
- The goal: higher-level collaboration between team members and machines **without a central server** — using a git technical branch instead
- Claude Code's own Teams feature does not replace wt-tools team sync — it complements it. wt-tools operates at the agent level, so different remote machines, users, or local agents can coordinate at a higher level than what Claude Teams alone provides. This is experimental.

### Cross-Platform & UI
- UI compactness is an ongoing challenge, especially when working across many projects. New ideas for reducing clutter come up regularly
- Cross-platform testing (Linux + macOS) needs significant community help — contributions and bug reports are highly valued

---

## Tone & Style Rules

1. **Language**: English only
2. **Voice**: Technical but accessible — assume the reader knows git and CLI basics but not the project internals
3. **Sentences**: Concise, active voice. Avoid filler words
4. **Formatting**:
   - Use tables for structured reference data (commands, config, platform support)
   - Use bullet lists for feature descriptions
   - Use code blocks for commands and config examples
   - Use `---` horizontal rules between major sections
5. **Jargon**: Define project-specific terms on first use (Ralph Loop, wt-control branch)
6. **Length**: Aim for scannable. Use `<details>` collapsed sections for rarely-needed info
7. **Emoji**: Avoid in prose. OK in status indicators (tables)

---

## CLI Documentation Rules

When documenting CLI tools:

- **User-facing commands** (wt-new, wt-work, wt-list, wt-close, wt-merge, wt-status, wt-loop, wt-project, wt-usage, wt-config, wt-control, wt-version, wt-deploy-hooks, wt-focus): Full table entry with description
- **Internal/hook scripts** (wt-common.sh, wt-hook-skill, wt-hook-stop, wt-skill-start, wt-control-init, wt-control-sync, wt-control-chat, wt-control-gui, wt-completions.*): Mention in an "Internals" note, not in the main CLI table
- **Discovering new commands**: Run `ls bin/wt-*` and cross-reference with the CLI Reference section

---

## Update Checklist

When modifying the README, verify these items:

- [ ] All sections from the mandatory list are present and in order
- [ ] "Latest update" date is current
- [ ] Platform & Editor Support table reflects current reality
- [ ] CLI Reference includes all user-facing `bin/wt-*` commands (run `ls bin/wt-*` to check)
- [ ] Known Issues section is up to date
- [ ] Screenshot is current (regenerate if GUI changed significantly)
- [ ] No broken internal links
- [ ] Code examples are copy-pasteable and correct

---

## AI Generation Instructions

When using an LLM to regenerate the README:

1. Provide this guide as context
2. Provide the current `bin/` directory listing for CLI completeness
3. Provide any recent changelog or feature additions
4. The LLM should follow the mandatory section order exactly
5. The LLM should read existing `bin/wt-*` scripts' `--help` output for accurate CLI descriptions
6. Output should be a complete, standalone README.md — not a diff or partial update
