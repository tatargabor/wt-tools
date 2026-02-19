## 1. Directory Structure + Project Spec

- [x] 1.1 Create `benchmark/synthetic/` directory tree (changes/, tests/, claude-md/, scripts/, results/)
- [x] 1.2 Write `benchmark/synthetic/project-spec.md` — LogBook domain: events, categories, tags (entities, relationships, endpoints, stack: Express + better-sqlite3 + nanoid)
- [x] 1.3 Write `benchmark/synthetic/README.md` — quick-start (3-step flow: init → run → score)

## 2. Change Files

- [x] 2.1 Write `changes/01-event-crud.md` — SEED change: event/category CRUD, establish all 6 conventions explicitly (pagination format, error format, removedAt, fmtDate, ID prefixes, ok wrapper). ~30 lines agent input + ~20 lines evaluator notes
- [x] 2.2 Write `changes/02-tags-filtering.md` — GAP change: tag CRUD, event-tag many-to-many, filter by tag/category/date. No new conventions, just functional work to create context gap
- [x] 2.3 Write `changes/03-comments-activity.md` — PROBE change: comment CRUD on events, activity log. Probes T1 (pagination), T2 (errors), T5 (cmt_ IDs), T6 (ok wrapper). Evaluator notes document expected convention usage
- [x] 2.4 Write `changes/04-dashboard-export.md` — PROBE change: event stats dashboard, CSV export. Probes T1 (pagination), T2 (errors), T3 (removedAt), T4 (fmtDate), T6 (ok wrapper)
- [x] 2.5 Write `changes/05-bulk-operations.md` — PROBE change: bulk archive, bulk tag, purge old. Probes all 6 traps (T1-T6). Final probe, highest convention density

## 3. Test Scripts

- [x] 3.1 Write `tests/test-01.sh` — functional: CRUD works, categories work. Convention: verify all 6 conventions are established correctly in C01 output
- [x] 3.2 Write `tests/test-02.sh` — functional: tags work, filtering works. No convention probes (gap change)
- [x] 3.3 Write `tests/test-03.sh` — functional: comments work. Convention probes: T1, T2, T5, T6 on comment endpoints
- [x] 3.4 Write `tests/test-04.sh` — functional: dashboard works, export works. Convention probes: T1, T2, T3, T4, T6
- [x] 3.5 Write `tests/test-05.sh` — functional: bulk ops work. Convention probes: T1, T2, T3, T4, T5, T6

## 4. CLAUDE.md Variants

- [x] 4.1 Write `claude-md/baseline.md` — project setup, workflow (read change → implement → test → stop), directory structure. PORT=3000
- [x] 4.2 Write `claude-md/with-memory.md` — baseline + memory recall before implementing + save conventions + save learnings. PORT=3001

## 5. Scripts

- [x] 5.1 Write `scripts/init.sh` — bootstrap with `--mode a|b|c` flag. Installs deps, copies files, strips evaluator notes, deploys CLAUDE.md, sets up memory (mode b/c), initial commit
- [x] 5.2 Write `scripts/run.sh` — sequential session runner. Per change: invoke claude CLI, wait, commit, run test, record result. Supports --start/--end for partial runs
- [x] 5.3 Write `scripts/pre-seed.sh` — inject 6 convention memories for Mode C. Each memory is a complete, well-written Decision with tags
- [x] 5.4 Write `scripts/score.sh` — grep source files for convention compliance. Flexible file discovery (find, not hardcoded paths). Output human + JSON. Comparison mode when multiple results exist

## 6. Documentation

- [x] 6.1 Write `benchmark/synthetic/run-guide.md` — step-by-step execution protocol for all 3 modes. Prerequisites, timing estimates, troubleshooting
- [x] 6.2 Write `benchmark/synthetic/scoring-rubric.md` — trap definitions (abbreviated from spec), grep patterns, expected deltas

## 7. Validation

- [x] 7.1 Dry-run init.sh for all 3 modes — verify directory structure, file contents, no evaluator note leaks
- [ ] 7.2 Manual run of Mode A (C01 only) — verify the agent can implement C01 from the spec, tests pass
- [ ] 7.3 Review all grep patterns in score.sh against actual C01 output — verify they detect conventions correctly

## 8. Mode D (Rules Layer)

- [x] 8.1 Write `scripts/pre-rules.sh` — deploys `.claude/rules.yaml` with all 10 conventions (T1-T10) as keyword-matched rules
- [x] 8.2 Write `claude-md/with-rules.md` — CLAUDE.md variant for Mode D (port 4002, mandatory rules instruction)
- [x] 8.3 Extend `init.sh` with `--mode d` — runs pre-rules.sh, deploys hooks, uses with-rules.md, port 4002, starts C03 like Mode C
- [x] 8.4 Update `run-guide.md` — Mode D section with C vs D comparison protocol and hypotheses
- [x] 8.5 Update `docs/developer-memory.md` — add Benchmark section (MemoryProbe, modes A-D, quick run, scoring table)
