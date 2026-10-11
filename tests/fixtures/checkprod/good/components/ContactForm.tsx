"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"

export default function ContactForm() {
  const router = useRouter()
  const [error, setError] = useState("")

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    const response = await fetch("/api/contact", { method: "POST", body: form })
    if (!response.ok) {
      setError("Enter a valid work email")
      return
    }
    router.push("/contact/thank-you")
  }

  return (
    <form onSubmit={onSubmit} noValidate>
      <label htmlFor="email">Work email</label>
      <input id="email" name="email" type="email" aria-invalid={error !== ""} aria-describedby="email-error" />
      {error && <p id="email-error">{error}</p>}
      <label htmlFor="message">Message</label>
      <textarea id="message" name="message" />
      <button type="submit">Send</button>
    </form>
  )
}
