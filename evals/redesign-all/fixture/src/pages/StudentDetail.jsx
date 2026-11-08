import { useEffect, useState } from "react"
import { useParams } from "react-router-dom"
import { getStudent } from "../api"
import { letterGrade, averageScore } from "../lib/grade"

export default function StudentDetail() {
  const { id } = useParams()
  const [student, setStudent] = useState(null)
  useEffect(() => {
    getStudent(id).then(setStudent)
  }, [id])
  if (!student) return <p>Loading...</p>
  const average = averageScore(student.scores.map((s) => s.score))
  return (
    <div className="page">
      <div className="card">
        <p>Name: {student.name}</p>
        <p>Email: {student.email}</p>
        <p>Role: <span className="pill">{student.role}</span></p>
        <p>Average: {average.toFixed(1)} ({letterGrade(average)})</p>
      </div>
      <h3>Test results</h3>
      {student.scores.map((s) => (
        <div className="card" key={s.test}>
          <span className="mono-label">TEST</span> {s.test}: {s.score.toFixed(1)}
        </div>
      ))}
    </div>
  )
}
