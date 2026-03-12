import { useState, useCallback } from 'react'
import { useWebSocket, type WSEvent } from '../hooks/useWebSocket'
import { useNotifications } from '../hooks/useNotifications'
import StatusHeader from '../components/StatusHeader'
import ChangeTable from '../components/ChangeTable'
import LogStream from '../components/LogStream'
import CheckpointBanner from '../components/CheckpointBanner'
import ResizableSplit from '../components/ResizableSplit'
import type { StateData } from '../lib/api'

interface Props {
  project: string | null
}

export default function Dashboard({ project }: Props) {
  const [state, setState] = useState<StateData | null>(null)
  const [logLines, setLogLines] = useState<string[]>([])
  const [checkpoint, setCheckpoint] = useState(false)
  const { notify } = useNotifications()

  const onEvent = useCallback((event: WSEvent) => {
    switch (event.event) {
      case 'state_update':
        setState(event.data as StateData)
        break
      case 'log_lines': {
        const { lines } = event.data as { lines: string[] }
        setLogLines((prev) => [...prev, ...lines].slice(-2000))
        break
      }
      case 'checkpoint_pending':
        setCheckpoint(true)
        notify('Checkpoint pending', `${project} requires approval`)
        break
      case 'change_complete':
        notify('Change complete', `A change finished in ${project}`)
        break
      case 'error':
        notify('Error', `Error in ${project}`)
        break
    }
  }, [project, notify])

  const { connected } = useWebSocket({ project, onEvent })

  if (!project) {
    return (
      <div className="flex items-center justify-center h-full text-neutral-500">
        Select a project to begin
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full">
      <StatusHeader state={state} connected={connected} project={project} />
      {checkpoint && (
        <CheckpointBanner project={project} onDismiss={() => setCheckpoint(false)} />
      )}
      <div className="flex-1 min-h-0">
        <ResizableSplit
          top={<ChangeTable changes={state?.changes ?? []} project={project} />}
          bottom={<LogStream lines={logLines} />}
          defaultRatio={0.55}
        />
      </div>
    </div>
  )
}
