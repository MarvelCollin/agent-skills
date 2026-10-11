import Link from "next/link"

export default function Footer() {
  return (
    <footer className="border-t px-4 py-8 text-sm">
      <p>Tidepool Labs Ltd, 41 Harbour Road, Bristol BS1 5TY, United Kingdom</p>
      <a href="mailto:hello@tidepool.studio">hello@tidepool.studio</a>
      <Link href="/privacy">Privacy policy</Link>
      <Link href="/terms">Terms of service</Link>
    </footer>
  )
}
