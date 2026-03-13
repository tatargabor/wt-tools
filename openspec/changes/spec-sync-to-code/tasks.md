## 1. Apply MODIFIED delta specs

- [x] 1.1 Apply editor-integration delta — remove keystroke automation, WM_CLASS filtering, accessibility requirements; simplify worktree opening and window focus specs
- [x] 1.2 Apply worktree-tools delta — add wt-new undocumented features (--branch, --skip-fetch, --new, env bootstrap, dep install, hook deploy, auto-open); add wt-close --keep-branch/--delete-remote/non-TTY; add wt-list --remote; update wt-add change-id derivation; remove openspec init and bare repo requirements
- [x] 1.3 Apply merge-conflict-fingerprint delta — add ASPIRATIONAL status marker to all requirements
- [x] 1.4 Apply agent-merge-resolution delta — add ASPIRATIONAL status marker to both requirements
- [x] 1.5 Apply smart-memory-recall delta — remove memory count guard requirement
- [x] 1.6 Apply orchestration-token-tracking delta — change R1 fallback from JSONL estimation to return 0
- [x] 1.7 Apply ralph-team-lifecycle delta — remove graceful teammate shutdown requirement; keep cleanup and orphan detection
- [x] 1.8 Apply ralph-team-prompt delta — remove 3+ task threshold rule and TaskCreate/TaskUpdate tracking requirement
- [x] 1.9 Apply orchestration-config delta — fix max_parallel default from 2 to 3

## 2. Create new spec

- [x] 2.1 Create merge-worktree spec — new spec for wt-merge covering CLI interface, multi-layer conflict resolution, generated file patterns, JSON deep merge, LLM resolution, model escalation, pre-merge auto-commit, post-merge cleanup

## 3. Archive OBSOLETE specs

- [x] 3.1 Archive memory-hooks-cli — mark all 4 requirements as REMOVED/DEPRECATED (install, hook content, check, remove)
- [x] 3.2 Archive memory-hooks-gui — mark all 3 requirements as REMOVED/DEPRECATED (install action, auto-reinstall, FeatureWorker cache)
