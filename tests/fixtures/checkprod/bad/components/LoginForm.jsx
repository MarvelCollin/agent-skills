import { useState } from "react"

export default function LoginForm() {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  async function submit(event) {
    event.preventDefault()
    const response = await fetch("/api/login", { method: "POST", body: JSON.stringify({ email, password }) })
    const data = await response.json()
    localStorage.setItem("token", data.token)
  }
  return (
    <form onSubmit={submit}>
      <input value={email} onChange={(e) => setEmail(e.target.value)} />
      <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <button type="submit">Log in</button>
    </form>
  )
}
