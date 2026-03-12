import { useState, useEffect } from 'react'
import { getProjects, type ProjectInfo } from '../lib/api'

const STORAGE_KEY = 'wt-web-project'

export function useProject() {
  const [projects, setProjects] = useState<ProjectInfo[]>([])
  const [project, setProjectState] = useState<string | null>(() => {
    return localStorage.getItem(STORAGE_KEY)
  })

  useEffect(() => {
    getProjects()
      .then((list) => {
        setProjects(list)
        // Auto-select first project if none stored
        if (!project && list.length > 0) {
          setProjectState(list[0].name)
          localStorage.setItem(STORAGE_KEY, list[0].name)
        }
      })
      .catch(() => {
        // API not available yet
      })
  }, [])

  const setProject = (name: string) => {
    setProjectState(name)
    localStorage.setItem(STORAGE_KEY, name)
  }

  return { project, setProject, projects }
}
