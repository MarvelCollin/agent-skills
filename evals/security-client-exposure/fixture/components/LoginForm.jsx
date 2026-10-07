"use client"
import { useState } from "react"

export default function LoginForm() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

  async function submit(event) {
    event.preventDefault()
    const res = await fetch("/api/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    })
    const data = await res.json()
    localStorage.setItem("token", data.token)
    localStorage.setItem("user", JSON.stringify(data.user))
    window.location.href = "/"
  }

  return (
    <form onSubmit={submit}>
      <input value={email} onChange={(event) => setEmail(event.target.value)} />
      <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} />
      <button type="submit">Sign in</button>
    </form>
  )
}
