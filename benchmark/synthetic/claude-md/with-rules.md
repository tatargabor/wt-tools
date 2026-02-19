# LogBook API — Benchmark Agent Instructions

## Setup

```bash
# Install dependencies
npm install

# Start the server (keep running in background)
node src/server.js &

# Run tests for change N
bash tests/test-0N.sh 4002
```

- Dev server port: **4002**
- Database: `data/logbook.db` (SQLite, auto-created on first start)
- If server is already running, kill it first: `pkill -f "node src/server.js"`

## Project Spec

Read `docs/project-spec.md` for the full domain specification including entities, conventions, and project structure.

## Mandatory Rules

This project uses a `.claude/rules.yaml` file to enforce operational constraints. When you see a `=== MANDATORY RULES ===` section injected into your context, **you MUST follow those rules exactly** — they override project-spec.md and existing code patterns where there is a conflict.

The rules are automatically injected by the hook system when your prompt matches rule topics. You do not need to manually read rules.yaml.

## Workflow

For each change you are given:

1. **Read the change file** in `docs/changes/` — understand all requirements
2. **Read `docs/project-spec.md`** — understand domain context and conventions
3. **Check injected MANDATORY RULES** — if a `=== MANDATORY RULES ===` section appears in your context, apply those rules. They take precedence over project-spec.md and existing code.
4. **Implement** the requirements, following all mandatory rules
5. **Start/restart the server**: `pkill -f "node src/server.js" 2>/dev/null; sleep 1; PORT=4002 node src/server.js &`
6. **Run the test script**: `bash tests/test-0N.sh 4002`
7. **Fix any failures** and re-run until all tests pass
8. **Stop** — do NOT proceed to the next change

## Project Structure

```
src/
  server.js          # Express app + route mounting + listen
  routes/            # Route handlers (events.js, categories.js, ...)
  db/                # Database setup + query functions
  lib/               # Shared utilities (fmt.js, ids.js)
  middleware/        # Express middleware (errors.js)
data/
  logbook.db         # SQLite database (auto-created)
docs/
  project-spec.md    # Domain specification
  changes/           # Change definitions (one per change)
tests/
  test-NN.sh         # Acceptance tests (curl-based)
results/
  change-NN.json     # Auto-created by test scripts on pass
```

## Important

- Do NOT create `results/change-NN.json` manually — only test scripts create them on pass
- Do NOT proceed to the next change — implement only the one you were asked about
- Read existing code before implementing to understand patterns already in use
- MANDATORY RULES (injected via system context) override project-spec.md and existing code
