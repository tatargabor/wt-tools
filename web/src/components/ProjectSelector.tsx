import type { ProjectInfo } from '../lib/api'

interface Props {
  projects: ProjectInfo[]
  current: string | null
  onChange: (name: string) => void
}

const statusColor: Record<string, string> = {
  running: 'bg-green-500',
  checkpoint: 'bg-yellow-500',
  idle: 'bg-neutral-600',
  stopped: 'bg-neutral-600',
  completed: 'bg-blue-500',
}

export default function ProjectSelector({ projects, current, onChange }: Props) {
  return (
    <select
      value={current ?? ''}
      onChange={(e) => onChange(e.target.value)}
      className="w-full bg-neutral-900 border border-neutral-700 rounded px-2 py-1.5 text-sm text-neutral-200 focus:outline-none focus:border-neutral-500"
    >
      {projects.length === 0 && (
        <option value="" disabled>No projects</option>
      )}
      {projects.map((p) => (
        <option key={p.name} value={p.name}>
          {p.status ? `● ` : ''}{p.name}
        </option>
      ))}
    </select>
  )
}

export function ProjectDot({ status }: { status?: string }) {
  const color = statusColor[status ?? 'idle'] ?? 'bg-neutral-600'
  return <span className={`inline-block w-2 h-2 rounded-full ${color}`} />
}
