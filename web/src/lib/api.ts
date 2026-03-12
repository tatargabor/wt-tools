/** Typed fetch wrappers for all REST endpoints. */

const BASE = '/api'

async function fetchJSON<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, init)
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`${res.status}: ${text}`)
  }
  return res.json()
}

// --- Types ---

export interface ProjectInfo {
  name: string
  path: string
  status?: string
}

export interface ChangeInfo {
  name: string
  status: string
  iteration?: number
  ralph_pid?: number
  worktree?: string
  branch?: string
  tokens_in?: number
  tokens_out?: number
  tokens_cache_read?: number
  tokens_cache_write?: number
  duration_s?: number
  gates?: Record<string, GateResult>
  extras?: Record<string, unknown>
}

export interface GateResult {
  status: 'pass' | 'fail' | 'skip' | 'pending'
  duration_s?: number
  output?: string
}

export interface StateData {
  plan_version?: string
  status?: string
  orchestrator_pid?: number
  changes: ChangeInfo[]
  started_at?: string
  completed?: number
  total?: number
  tokens_in?: number
  tokens_out?: number
  tokens_cache_read?: number
  tokens_cache_write?: number
}

export interface WorktreeInfo {
  path: string
  branch: string
  head: string
  bare?: boolean
  loop_state?: {
    iteration?: number
    status?: string
    change?: string
  }
  activity?: {
    skill?: string
    skill_args?: string
    broadcast?: string
    updated_at?: string
  }
}

export interface ActivityInfo {
  worktree: string
  skill?: string
  skill_args?: string
  broadcast?: string
  updated_at?: string
}

// --- Read endpoints ---

export function getProjects(): Promise<ProjectInfo[]> {
  return fetchJSON('/projects')
}

export function getState(project: string): Promise<StateData> {
  return fetchJSON(`/${project}/state`)
}

export function getChanges(project: string): Promise<ChangeInfo[]> {
  return fetchJSON(`/${project}/changes`)
}

export function getChange(project: string, name: string): Promise<ChangeInfo> {
  return fetchJSON(`/${project}/changes/${name}`)
}

export function getWorktrees(project: string): Promise<WorktreeInfo[]> {
  return fetchJSON(`/${project}/worktrees`)
}

export function getActivity(project: string): Promise<ActivityInfo[]> {
  return fetchJSON(`/${project}/activity`)
}

export function getLog(project: string): Promise<{ lines: string[] }> {
  return fetchJSON(`/${project}/log`)
}

// --- Write endpoints ---

export function approve(project: string): Promise<{ ok: boolean }> {
  return fetchJSON(`/${project}/approve`, { method: 'POST' })
}

export function stopOrchestrator(project: string): Promise<{ ok: boolean }> {
  return fetchJSON(`/${project}/stop`, { method: 'POST' })
}

export function stopChange(project: string, name: string): Promise<{ ok: boolean }> {
  return fetchJSON(`/${project}/changes/${name}/stop`, { method: 'POST' })
}

export function skipChange(project: string, name: string): Promise<{ ok: boolean }> {
  return fetchJSON(`/${project}/changes/${name}/skip`, { method: 'POST' })
}
