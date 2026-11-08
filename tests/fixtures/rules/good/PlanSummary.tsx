export function PlanSummary({ total, seats }: { total: number, seats: number }) {
  return (
    <section className="grid gap-6">
      <p className="text-sm font-medium text-stone-600">Billing</p>
      <h2 className="text-3xl font-semibold text-balance">Grade a class of quizzes in two minutes</h2>
      <p className="text-sm text-stone-600 text-pretty">Renews on the first of each month. Invoice <code className="font-mono">INV-2041</code></p>
      <p className="text-2xl font-semibold tabular-nums">{total.toFixed(2)} for {seats} seats</p>
    </section>
  )
}
