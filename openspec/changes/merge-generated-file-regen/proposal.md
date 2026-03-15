## Why

Lock file merge conflicts are the most persistent recurring issue across E2E runs — appearing in runs #3, #8, and #13. The current merge pipeline handles lock file conflicts by accepting "ours" (target branch version), which **silently discards feature branch dependencies**. This can lead to runtime failures when the merged code references packages that exist in the feature's `package.json` but not in the regenerated lock file.

### Evidence from E2E runs

| Run | File | Impact | Resolution |
|-----|------|--------|------------|
| #3 | pnpm-lock.yaml | Merge-blocked, sentinel manual fix | `pnpm install --no-frozen-lockfile` |
| #8 | pnpm-lock.yaml | Merge-blocked | Manual conflict resolution |
| #13 (Bug #24) | pnpm-lock.yaml + `.wt-tools/.last-memory-commit` | Merge-blocked, 11 leftover conflict markers | `git checkout --ours` + `pnpm install` |

### Root cause analysis

The merge pipeline has 5 conflict resolution layers (auto-resolve → JSON merge → LLM resolve → agent rebase → fingerprint dedup), but generated files need a fundamentally different strategy: **regenerate, don't merge**.

Current flow for lock files:
```
conflict detected → auto_resolve_generated_files() → git checkout --ours → done
                                                      ^^^ WRONG: discards feature deps
```

Correct flow:
```
conflict detected → auto_resolve_generated_files() → git checkout --ours → regenerate lock file → done
                                                                            ^^^ pnpm/yarn/npm install
```

Additionally, `.wt-tools/` runtime files (`.last-memory-commit`, agent state) sometimes get committed by worktree agents and block merge. These should be cleaned before merge, not resolved during.

### Current code locations

- `bin/wt-merge:45-134` — `GENERATED_FILE_PATTERNS` list and `auto_resolve_generated_files()`
- `bin/wt-merge:511-554` — pre-merge stashing
- `lib/wt_orch/merger.py:314-380` — merge orchestration calling `wt-merge`
- `lib/wt_orch/merger.py:561-584` — `_post_merge_deps_install()` (only runs if package.json changed)
- `lib/wt_orch/dispatcher.py:46-60` — `GENERATED_FILE_PATTERNS` and `LOCKFILE_PM_MAP`
- `lib/wt_orch/dispatcher.py:150-165` — worktree sync generated file handling

## What Changes

### 1. Lock File Regeneration After Conflict Resolution
- After `auto_resolve_generated_files()` accepts "ours" for lock files, detect which lock file was conflicted
- Run the appropriate package manager install to regenerate:
  - `pnpm-lock.yaml` → `pnpm install --no-frozen-lockfile`
  - `yarn.lock` → `yarn install`
  - `package-lock.json` → `npm install`
- Stage the regenerated lock file and amend the merge commit
- This ensures both sides' dependencies are present

### 2. Unconditional Post-Merge Dependency Install
- `_post_merge_deps_install()` currently checks if `package.json` changed — but lock file conflicts can occur even when only the lock file differs (transitive dependency updates)
- Change: always run dependency install after merge if a lock file was in the conflict set, regardless of package.json changes

### 3. Pre-Merge Runtime File Cleanup
- Before merge, remove `.wt-tools/` runtime files from the worktree's git index:
  - `.wt-tools/.last-memory-commit`
  - `.wt-tools/agents/`
  - `.wt-tools/orphan-detect/`
- Add these to the worktree's `.gitignore` if not already present
- Prevent worktree agents from committing runtime state files

### 4. Worktree Sync Improvement
- `sync_worktree_with_main()` in dispatcher.py uses same "ours" strategy — apply same regeneration logic
- After sync merge, regenerate lock file in the worktree too

## Capabilities

### New Capabilities
- `lockfile-regeneration-on-conflict`: Auto-regenerate lock files after merge conflict resolution instead of using stale "ours" version
- `pre-merge-runtime-cleanup`: Remove `.wt-tools/` runtime files from git index before merge

### Modified Capabilities
- `merge-conflict-resolution`: Lock file conflicts trigger regeneration, not just "ours" acceptance
- `post-merge-dependency-install`: Runs unconditionally when lock files were in conflict set
- `worktree-sync`: Applies same regeneration logic after syncing worktree with main

## Impact

- **Modified**: `bin/wt-merge` — add lock file regeneration after auto-resolve
- **Modified**: `lib/wt_orch/merger.py` — pass conflict file list to post-merge pipeline, unconditional deps install on lock conflict
- **Modified**: `lib/wt_orch/dispatcher.py` — lock file regeneration in worktree sync
- **New logic**: Pre-merge cleanup of `.wt-tools/` runtime files in worktree git index
- **Risk**: Lock file regeneration adds ~10-30s to merge time (acceptable for preventing recurring failures)
- **No breaking changes**: Existing behavior preserved for non-lock-file conflicts
