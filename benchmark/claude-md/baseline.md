# CraftBazaar — Multi-Vendor Artisan Marketplace

## Project Setup

- **Stack**: Next.js 14 (App Router) + Prisma + SQLite + TypeScript + Tailwind CSS
- **Dev server**: `PORT=3000 npm run dev`
- **Database**: SQLite (file-based, `prisma/dev.db`)
- **Migrations**: `npx prisma migrate dev`
- **Generate client**: `npx prisma generate` (required after schema changes)
- **Seed**: `npx prisma db seed`
- **Tests**: `npm test`

## Testing

Run tests after implementing each change:
```bash
npm test
```

If tests don't exist yet, verify manually:
- Check API routes with curl or fetch
- Verify pages render at the expected URLs
- Check database state with `npx prisma studio`

## OpenSpec Workflow

This project uses OpenSpec for structured change management. Key commands:

- `openspec list --json` — See all changes and their status
- `/opsx:ff <change-name>` — Create all artifacts for a change
- `/opsx:apply <change-name>` — Implement a change's tasks
- `openspec status --change "<name>" --json` — Check change progress

When implementing a change:
1. Use `/opsx:ff` to create artifacts (proposal, specs, design, tasks)
2. Use `/opsx:apply` to implement the tasks
3. Commit all work when done

## Benchmark Task

You are autonomously building CraftBazaar through 6 sequential changes. Each session starts fresh (no conversation history from previous sessions).

**Project spec**: Read `docs/benchmark/project-spec.md` for the full domain description, tech stack, entities, and project structure. Read this before your first change.

**Your workflow each session:**

1. Check what's already done:
   ```bash
   openspec list --json
   ```

2. Find the next incomplete change. Changes are numbered 01-06 in `docs/benchmark/`:
   ```bash
   ls docs/benchmark/
   ```
   Read the next unfinished change definition file. If this is the first change, also read `docs/benchmark/project-spec.md`.

3. Implement the change:
   - Run `/opsx:ff <change-name>` to create artifacts
   - Run `/opsx:apply <change-name>` to implement tasks
   - Make sure all acceptance criteria pass

4. After completing a change, write a status file:
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

5. Commit all work:
   ```bash
   git add -A && git commit -m "<change-name>: <summary>"
   ```

6. If all 6 changes are complete, report: "All CraftBazaar changes complete."

**Important:**
- Work on changes in order (01 → 02 → 03 → 04 → 05 → 06)
- Each change builds on the previous — don't skip ahead
- If you encounter an error, debug and fix it — don't ask for help
- If a previous change's code needs updating for the current change, update it
- Write the results JSON even if the change had issues — document what happened
