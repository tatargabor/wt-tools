# CraftBazaar — Multi-Vendor Artisan Marketplace

## Project Setup

- **Stack**: Next.js 14 (App Router) + Prisma + SQLite + TypeScript + Tailwind CSS
- **Dev server**: `PORT=3000 npm run dev`
- **Database**: SQLite (file-based, `prisma/dev.db`)
- **Migrations**: `npx prisma migrate dev`
- **Generate client**: `npx prisma generate` (required after schema changes)
- **Seed**: `npx prisma db seed`
- **Tests**: `npm test`

## Acceptance Testing

Each change has a corresponding test script in `tests/test-NN.sh`. After implementing a change:

1. Start the dev server if not running:
   ```bash
   PORT=3000 npm run dev &
   sleep 3
   ```

2. Run the test for the change you just implemented:
   ```bash
   bash tests/test-NN.sh 3000
   ```

3. If the test fails, fix the issues and re-run until all checks pass.

4. Do NOT commit until the test passes.

**Important**: These tests check API responses, schema structure, and page content. They are the acceptance criteria for each change. **Test scripts are read-only** — fix your code to match the tests, never modify the test files. Later tests include regression checks that verify earlier fixes survived.

## OpenSpec Workflow

This project uses OpenSpec for structured change management. Key commands:

- `openspec list --json` — See all changes and their status
- `/opsx:ff <change-name>` — Create all artifacts for a change
- `/opsx:apply <change-name>` — Implement a change's tasks
- `openspec status --change "<name>" --json` — Check change progress

When implementing a change:
1. Use `/opsx:ff` to create artifacts (proposal, specs, design, tasks)
2. Use `/opsx:apply` to implement the tasks
3. Run `bash tests/test-NN.sh 3000` and fix any failures
4. Commit all work when done

## Benchmark Task

You are autonomously building CraftBazaar through 12 sequential changes. Each session starts fresh (no conversation history from previous sessions).

**Project spec**: Read `docs/benchmark/project-spec.md` for the full domain description, tech stack, entities, and project structure. Read this before your first change.

**Changes are in three phases:**
- **01-06**: Build the core marketplace (products, cart, vendors, discounts, checkout, order workflow)
- **07-09**: Revision changes — stakeholder changed their mind on earlier decisions
- **10-11**: Feedback changes — design team corrections to UI/UX
- **12**: Sprint retro — fix 5 cross-cutting bugs

**Your workflow each session:**

1. Find the next incomplete change. There are exactly 12 changes (01 through 12):
   ```bash
   ls results/change-*.json 2>/dev/null   # which changes are done
   ls docs/benchmark/[0-9]*.md            # all 12 change definitions
   ```
   A change is done ONLY when its `results/change-NN.json` file exists.
   The `openspec list` "no-tasks" status means NOT STARTED — it still needs `/opsx:ff`.
   Read the next unfinished change definition file. If this is the first change, also read `docs/benchmark/project-spec.md`.

2. Implement the change:
   - Run `/opsx:ff <change-name>` to create artifacts
   - Run `/opsx:apply <change-name>` to implement tasks
   - Run `bash tests/test-NN.sh 3000` to verify
   - Fix any test failures and re-run until pass

3. After completing a change, write a status file:
   ```bash
   mkdir -p results
   cat > results/change-<NN>.json << 'RESULT'
   {
     "change": "<change-name>",
     "completed": true,
     "notes": "<brief summary of what was done and any issues encountered>"
   }
   RESULT
   ```

4. Commit all work:
   ```bash
   git add -A && git commit -m "<change-name>: <summary>"
   ```

5. Check if done: you are finished ONLY when `ls results/change-*.json | wc -l` returns 12. If fewer than 12, go back to step 1.

**Important:**
- Work on changes in order (01 → 02 → ... → 12)
- Each change builds on the previous — don't skip ahead
- Changes 07-09 REVISE earlier decisions — read them carefully
- Changes 10-11 CORRECT design issues — follow the specific corrections exactly
- Change 12 has 5 bugs to fix — find and fix all of them
- If you encounter an error, debug and fix it — don't ask for help
- If a previous change's code needs updating for the current change, update it
- Write the results JSON even if the change had issues — document what happened
- Run the acceptance test after each change — do NOT commit until it passes
