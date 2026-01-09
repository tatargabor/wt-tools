## Architecture

The change touches 4 layers, each with minimal modifications:

```
bin/wt-common.sh          New helper: get_main_branch()
       │
bin/wt-status              Remove main repo filter, add is_main_repo flag
bin/wt-work                Main branch detection → skip worktree creation
bin/wt-focus               Main branch detection → use project_path directly
       │
gui/workers/status.py      No changes (passes through JSON)
       │
gui/control_center/
  mixins/table.py           ★ prefix, sort main repo first
  mixins/menus.py           Filter context menu for is_main_repo
  mixins/handlers.py        Double-click/focus uses branch name as change_id
```

### Data Flow

```
wt-status --json
    │
    │  For each project:
    │    1. Main repo entry (is_main_repo: true, change_id: "master")
    │    2. Worktree entries (is_main_repo: false, change_id: "my-feature")
    │
    ▼
StatusWorker (gui/workers/status.py)
    │
    │  self.worktrees = [...] — includes main repo entries
    │
    ▼
TableMixin.refresh_table_display()
    │
    │  Sort: main repo first per project (is_main_repo flag)
    │  Render: ★ prefix in Change column
    │  Map: row_to_worktree includes main repo entries
    │
    ▼
MenusMixin.show_row_context_menu()
    │
    │  Check wt.get("is_main_repo") → exclude worktree-only actions
    │
    ▼
HandlersMixin.on_double_click() / on_focus()
    │
    │  wt-work / wt-focus called with branch name as change_id
    │  These scripts detect main branch → use project_path directly
```

## Key Decisions

### 1. Main branch detection via `git symbolic-ref`

Use `git -C "$project_path" symbolic-ref --short HEAD` to detect the main branch name. This handles both `master` and `main` conventions without hardcoding.

**Alternative considered**: Hardcode `master`/`main` list — rejected because repos may use other branch names.

### 2. `is_main_repo` flag in JSON (not separate data path)

The main repo entry uses the same JSON structure as worktrees with an added `is_main_repo: true` field. This keeps the GUI code unified — same rendering, same status detection, same row mapping.

**Alternative considered**: Separate main repo data structure — rejected because it would require parallel code paths in the GUI.

### 3. `wt-work` and `wt-focus` enhanced (not bypassed)

Instead of adding separate logic in the GUI for opening/focusing the main repo, we enhance `wt-work` and `wt-focus` to handle the main branch natively. This keeps the GUI simple (always calls same scripts) and makes the CLI tools more capable.

### 4. Context menu filtering (not separate menu)

A single `show_row_context_menu` method with `is_main_repo` checks, rather than a separate `show_main_repo_context_menu` method. The overlap is ~90%, so a few `if not is_main_repo:` guards are cleaner than duplication.

### 5. `change_id` field reused for branch name

For main repo entries, `change_id` contains the branch name (e.g., `"master"`). This is a semantic stretch but avoids adding a new field and keeps the GUI rendering logic unchanged.

## Edge Cases

### Detached HEAD on main repo
If the main repo is in detached HEAD state, `git symbolic-ref` fails. Fallback: use `git rev-parse --short HEAD` to show the commit hash as change_id. The entry still appears but with a hash instead of branch name.

### Main repo on a non-default branch
If someone checks out a feature branch directly in the main repo (not via worktree), the entry shows that branch name. This is correct behavior — it reflects reality.

### No worktrees exist for a project
The main repo entry still appears (project header + main repo row). This is the desired behavior — the user can see and interact with the project even without worktrees.

### Filter mode (editor-open filter)
When the editor-open filter is active, the main repo should be included if the editor has the main repo path open. The existing `editor_paths` check works unchanged since it's path-based.
