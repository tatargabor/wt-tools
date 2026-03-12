#!/usr/bin/env bash
# wt-loop prompt building: detect next change action, build Claude prompts
# Dependencies: lib/loop/state.sh and lib/loop/tasks.sh must be sourced first

# Detect the next OpenSpec change action needed.
# Args: $1=wt_path, $2=target_change (optional — if set, only inspect that change)
# Returns: "ff:<change-name>" or "apply:<change-name>" or "done" or "none"
detect_next_change_action() {
    local wt_path="$1"
    local target_change="${2:-}"

    # If a specific change is targeted, only inspect that one
    if [[ -n "$target_change" ]]; then
        local change_dir="$wt_path/openspec/changes/$target_change"
        local tasks_file="$change_dir/tasks.md"

        if [[ ! -d "$change_dir" ]]; then
            # Check if change was archived (moved to archive/ with date prefix)
            local archived
            archived=$(find "$wt_path/openspec/changes/archive" -maxdepth 1 -type d -name "*-$target_change" 2>/dev/null | head -1)
            if [[ -n "$archived" ]]; then
                echo "done"
            else
                echo "none"
            fi
            return
        fi

        # Does tasks.md exist? (ff done)
        if [[ ! -f "$tasks_file" ]]; then
            echo "ff:$target_change"
            return
        fi

        # Are all tasks checked? (apply done)
        local unchecked
        unchecked=$(grep -cE '^\s*-\s*\[\s*\]' "$tasks_file" 2>/dev/null || true)
        unchecked=${unchecked//[^0-9]/}
        unchecked=${unchecked:-0}
        if [[ "$unchecked" -gt 0 ]]; then
            echo "apply:$target_change"
            return
        fi

        echo "done"
        return
    fi

    # No target change — scan all changes (used by check_done for solo loops
    # and benchmark mode with numbered files)
    local change_order=()
    if ls "$wt_path"/docs/benchmark/[0-9]*.md &>/dev/null; then
        # Derive from numbered benchmark files: 01-product-catalog.md → product-catalog
        for f in "$wt_path"/docs/benchmark/[0-9]*.md; do
            local name
            name=$(basename "$f" .md | sed 's/^[0-9]*-//')
            change_order+=("$name")
        done
    elif [[ -d "$wt_path/openspec/changes" ]]; then
        # Fallback: alphabetical order
        for d in "$wt_path"/openspec/changes/*/; do
            [[ -d "$d" ]] || continue
            local name
            name=$(basename "$d")
            [[ "$name" == "archive" ]] && continue
            change_order+=("$name")
        done
    fi

    if [[ ${#change_order[@]} -eq 0 ]]; then
        echo "none"
        return
    fi

    local change_idx=0
    for change in "${change_order[@]}"; do
        change_idx=$((change_idx + 1))
        local change_dir="$wt_path/openspec/changes/$change"
        local tasks_file="$change_dir/tasks.md"

        # Check 0: Does results file exist? (change fully done — test passed)
        local nn
        nn=$(printf "%02d" "$change_idx")
        if [[ -f "$wt_path/results/change-${nn}.json" ]]; then
            continue  # Skip — this change is verified complete
        fi

        # Check 0.5: Does the change directory exist? (may be archived)
        if [[ ! -d "$change_dir" ]]; then
            # Check if archived
            if [[ -d "$wt_path/openspec/changes/archive/$change" ]]; then
                continue  # Archived — skip
            fi
            echo "ff:$change"
            return
        fi

        # Check 1: Does tasks.md exist? (ff done)
        if [[ ! -f "$tasks_file" ]]; then
            echo "ff:$change"
            return
        fi

        # Check 2: Are all tasks checked? (apply done)
        local unchecked
        unchecked=$(grep -cE '^\s*-\s*\[\s*\]' "$tasks_file" 2>/dev/null || true)
        unchecked=${unchecked//[^0-9]/}  # Strip non-digit chars
        unchecked=${unchecked:-0}
        if [[ "$unchecked" -gt 0 ]]; then
            echo "apply:$change"
            return
        fi
    done

    echo "done"
}

# Build parallel subagent prompt for apply phase
# Args: $1=change_name, $2=wt_path, $3=parallel_workers
build_parallel_apply_prompt() {
    local change_name="$1"
    local wt_path="$2"
    local parallel_workers="${3:-2}"

    local change_dir="$wt_path/openspec/changes/$change_name"
    local tasks_file="$change_dir/tasks.md"

    # Collect spec file paths for worker context
    local spec_files=""
    if [[ -d "$change_dir/specs" ]]; then
        spec_files=$(find "$change_dir/specs" -name "spec.md" -type f 2>/dev/null | sort | tr '\n' ' ')
    fi
    # Fall back to main specs if no change-level specs
    if [[ -z "$spec_files" ]] && [[ -d "$wt_path/openspec/specs" ]]; then
        spec_files=$(find "$wt_path/openspec/specs" -name "spec.md" -type f 2>/dev/null | sort | head -10 | tr '\n' ' ')
    fi

    cat <<PARALLEL_EOF
# YOUR TASK (MANDATORY — do this and ONLY this)
Implement the '$change_name' change using PARALLEL subagents.

## Step 1: Read context
- Read CLAUDE.md for project workflow
- Read the tasks file: $tasks_file
- Count the unchecked tasks (lines matching \`- [ ]\`)

## Step 2: Partition tasks into $parallel_workers groups
Split the unchecked tasks into $parallel_workers contiguous groups.
For example, if there are 9 tasks and $parallel_workers workers:
  Worker 1: tasks 1-3, Worker 2: tasks 4-6, Worker 3: tasks 7-9
If fewer tasks than workers, spawn only as many agents as tasks.

## Step 3: Spawn parallel worker agents
Use the Agent tool to spawn $parallel_workers agents IN A SINGLE RESPONSE (parallel).
Each worker agent receives:
- Its assigned task lines (exact checkbox text from tasks.md)
- The spec files to reference: $spec_files
- Instruction: "Read CLAUDE.md first. Implement ONLY the assigned tasks below. Mark each task as done in tasks.md (change \`- [ ]\` to \`- [x]\`). Commit your changes. Do NOT modify files outside your task scope."
- Set mode to "bypassPermissions" for each agent

## Step 4: Review
After ALL worker agents complete, spawn ONE more Agent with:
- subagent_type: "code-reviewer"
- Prompt: "Review the implementation of change '$change_name'. Read the spec files ($spec_files) and compare against git diff HEAD~$parallel_workers. Report any gaps: requirements that were not implemented or deviate from the spec. List each gap as: [Requirement name] — [what is missing]."

## Step 5: Fix and commit
If the reviewer found gaps, fix them directly. Then make a final commit.

## Important
- Do NOT use /opsx:apply — implement tasks directly via parallel agents
- Do NOT work on any other changes. Focus ONLY on '$change_name'
- ALL workers must commit their changes before you proceed to review
PARALLEL_EOF
}

# Build the prompt for Claude
build_prompt() {
    local task="$1"
    local iteration="$2"
    local max_iter="$3"
    local wt_path="$4"
    local done_criteria="$5"
    local target_change="${6:-}"

    local prev_commits=""
    local state_file
    state_file=$(get_loop_state_file "$wt_path")

    if [[ -f "$state_file" ]]; then
        prev_commits=$(jq -r '[.iterations[].commits[]?] | join(", ")' "$state_file" 2>/dev/null || echo "")
    fi

    local prev_text=""
    if [[ -n "$prev_commits" ]]; then
        prev_text="Previous iterations made commits: $prev_commits"
    else
        prev_text="This is the first iteration."
    fi

    # Detect OpenSpec project and determine specific action
    local change_action=""
    local specific_task=""
    local openspec_instructions=""

    if [[ -d "$wt_path/openspec" ]] && [[ "$done_criteria" == "openspec" ]] && [[ -n "$target_change" ]]; then
        # Scoped detection: only inspect the assigned change
        change_action=$(detect_next_change_action "$wt_path" "$target_change")

        case "$change_action" in
            ff:*)
                local change_name="${change_action#ff:}"
                specific_task="Create artifacts for the '$change_name' change"
                openspec_instructions="
# YOUR TASK (MANDATORY — do this and ONLY this)
Run: /opsx:ff $change_name
This will create design.md, specs, and tasks.md for the '$change_name' change.
Do NOT implement any code. Do NOT work on any other changes.
After /opsx:ff completes, commit the artifacts and stop.
"
                ;;
            apply:*)
                local change_name="${change_action#apply:}"
                specific_task="Implement the '$change_name' change"

                # Check if parallel mode is enabled
                local exec_mode
                exec_mode=$(jq -r '.execution_mode // "single"' "$state_file" 2>/dev/null)
                if [[ "$exec_mode" == "parallel" ]]; then
                    local p_workers
                    p_workers=$(jq -r '.parallel_workers // 2' "$state_file" 2>/dev/null)
                    openspec_instructions="
$(build_parallel_apply_prompt "$change_name" "$wt_path" "$p_workers")
"
                else
                    openspec_instructions="
# YOUR TASK (MANDATORY — do this and ONLY this)
Run: /opsx:apply $change_name
This will implement the tasks defined in tasks.md for the '$change_name' change.
Do NOT work on any other changes. Focus ONLY on '$change_name'.
After implementation, commit your changes and stop.
"
                fi
                ;;
            done)
                specific_task="All changes are complete"
                openspec_instructions="
# ALL CHANGES COMPLETE
All OpenSpec changes have been implemented. There is nothing left to do.
Do NOT write any files. Do NOT create any commits. Simply stop.
"
                ;;
            *)
                # No OpenSpec or no changes detected — use generic task
                specific_task="$task"
                ;;
        esac
    fi

    # Use specific task if detected, otherwise fall back to generic task
    local effective_task="${specific_task:-$task}"

    # Skip reflection when all changes are done — it creates dirty files
    # that prevent stall detection from firing as a safety net
    local reflection_section=""
    if [[ "$change_action" != "done" ]]; then
        reflection_section="
# Reflection (MANDATORY — last step before finishing)
Before you stop, write .claude/reflection.md with 3-5 bullet points:
- Errors you encountered and how you fixed them
- Non-obvious things you learned about this codebase
- Workarounds or gotchas the next iteration should know about
If nothing notable happened, write \"No notable issues.\" to the file."
    fi

    # Detect manual tasks and add instruction to skip them
    local manual_task_instruction=""
    local manual_count
    manual_count=$(count_manual_tasks "$wt_path")
    if [[ "$manual_count" -gt 0 ]]; then
        manual_task_instruction="
# Manual Tasks
Tasks marked with [?] in tasks.md require human action (e.g., providing API keys, external setup).
Do NOT attempt to complete [?] tasks — skip them entirely and focus only on [ ] tasks.
If all [ ] tasks are done but [?] tasks remain, commit your work and stop."
    fi

    cat <<EOF
# Task
$effective_task

# Context
This is iteration $iteration of $max_iter in an autonomous Ralph loop.
Previous work is visible in the git history and current file state.

# Instructions
1. Read CLAUDE.md first — it contains the project workflow and specific instructions
2. Follow the workflow described in CLAUDE.md exactly
3. Do ONLY what is specified in YOUR TASK above — nothing more
4. If stuck on the same issue, try a different approach
$openspec_instructions
$manual_task_instruction
# Previous Work
$prev_text

# Important
- Do ONLY the task specified above — do NOT work on other changes
- CLAUDE.md is the authoritative source for your workflow — follow it
- Commit your changes before exiting
$reflection_section
EOF
}
