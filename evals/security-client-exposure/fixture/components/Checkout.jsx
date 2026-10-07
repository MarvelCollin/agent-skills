"use client"

export default function Checkout({ cart }) {
  async function pay() {
    const user = JSON.parse(localStorage.getItem("user"))

    await fetch("https://api.stripe.com/v1/payment_intents", {
      method: "POST",
      headers: { Authorization: "Bearer " + process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY },
      body: new URLSearchParams({ amount: String(cart.total * 100), currency: "usd" })
    })

    await fetch("/api/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + localStorage.getItem("token")
      },
      body: JSON.stringify({ items: cart.items, price: cart.total, role: user.role })
    })
  }

  return <button onClick={pay}>Pay {cart.total}</button>
}
