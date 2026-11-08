import React from "react"
import ReactDOM from "react-dom/client"
import { BrowserRouter, Routes, Route, NavLink } from "react-router-dom"
import Dashboard from "./pages/Dashboard"
import Students from "./pages/Students"
import StudentDetail from "./pages/StudentDetail"
import Settings from "./pages/Settings"
import "./index.css"

function Layout({ children }) {
  return (
    <div className="shell">
      <aside className="sidebar glass">
        <div className="logo">🎓 Markwise</div>
        <NavLink to="/">🏠 Home</NavLink>
        <NavLink to="/students">👥 Students <span className="pill">New</span></NavLink>
        <NavLink to="/settings">⚙️ Settings</NavLink>
      </aside>
      <main className="content">{children}</main>
    </div>
  )
}

ReactDOM.createRoot(document.getElementById("root")).render(
  <BrowserRouter>
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/students" element={<Students />} />
        <Route path="/students/:id" element={<StudentDetail />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Layout>
  </BrowserRouter>
)
