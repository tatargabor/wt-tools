#!/usr/bin/env bash
# lib/orchestration/builder.sh — Base build health check and LLM-assisted fixing
# Dependencies: state.sh, events.sh must be sourced first

# ─── Base Build Health ───────────────────────────────────────────────

# Cached base build result: "pass", "fail:<output>", or "" (unchecked)
BASE_BUILD_STATUS=""
BASE_BUILD_OUTPUT=""
BASE_BUILD_FIX_ATTEMPTED=false

# Run build on the main project directory (not a worktree).
# Caches result in BASE_BUILD_STATUS / BASE_BUILD_OUTPUT for the session.
# Returns 0 if build passes, 1 if it fails.
check_base_build() {
    local project_path="$1"

    # Return cached result
    if [[ "$BASE_BUILD_STATUS" == "pass" ]]; then
        return 0
    elif [[ "$BASE_BUILD_STATUS" == "fail" ]]; then
        return 1
    fi

    # Detect build command + package manager
    local pm="npm"
    [[ -f "$project_path/pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "$project_path/yarn.lock" ]] && pm="yarn"
    [[ -f "$project_path/bun.lockb" || -f "$project_path/bun.lock" ]] && pm="bun"

    local build_cmd=""
    if [[ -f "$project_path/package.json" ]]; then
        build_cmd=$(cd "$project_path" && node -e "
            const p = require('./package.json');
            const s = p.scripts || {};
            if (s['build:ci']) console.log('build:ci');
            else if (s['build']) console.log('build');
        " 2>/dev/null || true)
    fi

    if [[ -z "$build_cmd" ]]; then
        BASE_BUILD_STATUS="pass"  # No build command = nothing to check
        return 0
    fi

    log_info "Base build check: running $pm run $build_cmd in $project_path"
    local rc=0
    BASE_BUILD_OUTPUT=$(cd "$project_path" && timeout 300 "$pm" run "$build_cmd" 2>&1) || rc=$?

    if [[ $rc -eq 0 ]]; then
        BASE_BUILD_STATUS="pass"
        log_info "Base build check: PASS"
        return 0
    else
        BASE_BUILD_STATUS="fail"
        log_warn "Base build check: FAIL — main branch has build errors"
        return 1
    fi
}

# Attempt to fix the main branch build using an LLM agent.
# Commits the fix directly on main if successful.
# Resets BASE_BUILD_STATUS so the next check re-runs.
fix_base_build_with_llm() {
    local project_path="$1"

    # Guard: don't retry if both sonnet and opus already failed this session
    if [[ "$BASE_BUILD_FIX_ATTEMPTED" == "both" ]]; then
        log_info "Base build fix: both sonnet and opus failed this session — skipping"
        return 1
    fi

    log_info "Base build fix: attempting LLM-assisted fix on main branch"
    info "Main branch has build errors — attempting LLM fix..."

    # Detect build command for the prompt
    local pm="npm"
    [[ -f "$project_path/pnpm-lock.yaml" ]] && pm="pnpm"
    [[ -f "$project_path/yarn.lock" ]] && pm="yarn"
    [[ -f "$project_path/bun.lockb" || -f "$project_path/bun.lock" ]] && pm="bun"
    local build_cmd="build"
    if [[ -f "$project_path/package.json" ]]; then
        build_cmd=$(cd "$project_path" && node -e "
            const p = require('./package.json');
            const s = p.scripts || {};
            if (s['build:ci']) console.log('build:ci');
            else if (s['build']) console.log('build');
        " 2>/dev/null || echo "build")
    fi

    local fix_prompt
    fix_prompt=$(cat <<FIX_EOF
The main branch has build errors that are blocking all worktree builds.
Fix these TypeScript/build errors directly on the main branch.

Build command: $pm run $build_cmd
Build output (last 3000 chars):
${BASE_BUILD_OUTPUT: -3000}

Instructions:
1. Analyze the build errors above carefully
2. Fix the root cause (type errors, missing imports, missing @types packages, schema mismatches, etc.)
3. Run: $pm run $build_cmd — confirm it passes
4. Commit the fix with message: "fix: repair main branch build errors"

Do NOT create a worktree — fix directly in the current directory.
FIX_EOF
)

    # Try sonnet first, then escalate to opus if sonnet fails
    local model
    if [[ "$BASE_BUILD_FIX_ATTEMPTED" == "sonnet" ]]; then
        model="$(model_id opus)"
        log_info "Base build fix: sonnet failed previously, escalating to opus"
        info "Sonnet couldn't fix build — trying with Opus..."
    else
        model="$(model_id sonnet)"
    fi

    local fix_rc=0
    (cd "$project_path" && echo "$fix_prompt" | run_claude --model "$model" --max-turns 20) || fix_rc=$?

    if [[ $fix_rc -eq 0 ]]; then
        log_info "Base build fix: LLM fix attempted, re-checking build..."
        BASE_BUILD_STATUS=""  # Reset cache to re-check
        BASE_BUILD_OUTPUT=""
        if check_base_build "$project_path"; then
            log_info "Base build fix: SUCCESS — main branch now builds (model: $model)"
            info "Main branch build fixed successfully"
            orch_remember "LLM fixed main branch build errors (model: $model)" Learning "phase:build,scope:main"
            BASE_BUILD_FIX_ATTEMPTED="done"
            return 0
        fi
    fi

    # Mark which model we tried
    if [[ "$BASE_BUILD_FIX_ATTEMPTED" == "sonnet" ]]; then
        BASE_BUILD_FIX_ATTEMPTED="both"
        log_error "Base build fix: opus also failed — manual intervention needed"
    else
        BASE_BUILD_FIX_ATTEMPTED="sonnet"
        log_warn "Base build fix: sonnet failed — will try opus on next attempt"
        # Return 1 but allow retry with opus
    fi
    send_notification "wt-orchestrate" "Main branch build fix FAILED (tried: ${BASE_BUILD_FIX_ATTEMPTED}) — manual intervention needed" "critical"
    return 1
}

# Sync a worktree branch with main to pick up fixes that landed after the branch was created.
# Uses git merge (not rebase) to preserve commit history and avoid force-push issues.
# Returns 0 if sync succeeded (or was unnecessary), 1 if merge conflicts occurred.
