## 1. Spec resolution in find_input()

- [ ] 1.1 Update `find_input()` in `lib/orchestration/state.sh`: when `SPEC_OVERRIDE` is set but file doesn't exist, try `wt/orchestration/specs/${SPEC_OVERRIDE}.md` before erroring
- [ ] 1.2 Update error message to show both literal path and wt/ path that were checked
- [ ] 1.3 Ensure the resolved absolute path (not short name) is stored in `INPUT_PATH`

## 2. specs subcommand

- [ ] 2.1 Add `cmd_specs()` function to `bin/wt-orchestrate` — lists spec files in `wt/orchestration/specs/` (active first, then archive/)
- [ ] 2.2 Add `specs show <name>` — resolve short name, cat the file content
- [ ] 2.3 Add `specs archive <name>` — move spec from top-level to archive/ using `git mv` (or `mv`)
- [ ] 2.4 Add `specs` to the case statement in `bin/wt-orchestrate` main dispatcher
- [ ] 2.5 Update `usage()` help text with specs subcommand documentation
- [ ] 2.6 Graceful handling when `wt/orchestration/specs/` doesn't exist

## 3. Legacy spec migration

- [ ] 3.1 Update `cmd_migrate()` in `bin/wt-project`: detect `docs/v[0-9]*.md` files and move them to `wt/orchestration/specs/archive/` using `git mv`
- [ ] 3.2 Print migration message for detected legacy spec files in `scaffold_wt_directory()` legacy detection

## 4. Testing

- [ ] 4.1 Test spec resolution: literal path wins, short name resolves, subdirectory resolves, missing errors with both paths
- [ ] 4.2 Test `specs` list output format (active + archived)
- [ ] 4.3 Test `specs archive` moves file correctly
- [ ] 4.4 Test legacy spec migration detects `docs/v*.md` pattern
