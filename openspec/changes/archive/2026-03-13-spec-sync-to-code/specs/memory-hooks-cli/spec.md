## REMOVED Requirements

### Requirement: wt-memory-hooks install command
**Reason**: DEPRECATED — The 5-layer hook system in `settings.json` (deployed by `wt-deploy-hooks` via `wt-project init`) now handles all memory operations. Inline SKILL.md patching is no longer needed.
**Migration**: Use `wt-project init` to deploy hooks. The `check` and `remove` subcommands still exist for legacy cleanup.

### Requirement: Hook content and placement
**Reason**: DEPRECATED — Memory hooks are now in `settings.json` event handlers, not inline in SKILL.md files.
**Migration**: Hooks are automatically deployed by `wt-deploy-hooks`.

### Requirement: wt-memory-hooks check command
**Reason**: DEPRECATED — Hook status is managed by `wt-deploy-hooks` and `wt-project init`.
**Migration**: Run `wt-project init` to ensure hooks are deployed.

### Requirement: wt-memory-hooks remove command
**Reason**: DEPRECATED — Still functional for removing legacy inline hooks from SKILL.md files.
**Migration**: Run `wt-memory-hooks remove` to clean up, then `wt-project init` to deploy the new hook system.
