import { BrowserRouter, Routes, Route, Navigate, useLocation, Link } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Worktrees from './pages/Worktrees'
import Home from './pages/Home'
import ProjectSelector from './components/ProjectSelector'
import { useProject } from './hooks/useProject'

function ProjectLayout() {
  const { project, setProject, projects } = useProject()
  const location = useLocation()

  const pathAfterProject = location.pathname.split('/').slice(3).join('/')
  const activeTab = pathAfterProject || 'dashboard'

  return (
    <div className="flex h-screen bg-neutral-950 text-neutral-200">
      <aside className="w-56 shrink-0 border-r border-neutral-800 flex flex-col">
        <Link to="/wt" className="block p-4 border-b border-neutral-800 hover:bg-neutral-900 transition-colors">
          <h1 className="text-sm font-semibold text-neutral-100 tracking-wide">wt-tools</h1>
        </Link>
        <div className="p-3">
          <ProjectSelector
            projects={projects}
            current={project}
            onChange={setProject}
          />
        </div>
        <nav className="flex-1 p-3 space-y-1">
          <Link
            to={project ? `/wt/${project}` : '/wt'}
            className={`block px-3 py-2 rounded text-sm ${activeTab === 'dashboard' ? 'bg-neutral-800 text-neutral-100' : 'hover:bg-neutral-800 text-neutral-300'}`}
          >
            Dashboard
          </Link>
          <Link
            to={project ? `/wt/${project}/worktrees` : '/wt'}
            className={`block px-3 py-2 rounded text-sm ${activeTab === 'worktrees' ? 'bg-neutral-800 text-neutral-100' : 'hover:bg-neutral-800 text-neutral-300'}`}
          >
            Worktrees
          </Link>
        </nav>
      </aside>

      <main className="flex-1 overflow-auto">
        <Routes>
          <Route index element={<Dashboard project={project} />} />
          <Route path="worktrees" element={<Worktrees project={project} />} />
        </Routes>
      </main>
    </div>
  )
}

function HomeLayout() {
  return (
    <div className="flex h-screen bg-neutral-950 text-neutral-200">
      <aside className="w-56 shrink-0 border-r border-neutral-800 flex flex-col">
        <div className="p-4 border-b border-neutral-800">
          <h1 className="text-sm font-semibold text-neutral-100 tracking-wide">wt-tools</h1>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <Home />
      </main>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/wt" replace />} />
        <Route path="/wt" element={<HomeLayout />} />
        <Route path="/wt/:project/*" element={<ProjectLayout />} />
      </Routes>
    </BrowserRouter>
  )
}
