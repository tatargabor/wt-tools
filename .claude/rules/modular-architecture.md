# Modular Architecture

wt-tools is a **framework** — project-specific logic lives in separate packages (wt-project-web, wt-project-base, etc.), not in wt-tools core.

## Rules

1. **Never hardcode project-specific patterns in wt-tools core.** Web-specific rules (IDOR checks, auth middleware, API patterns) belong in `wt-project-web`. Python-specific patterns belong in a Python profile package. wt-tools provides the abstraction layer (profiles, hooks, config), not the concrete implementations.

2. **Profile system is the extension point.** Project-specific behavior flows through `profile.detect_test_command()`, `profile.security_rules_paths()`, `profile.generated_file_patterns()`, etc. When adding new project-aware behavior, add it to the profile interface first, then implement in the appropriate wt-project-* package.

3. **Config resolution order matters.** Always use `config.auto_detect_test_command()` (profile → legacy fallback), not inline PM detection. The config module handles the resolution chain.

4. **Changes to wt-tools deploy to consumer projects via `wt-project init`.** Any file under `.claude/` that wt-tools generates must be deployable. Test changes against at least one consumer project.

5. **OpenSpec artifacts must be generic.** No project-specific names, paths, or metrics in proposals/designs/tasks/specs. Generalize findings before writing artifacts.
