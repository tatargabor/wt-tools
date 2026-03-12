import { useState } from 'react'
import type { ChangeInfo } from '../lib/api'
import { stopChange, skipChange } from '../lib/api'
import GateBar from './GateBar'

interface Props {
  changes: ChangeInfo[]
  project: string
}

const statusColor: Record<string, string> = {
  running: 'text-green-400',
  completed: 'text-blue-400',
  failed: 'text-red-400',
  skipped: 'text-neutral-500',
  pending: 'text-neutral-500',
  checkpoint: 'text-yellow-400',
}

function formatDuration(s?: number): string {
  if (!s) return '—'
  if (s < 60) return `${s.toFixed(0)}s`
  const m = Math.floor(s / 60)
  const rem = Math.floor(s % 60)
  return `${m}m${rem}s`
}

function formatTokens(n?: number): string {
  if (!n) return '—'
  if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`
  if (n >= 1_000) return `${(n / 1_000).toFixed(1)}k`
  return String(n)
}

export default function ChangeTable({ changes, project }: Props) {
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  const handleAction = async (name: string, action: 'stop' | 'skip') => {
    setActionLoading(`${name}:${action}`)
    try {
      if (action === 'stop') await stopChange(project, name)
      if (action === 'skip') await skipChange(project, name)
    } catch {
      // will be reflected in next state update
    }
    setActionLoading(null)
  }

  if (changes.length === 0) {
    return (
      <div className="p-4 text-neutral-500 text-sm">No changes</div>
    )
  }

  return (
    <table className="w-full text-sm">
      <thead>
        <tr className="text-xs text-neutral-500 border-b border-neutral-800">
          <th className="text-left px-4 py-2 font-medium">Name</th>
          <th className="text-left px-2 py-2 font-medium">Status</th>
          <th className="text-center px-2 py-2 font-medium">Iter</th>
          <th className="text-right px-2 py-2 font-medium">Duration</th>
          <th className="text-right px-2 py-2 font-medium">Tokens</th>
          <th className="text-center px-2 py-2 font-medium">Gates</th>
          <th className="text-right px-4 py-2 font-medium">Actions</th>
        </tr>
      </thead>
      <tbody>
        {changes.map((c) => (
          <tr key={c.name} className="border-b border-neutral-800/50 hover:bg-neutral-900/50">
            <td className="px-4 py-2 font-mono text-neutral-200">{c.name}</td>
            <td className={`px-2 py-2 font-medium ${statusColor[c.status] ?? 'text-neutral-400'}`}>
              {c.status}
            </td>
            <td className="px-2 py-2 text-center text-neutral-400">{c.iteration ?? '—'}</td>
            <td className="px-2 py-2 text-right text-neutral-400">{formatDuration(c.duration_s)}</td>
            <td className="px-2 py-2 text-right text-neutral-400 font-mono text-xs">
              {formatTokens(c.tokens_in)}/{formatTokens(c.tokens_out)}
            </td>
            <td className="px-2 py-2">
              <div className="flex justify-center">
                <GateBar gates={c.gates} />
              </div>
            </td>
            <td className="px-4 py-2 text-right">
              <div className="flex gap-1 justify-end">
                {c.status === 'running' && (
                  <button
                    onClick={() => handleAction(c.name, 'stop')}
                    disabled={actionLoading === `${c.name}:stop`}
                    className="px-2 py-0.5 text-xs bg-red-900/50 text-red-300 rounded hover:bg-red-900 disabled:opacity-50"
                  >
                    Stop
                  </button>
                )}
                {c.status === 'pending' && (
                  <button
                    onClick={() => handleAction(c.name, 'skip')}
                    disabled={actionLoading === `${c.name}:skip`}
                    className="px-2 py-0.5 text-xs bg-neutral-800 text-neutral-400 rounded hover:bg-neutral-700 disabled:opacity-50"
                  >
                    Skip
                  </button>
                )}
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
