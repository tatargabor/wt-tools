# LogBook API — Benchmark Agent Instructions

## Setup

```bash
# Install dependencies
npm install

# Start the server (keep running in background)
node src/server.js &

# Run tests for change N
bash tests/test-0N.sh 4001
```

- Dev server port: **4001**
- Database: `data/logbook.db` (SQLite, auto-created on first start)
- If server is already running, kill it first: `pkill -f "node src/server.js"`

## Project Spec

Read `docs/project-spec.md` for the full domain specification including entities, conventions, and project structure.

## Workflow

For each change you are given:

1. **Recall relevant context** — before implementing, check what you know:
   ```bash
   wt-memory recall "LogBook project conventions" --limit 5 --mode hybrid
   wt-memory recall "implementation patterns errors" --limit 5 --mode semantic
   ```
   Use recalled information to guide your implementation.

2. **Read the change file** in `docs/changes/` — understand all requirements
3. **Read `docs/project-spec.md`** — understand domain context and conventions
4. **Implement** the requirements, applying recalled conventions
5. **Start/restart the server**: `pkill -f "node src/server.js" 2>/dev/null; sleep 1; PORT=4001 node src/server.js &`
6. **Run the test script**: `bash tests/test-0N.sh 4001`
7. **Fix any failures** and re-run until all tests pass
8. **Save what you learned** — after implementation, save important patterns:
   ```bash
   # Save project conventions you encountered
   echo "<convention description>" | wt-memory remember --type Decision --tags "convention,<topic>"

   # Save any gotchas or errors you hit
   echo "<error and fix>" | wt-memory remember --type Learning --tags "change:0N,<topic>"
   ```
9. **Stop** — do NOT proceed to the next change

## Memory Guidelines

**What to save** (would help a future agent in a fresh session):
- Project conventions (API format, error format, naming patterns, utility functions)
- Gotchas encountered (SQLite quirks, import issues, test expectations)
- Architecture decisions (where things live, how they connect)

**What NOT to save**:
- Obvious things (Express routing basics, SQL syntax)
- Session-specific details ("edited line 42")
- Duplicate information already saved

**Quality bar**: Would a future agent in a fresh session materially benefit from knowing this?

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
- Always recall memories BEFORE starting implementation
