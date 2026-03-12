import { useState, useEffect } from 'react'
import { getWorktrees, type WorktreeInfo } from '../lib/api'

interface Props {
  project: string | null
}

export default function Worktrees({ project }: Props) {
  const [worktrees, setWorktrees] = useState<WorktreeInfo[]>([])

  useEffect(() => {
    if (!project) return
    getWorktrees(project).then(setWorktrees).catch(() => setWorktrees([]))
    const interval = setInterval(() => {
      getWorktrees(project).then(setWorktrees).catch(() => {})
    }, 10000)
    return () => clearInterval(interval)
  }, [project])

  if (!project) {
    return (
      <div className="flex items-center justify-center h-full text-neutral-500">
        Select a project
      </div>
    )
  }

  return (
    <div className="p-4">
      <h2 className="text-lg font-semibold text-neutral-100 mb-4">Worktrees</h2>
      {worktrees.length === 0 ? (
        <p className="text-neutral-500">No worktrees found</p>
      ) : (
        <div className="space-y-3">
          {worktrees.map((wt) => (
            <div key={wt.path} className="bg-neutral-900 rounded-lg p-4 border border-neutral-800">
              <div className="flex items-center justify-between mb-2">
                <span className="font-mono text-sm text-neutral-300">{wt.branch}</span>
                <span className="text-xs text-neutral-500 font-mono">{wt.head?.slice(0, 8)}</span>
              </div>
              <div className="text-xs text-neutral-500 mb-2 font-mono truncate">{wt.path}</div>
              {wt.loop_state && (
                <div className="flex gap-4 text-xs text-neutral-400">
                  <span>Iteration: {wt.loop_state.iteration ?? '—'}</span>
                  <span>Status: {wt.loop_state.status ?? '—'}</span>
                  {wt.loop_state.change && <span>Change: {wt.loop_state.change}</span>}
                </div>
              )}
              {wt.activity && (
                <div className="mt-2 text-xs text-neutral-400">
                  {wt.activity.broadcast && (
                    <p className="text-neutral-300">{wt.activity.broadcast}</p>
                  )}
                  {wt.activity.skill && (
                    <p>Skill: {wt.activity.skill} {wt.activity.skill_args ?? ''}</p>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
