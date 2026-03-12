import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { getProjects, type ProjectInfo } from '../lib/api'

export function useProject() {
  const { project: urlProject } = useParams<{ project: string }>()
  const navigate = useNavigate()
  const [projects, setProjects] = useState<ProjectInfo[]>([])

  useEffect(() => {
    getProjects()
      .then((list) => {
        setProjects(list)
        // If no project in URL, redirect to first project
        if (!urlProject && list.length > 0) {
          navigate(`/wt/${list[0].name}`, { replace: true })
        }
      })
      .catch(() => {})
  }, [])

  const setProject = (name: string) => {
    navigate(`/wt/${name}`)
  }

  return { project: urlProject ?? null, setProject, projects }
}
