import { supabase } from "../lib/supabaseClient"

export default function Checkout({ items }) {
  const total = items.reduce((sum, item) => sum + item.price * item.qty, 0)
  async function pay() {
    await fetch("/api/orders", { method: "POST", body: JSON.stringify({ items, total, price: total, status: "paid" }) })
    await supabase.from("orders").update({ status: "paid", total }).eq("id", items[0].orderId)
  }
  const stripeKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY
  return <button onClick={pay} data-key={stripeKey}>Pay {total}</button>
}
