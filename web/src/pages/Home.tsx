import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { getProjects, type ProjectInfo } from '../lib/api'

const statusStyle: Record<string, { dot: string; label: string }> = {
  running: { dot: 'bg-green-500 animate-pulse', label: 'Running' },
  checkpoint: { dot: 'bg-yellow-500 animate-pulse', label: 'Checkpoint' },
  completed: { dot: 'bg-blue-500', label: 'Completed' },
  stopped: { dot: 'bg-neutral-500', label: 'Stopped' },
  failed: { dot: 'bg-red-500', label: 'Failed' },
  idle: { dot: 'bg-neutral-700', label: 'Idle' },
  error: { dot: 'bg-red-900', label: 'Error' },
}

export default function Home() {
  const [projects, setProjects] = useState<ProjectInfo[]>([])

  useEffect(() => {
    const load = () => getProjects().then(setProjects).catch(() => {})
    load()
    const interval = setInterval(load, 5000)
    return () => clearInterval(interval)
  }, [])

  const active = projects.filter((p) => p.status && !['idle', 'error'].includes(p.status))
  const idle = projects.filter((p) => !p.status || p.status === 'idle')
  const errored = projects.filter((p) => p.status === 'error')

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <h1 className="text-xl font-semibold text-neutral-100 mb-6">wt-tools Dashboard</h1>

      {active.length > 0 && (
        <section className="mb-8">
          <h2 className="text-sm font-medium text-neutral-400 uppercase tracking-wider mb-3">Active Orchestrations</h2>
          <div className="space-y-2">
            {active.map((p) => (
              <ProjectCard key={p.name} project={p} />
            ))}
          </div>
        </section>
      )}

      <section className="mb-8">
        <h2 className="text-sm font-medium text-neutral-400 uppercase tracking-wider mb-3">
          Projects ({idle.length})
        </h2>
        <div className="grid grid-cols-2 gap-2">
          {idle.map((p) => (
            <ProjectCard key={p.name} project={p} compact />
          ))}
        </div>
      </section>

      {errored.length > 0 && (
        <section>
          <h2 className="text-sm font-medium text-neutral-400 uppercase tracking-wider mb-3">
            Unavailable ({errored.length})
          </h2>
          <div className="grid grid-cols-2 gap-2">
            {errored.map((p) => (
              <ProjectCard key={p.name} project={p} compact />
            ))}
          </div>
        </section>
      )}
    </div>
  )
}

function ProjectCard({ project, compact }: { project: ProjectInfo; compact?: boolean }) {
  const s = statusStyle[project.status ?? 'idle'] ?? statusStyle.idle

  return (
    <Link
      to={`/wt/${project.name}`}
      className={`block rounded-lg border border-neutral-800 hover:border-neutral-700 transition-colors ${
        compact ? 'p-3' : 'p-4 bg-neutral-900/50'
      }`}
    >
      <div className="flex items-center gap-2">
        <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${s.dot}`} />
        <span className="font-mono text-sm text-neutral-200 truncate">{project.name}</span>
        {!compact && (
          <span className="ml-auto text-xs text-neutral-500">{s.label}</span>
        )}
      </div>
      {!compact && (
        <div className="mt-1 text-xs text-neutral-500 font-mono truncate">{project.path}</div>
      )}
    </Link>
  )
}
