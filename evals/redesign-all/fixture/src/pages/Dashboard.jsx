import { useEffect, useState } from "react"
import { getStats } from "../api"
import { averageScore } from "../lib/grade"

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  useEffect(() => {
    getStats().then(setStats)
  }, [])
  if (!stats) return <p>Loading...</p>
  return (
    <div className="page">
      <span className="eyebrow">✨ New dashboard</span>
      <h1>Welcome to the <em>future</em> of grading</h1>
      <p className="muted">Everything you need — all in one place.</p>
      <div className="stats">
        <div className="card"><div className="icon-tile">📝</div><span>Questions</span><b>{stats.questions}</b></div>
        <div className="card"><div className="icon-tile">👥</div><span>Students</span><b>{stats.students}</b></div>
        <div className="card"><div className="icon-tile">📊</div><span>Average score</span><b>{averageScore(stats.scores).toFixed(1)}</b></div>
      </div>
    </div>
  )
}
