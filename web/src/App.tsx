import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Worktrees from './pages/Worktrees'
import ProjectSelector from './components/ProjectSelector'
import { useProject } from './hooks/useProject'

function AppLayout() {
  const { project, setProject, projects } = useProject()

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
          <a href="/" className="block px-3 py-2 rounded text-sm hover:bg-neutral-800 text-neutral-300">
            Dashboard
          </a>
          <a href="/worktrees" className="block px-3 py-2 rounded text-sm hover:bg-neutral-800 text-neutral-300">
            Worktrees
          </a>
        </nav>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">
        <Routes>
          <Route path="/" element={<Dashboard project={project} />} />
          <Route path="/worktrees" element={<Worktrees project={project} />} />
        </Routes>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AppLayout />
    </BrowserRouter>
  )
}
