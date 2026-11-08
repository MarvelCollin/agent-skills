import { useEffect, useState } from "react"
import { Link } from "react-router-dom"
import { getStudents, deleteStudent } from "../api"
import { letterGrade } from "../lib/grade"

export default function Students() {
  const [page, setPage] = useState(1)
  const [q, setQ] = useState("")
  const [role, setRole] = useState("all")
  const [data, setData] = useState({ rows: [], total: 0 })

  function load() {
    getStudents({ page, pageSize: 25, q, role }).then(setData)
  }

  useEffect(load, [page, q, role])

  async function remove(id) {
    if (confirm("Delete this student?")) {
      await deleteStudent(id)
      load()
    }
  }

  return (
    <div className="page">
      <h2>All the students<br />in your school</h2>
      <input placeholder="Search..." value={q} onChange={(e) => setQ(e.target.value)} style={{ width: 380 }} />
      <select value={role} onChange={(e) => setRole(e.target.value)}>
        <option value="all">All roles</option>
        <option value="student">Student</option>
        <option value="assistant">Assistant</option>
      </select>
      <table>
        <thead>
          <tr><th></th><th>Name</th><th>Role</th><th>Score</th><th></th></tr>
        </thead>
        <tbody>
          {data.rows.map((s) => (
            <tr key={s.id}>
              <td><div className="avatar">{s.name.split(" ").map((p) => p.charAt(0)).join("")}</div></td>
              <td><Link to={`/students/${s.id}`}>{s.name}</Link></td>
              <td><span className="pill">{s.role}</span></td>
              <td>{s.score.toFixed(1)} ({letterGrade(s.score)})</td>
              <td><button className="btn" onClick={() => remove(s.id)}>Delete</button></td>
            </tr>
          ))}
        </tbody>
      </table>
      <button className="btn" onClick={() => setPage(page - 1)} disabled={page === 1}>Prev</button>
      <span>Page {page}</span>
      <button className="btn" onClick={() => setPage(page + 1)} disabled={page * 25 >= data.total}>Next</button>
    </div>
  )
}
