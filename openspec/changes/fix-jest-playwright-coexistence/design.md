## Context

The orchestrator has a two-level testing architecture: `test_command` (Jest unit tests, pre-merge in worktree) and `smoke_command` (Playwright E2E, post-merge on main). This causes three problems: (1) Jest crashes when it encounters Playwright `.spec.ts` files in jsdom, (2) E2E failures post-merge mean broken code is already on main with no change attribution, (3) the planner defers all Playwright tests to a single consolidation change that's too complex for one agent.

### Industry Context

The ISTQB CT-TAS v1.0 (2024) and CTAL-TAE v2.0 syllabi define four test levels mapped to automation: unit (component), component integration, contract, and UI (E2E). The modern "Testing Diamond" model — endorsed by web.dev and popularized by Guillermo Rauch's "mostly integration" — shifts focus from unit-heavy pyramids to integration-heavy strategies. This fits web applications where runtime interactions (cookies, middleware, DB queries) are the primary failure mode.

Industry consensus on pre-merge E2E: Shipyard, Aviator, and Conf42 talks advocate "shift left" — running E2E in ephemeral environments per PR/branch before merge. Worktrees are our ephemeral environments.

Playwright natively supports per-worker isolation via `workerIndex` for ports and databases. For our simpler case (one Playwright run per worktree), a `PW_PORT` env var suffices.

## Goals / Non-Goals

**Goals:**
- Each feature change owns and runs its own Playwright E2E tests pre-merge in its worktree
- Jest and Playwright coexist without interference (testPathIgnorePatterns)
- Port and DB isolation between parallel worktrees running E2E tests
- Planner generates per-change E2E test files as explicit deliverables, not scenario descriptions
- Document the testing strategy with industry references (ISTQB, Testing Diamond)

**Non-Goals:**
- PostgreSQL/MySQL per-worktree DB isolation (future — document pattern only)
- Removing `smoke_command` (stays as optional post-merge cross-feature integration)
- Changing the Playwright test runner or framework
- Playwright sharding across machines (single-machine orchestration for now)

## Decisions

### 1. Two-Step Verify Gate (aligned with merge queue best practices)

The Aviator merge queue pattern recommends two-step CI: fast tests on every commit, thorough tests before merge. Our verify gate implements this:

```
Step 1 — Fast feedback (~30s):        Step 2 — Thorough validation (~2min):
┌─────────────────────────┐            ┌─────────────────────────────┐
│ test_command (Jest)     │            │ e2e_command (Playwright)    │
│ build (pnpm build)     │            │  ├─ auto-start dev server   │
│                         │            │  ├─ per-worktree DB         │
│ → catches type errors,  │            │  ├─ isolated port           │
│   import errors, logic  │            │  └─ real runtime validation │
└─────────────────────────┘            └─────────────────────────────┘
```

Add `e2e_command` as a new orchestration directive that runs in the worktree, pre-merge, after build passes. Playwright's `webServer` config auto-starts a dev server per worktree.

### 2. Port isolation via `PW_PORT` environment variable

The orchestrator assigns a unique port per worktree:

```bash
# In verifier.sh, before running e2e_command
local e2e_port=$((3100 + (RANDOM % 900)))
PW_PORT=$e2e_port run_tests_in_worktree "$wt_path" "$e2e_command" "$e2e_timeout"
```

The Playwright config template reads `PW_PORT`:

```typescript
const PORT = process.env.PW_PORT ? parseInt(process.env.PW_PORT) : 3100;
export default defineConfig({
  use: { baseURL: `http://localhost:${PORT}` },
  webServer: {
    command: `pnpm dev --port ${PORT}`,
    url: `http://localhost:${PORT}`,
    reuseExistingServer: false,  // fail fast on port collision
  },
});
```

Rationale: Random port in 3100-3999 range avoids collision with dev servers (3000) and other worktrees. Playwright's native `workerIndex` supports the same pattern but we don't need it — one Playwright run per worktree is simpler.

### 3. DB isolation strategy

Per the Playwright GitHub issue #33699, DB isolation is the hardest problem in parallel E2E. Three tiers:

**SQLite (zero config — covers most orchestrated projects):**
Each worktree has its own `prisma/dev.db` file. `prisma db push` + `prisma db seed` operates on the local file. No shared state, no conflicts. Schema divergence between worktrees (e.g., cart-feature adds CartItem, admin-auth adds User) is naturally isolated — each worktree's `prisma db push` creates tables matching its own schema.

**PostgreSQL/MySQL (future — document pattern now):**
Per-worktree database names via `DATABASE_URL` override:
```
cart-feature  → DATABASE_URL=postgres://.../ app_wt_cart_feature
admin-auth    → DATABASE_URL=postgres://.../ app_wt_admin_auth
```
Implementation: `e2e_db_setup`/`e2e_db_teardown` hooks in orchestrator. Deferred.

**Playwright globalSetup for clean state:**
```typescript
// tests/e2e/global-setup.ts
async function globalSetup() {
  execSync('npx prisma generate', { stdio: 'inherit' });          // regenerate client for new models
  execSync('npx prisma db push --force-reset', { stdio: 'inherit' }); // fresh schema
  execSync('npx prisma db seed', { stdio: 'inherit' });           // seed test data
}
```

Note: `prisma generate` is critical — without it, the Prisma client doesn't know about models added by the current change, causing seed/test failures.

### 4. Playwright infrastructure bootstrap

**Problem:** In parallel execution, there's no "first change" — multiple changes start simultaneously. No single change can be guaranteed to create `playwright.config.ts` before others need it.

**Solution:** The `test-infrastructure` change (always first in dependency order) sets up Playwright infrastructure alongside Jest:
- Create `playwright.config.ts` with `PW_PORT` support
- Add `@playwright/test` to devDependencies
- Add `testPathIgnorePatterns: ["/tests/e2e/"]` to `jest.config`
- Run `npx playwright install chromium` (browser cache is global, shared by all worktrees)
- Create `tests/e2e/global-setup.ts` with prisma generate + push + seed

The planner must assign Playwright setup to the infrastructure/foundation change, NOT to the first feature change. Feature changes then only create their own `.spec.ts` files.

**Fallback:** If `e2e_command` is configured but `playwright.config.ts` doesn't exist in the worktree, the verifier should **skip gracefully** (log warning) rather than crash. This handles the edge case where a change started before infrastructure was merged.

### 5. Planner changes — per-change E2E ownership (Testing Diamond)

Following the Testing Diamond model, integration/E2E tests provide more business value than unit tests for web apps. The planner's "Functional test planning" section is rewritten to enforce per-change E2E ownership:

- Each feature change adding a user-facing route MUST create `tests/e2e/<feature>.spec.ts`
- Scope must say `Create tests/e2e/<feature>.spec.ts` (explicit file task), not just list scenarios
- The infrastructure/foundation change MUST set up Playwright config, browser install, and jest exclusion
- NO consolidation E2E change — this is an anti-pattern (one agent can't write all E2E tests)

### 6. Jest/Playwright coexistence in testing-conventions.md

Jest default `testRegex` matches `.spec.ts` → crashes on Playwright imports in jsdom (`TypeError: Class extends value undefined`). The fix is one line:

```typescript
// jest.config.ts
testPathIgnorePatterns: ["/node_modules/", "/tests/e2e/"],
```

This must be set up in the first change that introduces Playwright tests.

### 7. E2E failure diagnostics for agent retry

The agent needs enough context to fix E2E failures. Playwright output is verbose — a 2000-char truncation (current `test_command` limit) may only show the summary without actual errors.

**Improvements for `e2e_command` retry context:**

- Increase output truncation to 4000 chars for e2e failures (Playwright is more verbose than Jest)
- Configure Playwright reporter to output concise errors: `reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]]`
- On e2e failure, also read dev server stderr if available (Playwright's `webServer` can redirect to a log file)
- Include the specific test file that failed + the assertion error (parse from Playwright output)

**Process cleanup after timeout:** When `run_tests_in_worktree` times out, the `pnpm dev` child process may survive as a zombie on the assigned port. Add `pkill -f "pnpm dev.*--port $PW_PORT"` cleanup after e2e failure/timeout.

### 8. Smoke command relationship (post-merge = optional cross-feature gate)

```
LEVEL              WHEN           WHAT                    GATE
─────              ────           ────                    ────
test_command       pre-merge      Jest unit tests         blocking
build              pre-merge      TypeScript/Next build   blocking
e2e_command        pre-merge      Playwright per-change   blocking (NEW)
smoke_command      post-merge     cross-feature integ.    optional
```

`smoke_command` remains for projects needing cross-feature integration tests post-merge. But for most web projects, `e2e_command` provides sufficient coverage pre-merge.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| E2E tests slow verify gate (30-120s extra) | Catches real bugs pre-merge vs. wasting tokens on post-merge fix attempts. Industry consensus: "shift left" is worth the cost. |
| Port collision between parallel worktrees | Random port range (900 ports), ~0.1% collision probability per pair. Playwright errors clearly if port taken. |
| Playwright browser not installed | `npx playwright install chromium` in first change. Browser cache at `~/.cache/ms-playwright/` shared across worktrees. |
| PostgreSQL projects can't use pre-merge E2E yet | Document pattern, implement hooks later. Most orchestrated projects use SQLite. |
| Agent ignores E2E scope | Fixed: scope says "Create file X" not "Functional test scenarios:". Verify gate enforces test file exists. |
| Dev server startup flaky in worktree | Playwright `webServer.timeout: 120_000` + health check built into Playwright. |

## References

- ISTQB CT-TAS v1.0 Syllabus (2024) — test automation strategy, CI/CD integration
- ISTQB CTAL-TAE v2.0 — test automation architecture, test levels mapping
- Testing Diamond model — "mostly integration" for web apps
- Playwright docs: Parallelism, WorkerInfo, Fixtures (per-worker isolation)
- Playwright GitHub #33699 — DB isolation patterns for parallel E2E
- Shipyard: "E2E Testing Before Merge" — ephemeral environments per PR
- Aviator: "Pre and Post-Merge Tests Using a Merge Queue" — two-step CI
- Microsoft Engineering Playbook: Smoke Testing — post-deploy verification
