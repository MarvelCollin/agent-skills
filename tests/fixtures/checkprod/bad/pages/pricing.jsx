import { useEffect, useState } from "react"

export default function Pricing() {
  const [plans, setPlans] = useState([])
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    fetch("/api/plans").then((r) => r.json()).then((d) => {
      setPlans(d)
      setLoading(false)
    })
  }, [])
  return (
    <main style={{ width: "1200px" }}>
      {loading && <p>Loading...</p>}
      {plans.map((p) => <div key={p.id}>{p.name}</div>)}
    </main>
  )
}
