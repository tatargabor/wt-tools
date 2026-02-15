---
name: "OPSX: Fast Forward"
description: Create a change and generate all artifacts needed for implementation in one go
category: Workflow
tags: [workflow, artifacts, experimental]
---

Fast-forward through artifact creation - generate everything needed to start implementation.

**Input**: The argument after `/opsx:ff` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

1. **If no input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   openspec new change "<name>"
   ```
   This creates a scaffolded change at `openspec/changes/<name>/`.

3. **Get the artifact build order**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies

3b. **Recall relevant past experience (automatic)**

   If `wt-memory health` succeeds:
   - Run: `wt-memory recall "<change-name> <description-from-user>" --limit 5 --mode hybrid --tags change:<change-name>`
   - Keep relevant memories (past decisions, patterns, errors) in mind during artifact creation

   If `wt-memory health` fails, skip silently.

3c. **Recognize knowledge mid-flow (ongoing)**

   **Agent discoveries**: When you discover something non-obvious during codebase research, save it BEFORE summarizing. Order: **Discover → Save → Tell**.

   **User-shared knowledge**: The user may also share corrections, constraints, or contextual knowledge. When you recognize such knowledge, save it immediately.

   **Recognize by intent** (works in any language):
   - User corrects your approach or shares a better alternative
   - User warns about a dependency, API behavior, or known issue
   - User shares a project constraint or preference

   **Do NOT save**: simple confirmations ("ok", "jó", "continue"), task-specific instructions, or questions.

   **When recognized**:
   1. Run `wt-memory health` — if it fails, skip silently
   2. Save: `echo "<insight>" | wt-memory remember --type <Decision|Learning|Context> --tags change:<change-name>,phase:ff,source:user,<topic>`
   3. Confirm: `[Memory saved: <Type> — <summary>]`
   4. Adjust the artifact being created if needed, then continue

4. **Create artifacts in sequence until apply-ready**

   Use the **TodoWrite tool** to track progress through the artifacts.

   Loop through artifacts in dependency order (artifacts with no pending dependencies first):

   a. **For each artifact that is `ready` (dependencies satisfied)**:
      - Get instructions:
        ```bash
        openspec instructions <artifact-id> --change "<name>" --json
        ```
      - The instructions JSON includes:
        - `context`: Project background (constraints for you - do NOT include in output)
        - `rules`: Artifact-specific rules (constraints for you - do NOT include in output)
        - `template`: The structure to use for your output file
        - `instruction`: Schema-specific guidance for this artifact type
        - `outputPath`: Where to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure
      - Apply `context` and `rules` as constraints - but do NOT copy them into the file
      - Show brief progress: "✓ Created <artifact-id>"

   b. **Continue until all `applyRequires` artifacts are complete**
      - After creating each artifact, re-run `openspec status --change "<name>" --json`
      - Check if every artifact ID in `applyRequires` has `status: "done"` in the artifacts array
      - Stop when all `applyRequires` artifacts are done

   c. **If an artifact requires user input** (unclear context):
      - Use **AskUserQuestion tool** to clarify
      - Then continue with creation

5. **Show final status**
   ```bash
   openspec status --change "<name>"
   ```

6. **Agent self-reflection (automatic, after all artifacts created)**

   Before showing the final output, review the entire session for your own insights — things you discovered while creating all artifacts that a future agent would benefit from knowing.

   **What to look for:**
   - Decision rationale (why you chose approach X over Y in design/specs)
   - Codebase patterns discovered during research (non-obvious architecture, conventions)
   - Surprises or gotchas found while exploring the code
   - Connections between this change and other parts of the system
   - Architectural insights that emerged from writing the full artifact set

   **What NOT to save:**
   - Routine observations ("the codebase uses TypeScript")
   - Things already saved by the mid-flow user-knowledge hook (step 3c)
   - Session-specific context (file paths read, commands run)

   If `wt-memory health` succeeds and you have insights worth saving:
   - Save each insight:
     ```bash
     echo "<insight description>" | wt-memory remember --type <Learning|Decision> --tags change:<change-name>,phase:ff,source:agent,<topic>
     ```
   - Confirm: `[Agent insights saved: N items]`

   If no insights worth saving: `[Agent insights saved: 0 items]`
   If health fails, skip silently.

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/opsx:apply` to start implementing."

**Artifact Creation Guidelines**

- Follow the `instruction` field from `openspec instructions` for each artifact type
- The schema defines what each artifact should contain - follow it
- Read dependency artifacts for context before creating new ones
- Use the `template` as a starting point, filling in based on context

**Guardrails**
- Create ALL artifacts needed for implementation (as defined by schema's `apply.requires`)
- Always read dependency artifacts before creating a new one
- If context is critically unclear, ask the user - but prefer making reasonable decisions to keep momentum
- If a change with that name already exists, ask if user wants to continue it or create a new one
- Verify each artifact file exists after writing before proceeding to next
