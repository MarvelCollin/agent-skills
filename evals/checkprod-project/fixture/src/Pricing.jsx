import { useEffect, useState } from "react"
import { getPlans } from "./lib/firebase"

export default function Pricing() {
  const [plans, setPlans] = useState([])
  useEffect(() => {
    getPlans().then(setPlans)
  }, [])
  async function buy(plan) {
    await fetch("/api/checkout", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ planId: plan.id, price: plan.price }) })
  }
  return (
    <main className="hero">
      <h1>Pricing</h1>
      {plans.map((plan) => (
        <button key={plan.id} onClick={() => buy(plan)}>{plan.name} {plan.price}</button>
      ))}
    </main>
  )
}
