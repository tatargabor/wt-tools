#!/usr/bin/env bash
# Bash completions for wt-* commands

# Get list of active worktree change-ids
_wt_get_worktrees() {
    wt-list 2>/dev/null | grep -E '^\s+\w' | awk '{print $1}' 2>/dev/null
}

# Get list of remote change branches
_wt_get_remote_branches() {
    git fetch -q 2>/dev/null
    git branch -r 2>/dev/null | grep 'origin/change/' | sed 's|.*origin/change/||' 2>/dev/null
}

# wt-work completion: existing worktrees + remote branches
_wt_work_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--terminal --help"

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    else
        local worktrees=$(_wt_get_worktrees)
        local remotes=$(_wt_get_remote_branches)
        COMPREPLY=($(compgen -W "${worktrees} ${remotes}" -- "${cur}"))
    fi
}

# wt-close completion: existing worktrees only
_wt_close_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--force --keep-branch --delete-remote --help"

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    else
        local worktrees=$(_wt_get_worktrees)
        COMPREPLY=($(compgen -W "${worktrees}" -- "${cur}"))
    fi
}

# wt-merge completion: existing worktrees only
_wt_merge_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--target --no-delete --help"

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    else
        local worktrees=$(_wt_get_worktrees)
        COMPREPLY=($(compgen -W "${worktrees}" -- "${cur}"))
    fi
}

# wt-new completion: just flags (change-id is new)
_wt_new_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--new --project --help"

    if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    fi
}

# wt-list completion: flags only
_wt_list_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--all --remote --project --help"
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
}

# wt-project completion: subcommands
_wt_project_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
        wt-project)
            COMPREPLY=($(compgen -W "init list remove default --help" -- "${cur}"))
            ;;
        remove|default)
            # Complete with registered project names
            local projects=$(wt-project list 2>/dev/null | grep -E '^\s+\w' | awk '{print $1}' | sed 's/(default)//')
            COMPREPLY=($(compgen -W "${projects}" -- "${cur}"))
            ;;
    esac
}

# wt-jira completion: subcommands
_wt_jira_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
        wt-jira)
            COMPREPLY=($(compgen -W "init test show log sync create-story rename-story move-subtask --help" -- "${cur}"))
            ;;
        log)
            # Suggest common durations
            COMPREPLY=($(compgen -W "30m 1h 2h 3h 4h 1d" -- "${cur}"))
            ;;
        sync)
            COMPREPLY=($(compgen -W "--dry-run --project --yes" -- "${cur}"))
            ;;
    esac
}

# Register completions
complete -F _wt_work_completions wt-work
complete -F _wt_close_completions wt-close
complete -F _wt_merge_completions wt-merge
complete -F _wt_new_completions wt-new
complete -F _wt_list_completions wt-list
complete -F _wt_project_completions wt-project
complete -F _wt_jira_completions wt-jira
