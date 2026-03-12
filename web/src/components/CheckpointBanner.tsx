import { useState } from 'react'
import { approve, stopOrchestrator } from '../lib/api'

interface Props {
  project: string
  onDismiss: () => void
}

export default function CheckpointBanner({ project, onDismiss }: Props) {
  const [loading, setLoading] = useState<string | null>(null)
  const [confirmStop, setConfirmStop] = useState(false)

  const handleApprove = async () => {
    setLoading('approve')
    try {
      await approve(project)
      onDismiss()
    } catch {
      // error will show in state
    }
    setLoading(null)
  }

  const handleStop = async () => {
    if (!confirmStop) {
      setConfirmStop(true)
      return
    }
    setLoading('stop')
    try {
      await stopOrchestrator(project)
      onDismiss()
    } catch {
      // error will show in state
    }
    setLoading(null)
    setConfirmStop(false)
  }

  return (
    <div className="flex items-center gap-3 px-4 py-3 bg-yellow-900/30 border-b border-yellow-800/50">
      <span className="text-yellow-300 text-sm font-medium flex-1">
        Checkpoint pending — orchestration is waiting for approval
      </span>
      <button
        onClick={handleApprove}
        disabled={loading !== null}
        className="px-3 py-1.5 text-sm bg-green-700 text-white rounded hover:bg-green-600 disabled:opacity-50 font-medium"
      >
        {loading === 'approve' ? 'Approving...' : 'Approve'}
      </button>
      <button
        onClick={handleStop}
        disabled={loading !== null}
        className={`px-3 py-1.5 text-sm rounded font-medium disabled:opacity-50 ${
          confirmStop
            ? 'bg-red-700 text-white hover:bg-red-600'
            : 'bg-neutral-700 text-neutral-300 hover:bg-neutral-600'
        }`}
      >
        {confirmStop ? 'Confirm Stop' : 'Stop'}
      </button>
    </div>
  )
}
