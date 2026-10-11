import Link from "next/link"

export const metadata = {
  title: "Thanks, we got your message",
  description: "We reply within one working day."
}

export default function ThankYouPage() {
  return (
    <main className="mx-auto max-w-xl px-4 py-16">
      <h1>Thanks, we got your message</h1>
      <p>We reply within one working day from hello@tidepool.studio.</p>
      <Link href="/">Back to the home page</Link>
    </main>
  )
}
