---
name: openspec-apply-change
description: Implement tasks from an OpenSpec change. Use when the user wants to start implementing, continue implementation, or work through tasks.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.1.1"
---

Implement tasks from an OpenSpec change.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/opsx:apply <other>`).

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - Which artifact contains the tasks (typically "tasks" for spec-driven, check status for others)

3. **Get apply instructions**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   This returns:
   - Context file paths (varies by schema - could be proposal/specs/design/tasks or spec/tests/implementation/docs)
   - Progress (total, complete, remaining)
   - Task list with status
   - Dynamic instruction based on current state

   **Handle states:**
   - If `state: "blocked"` (missing artifacts): show message, suggest using openspec-continue-change
   - If `state: "all_done"`: congratulate, suggest archive
   - Otherwise: proceed to implementation

4. **Read context files**

   Read the files listed in `contextFiles` from the apply instructions output.
   The files depend on the schema being used:
   - **spec-driven**: proposal, specs, design, tasks
   - Other schemas: follow the contextFiles from CLI output

4b. **Use injected memories**

   The memory recall hook automatically injects relevant past experience into the prompt on change boundaries. If you see a `=== PROJECT MEMORY ===` block above, use those memories to inform implementation (avoid past errors, reuse working patterns).

4c. **Recognize knowledge mid-flow (ongoing)**

   **Agent discoveries**: When you discover something non-obvious during implementation (unexpected errors, environment quirks, workarounds), save it BEFORE continuing. Order: **Discover → Save → Tell**. Don't defer to step 7.

   **User-shared knowledge**: The user may also share corrections, warnings, or contextual knowledge between tasks. When you recognize such knowledge, save it immediately — don't wait for step 7.

   **Recognize by intent** (works in any language):
   - User corrects your approach or shares a better alternative
   - User warns about a dependency, API behavior, or known issue
   - User shares a project constraint or preference

   **Do NOT save**: simple confirmations ("ok", "jó", "continue"), task-specific instructions ("edit that line"), or questions.

   **When recognized**:
   1. Run `wt-memory health` — if it fails, skip silently
   2. Save: `echo "<insight>" | wt-memory remember --type <Decision|Learning> --tags change:<change-name>,phase:apply,source:user,<topic>`
   3. Confirm: `[Memory saved: <Type> — <summary>]`
   4. Adjust implementation if needed, then continue

   Step 7's remember block handles implementation-level learnings (errors, patterns). This mid-flow save covers user-provided knowledge.

5. **Show current progress**

   Display:
   - Schema being used
   - Progress: "N/M tasks complete"
   - Remaining tasks overview
   - Dynamic instruction from CLI

6. **Implement tasks (loop until done or blocked)**

   For each pending task:
   - Show which task is being worked on
   - Make the code changes required
   - Keep changes minimal and focused
   - Mark task complete in the tasks file: `- [ ]` → `- [x]`
   - Continue to next task

   **Pause if:**
   - Task is unclear → ask for clarification
   - Implementation reveals a design issue → suggest updating artifacts
   - Error or blocker encountered → report and wait for guidance
   - User interrupts

7. **On completion or pause, show status**

   Display:
   - Tasks completed this session
   - Overall progress: "N/M tasks complete"
   - If all done: suggest archive
   - If paused: explain why and wait for guidance

   After showing status, if `wt-memory health` succeeds:
   - If errors were encountered during this session, save each:
     ```bash
     echo "<error description and workaround/fix>" | wt-memory remember --type Learning --tags change:<change-name>,phase:apply,source:agent,error
     ```
   - If useful patterns were discovered, save each:
     ```bash
     echo "<pattern description>" | wt-memory remember --type Learning --tags change:<change-name>,phase:apply,source:agent,pattern
     ```
   - If all tasks are complete, save a completion event:
     ```bash
     echo "<change-name>: implementation complete — <brief summary>" | wt-memory remember --type Context --tags change:<change-name>,phase:apply,source:agent,implementation
     ```
   If health fails, skip silently.

**Output During Implementation**

```
## Implementing: <change-name> (schema: <schema-name>)

Working on task 3/7: <task description>
[...implementation happening...]
✓ Task complete

Working on task 4/7: <task description>
[...implementation happening...]
✓ Task complete
```

**Output On Completion**

```
## Implementation Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete! Ready to archive this change.
```

**Output On Pause (Issue Encountered)**

```
## Implementation Paused

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting (from the apply instructions output)
- If task is ambiguous, pause and ask before implementing
- If implementation reveals issues, pause and suggest artifact updates
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements - don't guess
- Use contextFiles from CLI output, don't assume specific file names

**Fluid Workflow Integration**

This skill supports the "actions on a change" model:

- **Can be invoked anytime**: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
- **Allows artifact updates**: If implementation reveals design issues, suggest updating artifacts - not phase-locked, work fluidly
