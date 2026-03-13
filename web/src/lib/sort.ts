import type { ProjectInfo } from './api'

/** Sort projects by last_updated descending (most recent first). Nulls go last. */
export function sortByLastUpdated(projects: ProjectInfo[]): ProjectInfo[] {
  return [...projects].sort((a, b) => {
    if (!a.last_updated && !b.last_updated) return 0
    if (!a.last_updated) return 1
    if (!b.last_updated) return -1
    return b.last_updated.localeCompare(a.last_updated)
  })
}
