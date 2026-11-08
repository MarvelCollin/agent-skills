export function PlanSummary({ total, seats }: { total: number, seats: number }) {
  return (
    <section className="grid gap-6">
      <p className="font-mono text-xs uppercase tracking-widest">Billing</p>
      <h2 className="text-3xl font-semibold">Grade quizzes <em className="font-serif">faster</em></h2>
      <h3 className="text-xl font-semibold">Every seat<br />billed monthly</h3>
      <p className="text-sm text-gray-400">Renews on the first of each month.</p>
      <p className="text-2xl font-semibold">{total.toFixed(2)} for {seats} seats</p>
    </section>
  )
}
