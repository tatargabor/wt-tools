import type { GateResult } from '../lib/api'

interface Props {
  gates?: Record<string, GateResult>
}

const gateLabels: Record<string, string> = {
  test: 'T',
  build: 'B',
  eslint: 'E',
  review: 'R',
  verify: 'V',
  smoke: 'S',
}

const statusStyle: Record<string, string> = {
  pass: 'bg-green-900 text-green-300',
  fail: 'bg-red-900 text-red-300',
  skip: 'bg-neutral-800 text-neutral-500',
  pending: 'bg-neutral-800 text-neutral-600',
}

export default function GateBar({ gates }: Props) {
  if (!gates || Object.keys(gates).length === 0) {
    return <span className="text-neutral-600 text-xs">—</span>
  }

  return (
    <div className="flex gap-0.5">
      {Object.entries(gates).map(([name, result]) => (
        <span
          key={name}
          title={`${name}: ${result.status}${result.duration_s ? ` (${result.duration_s.toFixed(1)}s)` : ''}`}
          className={`w-5 h-5 flex items-center justify-center rounded text-[10px] font-mono font-bold ${statusStyle[result.status] ?? statusStyle.pending}`}
        >
          {gateLabels[name] ?? name.charAt(0).toUpperCase()}
        </span>
      ))}
    </div>
  )
}
