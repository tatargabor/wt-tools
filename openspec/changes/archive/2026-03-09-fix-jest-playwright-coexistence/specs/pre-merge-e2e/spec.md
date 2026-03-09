# Pre-Merge E2E Testing

## Overview

The orchestrator runs Playwright functional tests in the worktree before merge, giving each feature change its own E2E test validation with isolated port and database. This implements a "shift left" strategy aligned with ISTQB CT-TAS and the Testing Diamond model.

## Industry Research

### Testing Models

**Testing Pyramid (traditional):** Unit-heavy base (70%), integration middle (20%), E2E top (10%). Originated from Mike Cohn (2009). Optimizes for speed and isolation but under-tests runtime interactions critical in web apps.

**Testing Diamond (modern, preferred for web apps):** Integration-heavy middle (~50%), unit base (~40%), E2E top (~10%). Popularized by Guillermo Rauch's "Write tests. Not too many. Mostly integration." Endorsed by web.dev testing strategy guides. Rationale: web applications fail primarily at runtime boundaries (cookies, middleware, DB queries, redirects) — mocked unit tests miss these entirely.

**ISTQB CT-TAS v1.0 (2024) — Test Automation Strategy:** Defines four test levels mapped to CI/CD automation:

| ISTQB Level | Maps to | Automation |
|---|---|---|
| Component (unit) | Jest/Vitest | `test_command` pre-merge |
| Component Integration | API/DB tests with doubles | `test_command` pre-merge |
| Contract | Service contract validation | N/A (single-service projects) |
| UI (E2E) | Playwright against running app | `e2e_command` pre-merge |

The CTAL-TAE v2.0 syllabus extends this with test automation architecture patterns: keyword-driven, data-driven, and model-based. Our approach aligns with data-driven (env vars for port/DB) and keyword-driven (Playwright page object pattern).

### Pre-Merge E2E — "Shift Left" Consensus

Industry consensus: run E2E tests pre-merge in ephemeral environments, not post-merge on main.

- **Shipyard** ("E2E Testing Before Merge"): Ephemeral preview environments per PR. Each PR gets its own isolated runtime. Worktrees serve this role in our orchestrator — isolated filesystem, branch, and database per change.
- **Aviator** ("Pre and Post-Merge Tests Using a Merge Queue"): Two-step CI — fast tests (lint, unit) on every commit, thorough tests (E2E, integration) before merge. Maps directly to our Step 1 (test_command + build) / Step 2 (e2e_command) verify gate.
- **Conf42** talks on shift-left testing: Catching bugs earlier is cheaper. Post-merge E2E means broken code is already on main with no change attribution for the fix.

### Playwright Isolation Patterns

Playwright natively supports per-worker isolation via `workerIndex` for ports and databases (documented in Parallelism, WorkerInfo, and Fixtures docs). For our simpler case — one Playwright run per worktree — a `PW_PORT` environment variable suffices.

Key isolation mechanisms:
- **Port**: `PW_PORT` env var, random in 3100-3999, read by `playwright.config.ts`
- **Dev server**: `webServer` config auto-starts `pnpm dev --port $PW_PORT` per worktree
- **Collision detection**: `reuseExistingServer: false` fails fast if port is taken
- **Browser cache**: `~/.cache/ms-playwright/` is shared across worktrees (installed once via `npx playwright install chromium`)

### DB Isolation for Parallel E2E

Per Playwright GitHub issue #33699, database isolation is the hardest problem in parallel E2E testing. Three tiers:

1. **SQLite (zero config):** File-based, each worktree has its own `prisma/dev.db`. Schema divergence between worktrees (different changes adding different models) is naturally isolated.
2. **PostgreSQL/MySQL (future):** Per-worktree database names via `DATABASE_URL` override (e.g., `app_wt_cart_feature`). Requires `e2e_db_setup`/`e2e_db_teardown` orchestrator hooks.
3. **Clean state via globalSetup:** `prisma generate` (regenerate client for new models) → `prisma db push --force-reset` (fresh schema) → `prisma db seed` (test data). The `generate` step is critical — without it, the Prisma client doesn't know about models added by the current change.

### Empirical Finding — MiniShop E2E Run #2

Root cause of `playwright-e2e` change failure: Jest picks up Playwright `.spec.ts` files by default and crashes on Playwright imports in jsdom (`TypeError: Class extends value undefined`). The fix: `testPathIgnorePatterns: ["/node_modules/", "/tests/e2e/"]` in `jest.config`. Additionally, the planner deferred all E2E tests to a single consolidation change — an anti-pattern that overloads one agent. Each feature change must own its own `.spec.ts` file.

### References

- ISTQB CT-TAS v1.0 Syllabus (2024) — test automation strategy, CI/CD integration
- ISTQB CTAL-TAE v2.0 — test automation architecture, test levels mapping
- Testing Diamond model — web.dev/articles/ta-strategies, code4it.dev
- Guillermo Rauch — "Write tests. Not too many. Mostly integration."
- Playwright docs: Parallelism, WorkerInfo, Fixtures (per-worker isolation)
- Playwright GitHub #33699 — DB isolation patterns for parallel E2E
- Shipyard: "E2E Testing Before Merge" — ephemeral environments per PR
- Aviator: "Pre and Post-Merge Tests Using a Merge Queue" — two-step CI
- Conf42: Shift-left testing talks
- Microsoft Engineering Playbook: Smoke Testing — post-deploy verification

## Requirements

### E2E Command Directive

1. The orchestration config SHALL support an `e2e_command` directive (string, optional)
2. When `e2e_command` is set, the verify gate SHALL run it in the worktree after build passes and before scope check
3. The `e2e_command` SHALL run with a `PW_PORT` environment variable set to a random port in the range 3100-3999
4. If `e2e_command` fails, the verify gate SHALL follow the same retry logic as `test_command`: resume the agent with error context, retry up to `max_verify_retries` times
5. The `e2e_command` timeout SHALL default to 120 seconds, configurable via `e2e_timeout` directive
6. The `e2e_command` SHALL run in the worktree directory (same as `test_command`), not on main

### Two-Step Verify Gate Flow

The verify gate SHALL execute steps in this order:

**Step 1 — Fast feedback:**
1. `test_command` (unit tests — Jest/Vitest)
2. Build check (`pnpm build`)

**Step 2 — Thorough validation:**
3. `e2e_command` (functional tests — Playwright) — NEW
4. Scope check
5. Test file check

If any step fails and retries are exhausted, the change is marked failed. Steps 1-3 each trigger agent resume on failure.

### Port Isolation

1. Each `e2e_command` invocation SHALL set `PW_PORT` to `3100 + (RANDOM % 900)`
2. The Playwright config template SHALL read `PW_PORT` from environment and use it for both `baseURL` and `webServer.command`
3. `webServer.reuseExistingServer` SHALL be set to `false` to fail fast on port collision
4. The port range 3100-3999 SHALL be reserved for E2E tests, avoiding the default dev server port (3000)

### DB Isolation

1. For file-based databases (SQLite): no action needed — worktree-local DB files are naturally isolated
2. For server-based databases (PostgreSQL, MySQL): future capability — the orchestrator MAY support `e2e_db_setup` and `e2e_db_teardown` hooks to create/drop per-worktree databases
3. The Playwright `globalSetup` SHALL run `prisma generate` THEN `prisma db push --force-reset` THEN `prisma db seed` to ensure the Prisma client matches the current schema and DB state is clean
4. Schema divergence between worktrees (different changes adding different models) SHALL be handled naturally by per-worktree `prisma db push`

### Playwright Infrastructure Bootstrap

1. The planner SHALL assign Playwright infrastructure setup to the infrastructure/foundation change (first in dependency order), NOT to individual feature changes
2. The infrastructure change SHALL create: `playwright.config.ts`, `tests/e2e/global-setup.ts`, jest config exclusion, install `@playwright/test` + run `npx playwright install chromium`
3. If `e2e_command` is configured but `playwright.config.ts` does not exist in the worktree, the verify gate SHALL skip the e2e step gracefully (log warning, not fail)
4. Feature changes SHALL only create their own `tests/e2e/<feature>.spec.ts` files, not Playwright infrastructure

### E2E Failure Diagnostics

1. The verify gate SHALL use a 4000-char output truncation for `e2e_command` failures (Playwright output is more verbose than Jest)
2. On `e2e_command` failure or timeout, the verifier SHALL kill orphaned dev server processes on the assigned `PW_PORT`
3. The retry context SHALL include the e2e output, original scope, and memory context

### Planner — Per-Change E2E Ownership

1. The planner prompt SHALL instruct that each feature change creating a user-facing route MUST include a `tests/e2e/<feature>.spec.ts` file
2. The scope SHALL reference the `.spec.ts` file as an explicit deliverable (e.g., "Create tests/e2e/cart.spec.ts"), not as scenario descriptions
3. The planner SHALL NOT generate a consolidation "e2e" change that writes all Playwright tests at once — this is an anti-pattern that overloads a single agent

### Jest/Playwright Coexistence

1. The testing-conventions rule SHALL document that Jest picks up `.spec.ts` files by default and crashes on Playwright imports in jsdom
2. The rule SHALL require `testPathIgnorePatterns: ["/node_modules/", "/tests/e2e/"]` in `jest.config` when Playwright tests exist
3. The planner prompt SHALL include this requirement in the first change that creates E2E tests
4. The template SHOULD provide a reference `playwright.config.ts` with `PW_PORT` support and `webServer` auto-start

### Smoke Command Relationship

1. `smoke_command` SHALL remain as an optional post-merge directive for cross-feature integration tests
2. `e2e_command` and `smoke_command` are independent — projects MAY use either, both, or neither
3. When `e2e_command` covers per-change E2E, `smoke_command` is typically not needed unless cross-feature integration testing is desired
4. The testing-conventions rule SHALL document this relationship and when to use each
