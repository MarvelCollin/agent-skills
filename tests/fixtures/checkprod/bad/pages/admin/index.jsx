import { useEffect, useState } from "react"

export default function Admin() {
  const [user, setUser] = useState(null)
  useEffect(() => { fetch("/api/me").then((r) => r.json()).then(setUser) }, [])
  if (!user || user.role !== "admin") return null
  return <h1>Admin</h1>
}
