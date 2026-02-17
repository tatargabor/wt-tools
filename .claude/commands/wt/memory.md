Interact with the project's cognitive memory system (shodh-memory).

**Usage**: `/wt:memory [subcommand] [args]`

**Subcommands**:
- `status` — Show memory health, count, and storage path
- `recall <query>` — Search memories semantically
- `remember <content>` — Save a new memory
- `list` — List all memories for the current project
- `browse` (default) — Show summary of all memories grouped by type
- `audit [--threshold F] [--json]` — Report duplicate clusters and memory health
- `dedup [--threshold F] [--dry-run] [--interactive]` — Remove duplicate memories

**What to do**:

1. Parse `$ARGUMENTS` to determine the subcommand (first word). If no arguments or unrecognized subcommand, default to `browse`.

2. **Check health first**:
   ```bash
   wt-memory health
   ```
   If this fails (exit code non-zero), display:
   > "Memory system not available — shodh-memory is not running. Check with `wt-memory health`."
   Then STOP.

3. **Execute the subcommand**:

   **status**:
   ```bash
   wt-memory status
   ```
   Display the output directly.

   **recall** (rest of arguments is the query):
   ```bash
   wt-memory recall "<query>" --limit 5
   ```
   Parse the JSON output. For each memory, display:
   - Type and tags
   - Content (truncated to 200 chars if long)
   - Creation date
   If no results, say "No matching memories found."

   **remember** (rest of arguments is the content):
   - Use the **AskUserQuestion tool** to ask which memory type to use:
     - Options: `Decision`, `Learning`, `Observation`, `Event`
   - Optionally ask for comma-separated tags (or skip)
   - Then run:
     ```bash
     echo "<content>" | wt-memory remember --type <type> --tags <tags>
     ```
   - Confirm: "Memory saved."

   **list**:
   ```bash
   wt-memory list
   ```
   Parse JSON and display all memories in a readable table format.

   **browse** (default):
   ```bash
   wt-memory status
   wt-memory list
   ```
   Display status summary, then group memories by type (Decision, Learning, Observation, Event) and show counts + recent entries.

   **audit** (pass all remaining args through):
   ```bash
   wt-memory audit [--threshold F] [--json]
   ```
   Display the output directly. If `--json` is not present, the output is already human-readable.

   **dedup** (pass all remaining args through):
   ```bash
   wt-memory dedup [--threshold F] [--dry-run] [--interactive]
   ```
   Display the output directly. Warn the user if neither `--dry-run` nor `--interactive` is specified (destructive operation).

**Important**:
- All `wt-memory` commands auto-detect the project from git root
- If shodh-memory is not installed, all commands fail gracefully
- Memory types: Decision (architectural choices), Learning (patterns/gotchas), Observation (errors/issues), Event (milestones)

ARGUMENTS: $ARGUMENTS
