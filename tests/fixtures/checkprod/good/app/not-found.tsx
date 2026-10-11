import Link from "next/link"

export default function NotFound() {
  return (
    <main className="mx-auto max-w-xl px-4 py-24">
      <h1>We could not find that page</h1>
      <p>The link may be old. Try the home page or the contact page.</p>
      <Link href="/">Home</Link>
      <Link href="/contact">Contact</Link>
    </main>
  )
}
