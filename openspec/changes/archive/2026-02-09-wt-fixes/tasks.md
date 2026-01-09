## 1. Fix wt-new path resolution

- [x] 1.1 In `gui/control_center/mixins/handlers.py`, replace `"wt-new"` with `str(SCRIPT_DIR / "wt-new")` on lines 230 and 233
- [x] 1.2 Remove the misleading comment on line 228 ("use global wt-new (from PATH), not local")

## 2. Add test coverage

- [x] 2.1 Create `tests/gui/test_14_create_worktree.py` — test that `create_worktree()` constructs commands with `SCRIPT_DIR`-based path for both project and local-repo cases
- [ ] 2.2 Run GUI tests: `PYTHONPATH=. python -m pytest tests/gui/ -v --tb=short`
