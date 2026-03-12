import { BrowserRouter, Routes, Route, Navigate, useLocation, Link } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Worktrees from './pages/Worktrees'
import ProjectSelector from './components/ProjectSelector'
import { useProject } from './hooks/useProject'

function ProjectLayout() {
  const { project, setProject, projects } = useProject()
  const location = useLocation()

  // Determine active tab from URL
  const pathAfterProject = location.pathname.split('/').slice(3).join('/')
  const activeTab = pathAfterProject || 'dashboard'

  return (
    <div className="flex h-screen bg-neutral-950 text-neutral-200">
      {/* Sidebar */}
      <aside className="w-56 shrink-0 border-r border-neutral-800 flex flex-col">
        <div className="p-4 border-b border-neutral-800">
          <h1 className="text-sm font-semibold text-neutral-100 tracking-wide">wt-tools</h1>
        </div>
        <div className="p-3">
          <ProjectSelector
            projects={projects}
            current={project}
            onChange={setProject}
          />
        </div>
        <nav className="flex-1 p-3 space-y-1">
          <Link
            to={project ? `/wt/${project}` : '/'}
            className={`block px-3 py-2 rounded text-sm ${activeTab === 'dashboard' ? 'bg-neutral-800 text-neutral-100' : 'hover:bg-neutral-800 text-neutral-300'}`}
          >
            Dashboard
          </Link>
          <Link
            to={project ? `/wt/${project}/worktrees` : '/'}
            className={`block px-3 py-2 rounded text-sm ${activeTab === 'worktrees' ? 'bg-neutral-800 text-neutral-100' : 'hover:bg-neutral-800 text-neutral-300'}`}
          >
            Worktrees
          </Link>
        </nav>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        <Routes>
          <Route index element={<Dashboard project={project} />} />
          <Route path="worktrees" element={<Worktrees project={project} />} />
        </Routes>
      </main>
    </div>
  )
}

function RootRedirect() {
  // Redirect / to /wt/ which will then redirect to the first project
  return <Navigate to="/wt/" replace />
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<RootRedirect />} />
        <Route path="/wt" element={<ProjectLayout />} />
        <Route path="/wt/:project/*" element={<ProjectLayout />} />
      </Routes>
    </BrowserRouter>
  )
}
