import { useRef, useEffect, useState } from 'react'
import type { ChangeInfo, SessionInfo } from '../lib/api'
import { getChangeSession } from '../lib/api'

interface Props {
  orchLines: string[]
  selectedChange: ChangeInfo | null
  project: string
}

function orchLineColor(line: string): string {
  if (line.includes('ERROR')) return 'text-red-400'
  if (line.includes('WARN')) return 'text-yellow-400'
  if (line.includes('REPLAN')) return 'text-cyan-400'
  if (line.includes('CHECKPOINT')) return 'text-yellow-300'
  return 'text-neutral-400'
}

function sessionLineColor(line: string): string {
  if (line.startsWith('>>>')) return 'text-neutral-200'
  if (line.startsWith('  [Read]') || line.startsWith('  [Glob]') || line.startsWith('  [Grep]'))
    return 'text-cyan-500/70'
  if (line.startsWith('  [Write]') || line.startsWith('  [Edit]'))
    return 'text-amber-400/80'
  if (line.startsWith('  [Bash]'))
    return 'text-purple-400/80'
  if (line.startsWith('  ['))
    return 'text-neutral-500'
  if (line.startsWith('---'))
    return 'text-neutral-600'
  if (line.includes('ERROR') || line.includes('error')) return 'text-red-400'
  if (line.includes('WARN') || line.includes('warning')) return 'text-yellow-400'
  return 'text-neutral-400'
}

type ActiveView = { kind: 'orch' } | { kind: 'session'; sessionId: string }

export default function LogPanel({ orchLines, selectedChange, project }: Props) {
  const [activeView, setActiveView] = useState<ActiveView>({ kind: 'orch' })
  const [sessions, setSessions] = useState<SessionInfo[]>([])
  const [sessionLines, setSessionLines] = useState<string[]>([])
  const [sessionLoading, setSessionLoading] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const [autoScroll, setAutoScroll] = useState(true)

  // When change selection changes, load sessions and auto-select latest
  useEffect(() => {
    if (!selectedChange) {
      setActiveView({ kind: 'orch' })
      setSessions([])
      setSessionLines([])
      return
    }
    // Fetch with no session_id to get latest + session list
    setSessionLoading(true)
    getChangeSession(project, selectedChange.name, 500)
      .then((data) => {
        setSessions(data.sessions)
        setSessionLines(data.lines)
        if (data.session_id) {
          setActiveView({ kind: 'session', sessionId: data.session_id })
        }
        setTimeout(() => {
          if (containerRef.current) containerRef.current.scrollTop = containerRef.current.scrollHeight
        }, 50)
      })
      .catch(() => {
        setSessions([])
        setSessionLines(['(Failed to load session)'])
      })
      .finally(() => setSessionLoading(false))
  }, [project, selectedChange?.name])

  // Load specific session when switching tabs
  const loadSession = (sessionId: string) => {
    if (!selectedChange) return
    setActiveView({ kind: 'session', sessionId })
    setSessionLoading(true)
    getChangeSession(project, selectedChange.name, 500, sessionId)
      .then((data) => {
        setSessionLines(data.lines)
        setTimeout(() => {
          if (containerRef.current) containerRef.current.scrollTop = containerRef.current.scrollHeight
        }, 50)
      })
      .catch(() => setSessionLines(['(Failed to load session)']))
      .finally(() => setSessionLoading(false))
  }

  // Auto-refresh active session for running changes
  useEffect(() => {
    if (activeView.kind !== 'session' || !selectedChange || selectedChange.status !== 'running') return
    const sid = activeView.sessionId
    const interval = setInterval(() => {
      getChangeSession(project, selectedChange.name, 500, sid)
        .then((data) => {
          setSessionLines(data.lines)
          // Update sessions list too (new session may have appeared)
          if (data.sessions.length !== sessions.length) {
            setSessions(data.sessions)
          }
        })
        .catch(() => {})
    }, 3000)
    return () => clearInterval(interval)
  }, [activeView, project, selectedChange?.name, selectedChange?.status, sessions.length])

  // Determine what to display
  const isOrch = activeView.kind === 'orch'
  const lines = isOrch ? orchLines : sessionLines
  const colorFn = isOrch ? orchLineColor : sessionLineColor

  // Auto-scroll
  useEffect(() => {
    if (autoScroll && containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight
    }
  }, [lines, autoScroll])

  const handleScroll = () => {
    if (!containerRef.current) return
    const { scrollTop, scrollHeight, clientHeight } = containerRef.current
    setAutoScroll(scrollHeight - scrollTop - clientHeight < 50)
  }

  // Session tab label: show index + short time
  const sessionLabel = (s: SessionInfo, idx: number) => {
    const d = new Date(s.mtime)
    const time = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    return `#${sessions.length - idx} ${time}`
  }

  return (
    <div className="relative h-full flex flex-col">
      {/* Tab bar */}
      <div className="flex items-center gap-1 px-3 py-1 border-b border-neutral-800 bg-neutral-900/50 overflow-x-auto">
        <button
          onClick={() => setActiveView({ kind: 'orch' })}
          className={`px-2 py-0.5 text-xs rounded transition-colors shrink-0 ${
            isOrch
              ? 'bg-neutral-800 text-neutral-200'
              : 'text-neutral-500 hover:text-neutral-300'
          }`}
        >
          Orch Log
        </button>
        {selectedChange && sessions.length > 0 && (
          <>
            <span className="text-[10px] text-neutral-700 mx-0.5 shrink-0">|</span>
            <span className="text-[10px] text-neutral-600 shrink-0 mr-1">
              {selectedChange.name}
            </span>
            {sessions.map((s, i) => {
              const isActive = activeView.kind === 'session' && activeView.sessionId === s.id
              const isLatest = i === 0
              return (
                <button
                  key={s.id}
                  onClick={() => loadSession(s.id)}
                  className={`px-1.5 py-0.5 text-xs rounded font-mono transition-colors shrink-0 ${
                    isActive
                      ? 'bg-blue-900/60 text-blue-300'
                      : 'text-neutral-500 hover:text-neutral-300 hover:bg-neutral-900'
                  }`}
                  title={`Session ${s.id.slice(0, 8)}… — ${new Date(s.mtime).toLocaleString()}`}
                >
                  {sessionLabel(s, i)}{isLatest ? ' ●' : ''}
                </button>
              )
            })}
          </>
        )}
        <span className="ml-auto text-xs text-neutral-600 shrink-0">
          {lines.length} lines
          {!isOrch && selectedChange?.status === 'running' && (
            <span className="ml-2 text-green-600 animate-pulse">LIVE</span>
          )}
        </span>
      </div>

      {/* Content */}
      <div
        ref={containerRef}
        onScroll={handleScroll}
        className="flex-1 overflow-auto p-2 font-mono text-xs leading-5"
      >
        {sessionLoading && !isOrch && (
          <p className="text-neutral-600">Loading session...</p>
        )}
        {lines.map((line, i) => (
          <div key={i} className={colorFn(line)}>
            {line}
          </div>
        ))}
        {!sessionLoading && !isOrch && lines.length === 0 && (
          <p className="text-neutral-600">No session data yet</p>
        )}
      </div>

      {/* Jump to bottom */}
      {!autoScroll && (
        <button
          onClick={() => {
            setAutoScroll(true)
            if (containerRef.current) {
              containerRef.current.scrollTop = containerRef.current.scrollHeight
            }
          }}
          className="absolute bottom-3 right-3 px-2 py-1 text-xs bg-neutral-800 text-neutral-300 rounded hover:bg-neutral-700"
        >
          Jump to bottom
        </button>
      )}
    </div>
  )
}
