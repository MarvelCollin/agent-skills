import { useState } from "react"

export default function Contact() {
  const [email, setEmail] = useState("")
  async function send(event) {
    event.preventDefault()
    await fetch("/api/contact", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ email }) })
  }
  return (
    <form onSubmit={send}>
      <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
      <button type="submit">Send</button>
    </form>
  )
}
