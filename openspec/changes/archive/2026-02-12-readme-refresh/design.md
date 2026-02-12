## Context

The current README.md (~390 lines) covers the GUI and basic CLI well but has grown organically without a guiding structure. About 10 CLI tools in `bin/` are undocumented, there's no platform/editor support info, and no known issues section. The `docs/config.md` file has minimal doc-generation notes. There is no single source of truth for what the README should contain.

## Goals / Non-Goals

**Goals:**
- Create a `docs/readme-guide.md` that defines README structure, mandatory sections, tone, and update rules
- Rewrite README.md following the guide — comprehensive but scannable
- Document all user-facing CLI tools
- Add platform & editor support status
- Add known issues section

**Non-Goals:**
- Generating full API/developer docs (that's a separate effort)
- Auto-generating README from code (manual, guide-driven process)
- Documenting internal scripts that aren't user-facing (e.g., `wt-common.sh`)
- Changing any code or behavior — this is docs-only

## Decisions

### 1. Separate readme-guide.md file (not inline in config.md)

**Decision**: Create `docs/readme-guide.md` as a standalone file.

**Rationale**: The guide will be ~100+ lines with section templates, tone rules, and checklists. Embedding this in `docs/config.md` would make that file unwieldy. A standalone file is also easier to reference from CLAUDE.md or other tooling.

**Alternative considered**: Expanding `docs/config.md` — rejected because config.md serves a different purpose (repo metadata, doc generation settings).

### 2. README structure: overview-first, details-later

**Decision**: Restructure README to lead with a short overview + screenshot, then Quick Start, then features, then detailed sections.

**Rationale**: New visitors need to understand what this is in 10 seconds. Current README jumps straight into GUI details. The "inverted pyramid" pattern (overview → details) is standard for popular open-source projects.

### 3. CLI tool documentation scope

**Decision**: Document all user-facing `bin/wt-*` commands. Internal helpers (`wt-common.sh`) and hook scripts (`wt-hook-skill`, `wt-hook-stop`) get a brief mention in an "Internals" note, not full docs.

**Rationale**: Users need to know about `wt-config`, `wt-version`, `wt-deploy-hooks`, `wt-focus`, etc. But hook scripts are auto-installed and not manually invoked — cluttering the CLI table with them reduces clarity.

### 4. Known Issues as living section

**Decision**: Add a "Known Issues & Limitations" section with current platform/editor quirks.

**Rationale**: Setting honest expectations builds trust. This section covers: Zed as primary editor, Qt/conda conflicts on Linux, macOS workarounds, Windows not supported, and editor detection edge cases.

### 5. readme-guide.md serves as generation instructions

**Decision**: The guide doubles as both human-readable documentation policy AND instructions for AI-assisted README regeneration.

**Rationale**: When running docs generation (or asking Claude to update the README), the guide provides the authoritative structure. This avoids ad-hoc generation that drifts from the intended format.

## Risks / Trade-offs

- **[Guide drift]** → The guide may become outdated as features change. **Mitigation**: The guide includes an "Update Checklist" section reminding authors to verify sections after feature changes.
- **[README length]** → Adding all CLI tools + platform info may make the README too long. **Mitigation**: Use collapsed sections (`<details>`) for rarely-needed info, keep main sections concise with links to full docs.
- **[Incomplete CLI docs]** → Some bin/ scripts may need investigation to document accurately. **Mitigation**: Read each script's help/usage output during implementation.
