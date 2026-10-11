import Image from "next/image"
import Link from "next/link"

export const metadata = {
  title: "Searchable notes from every customer call",
  description: "Record support calls, get clean notes and find any answer in seconds."
}

export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl px-4 md:px-8">
      <section className="py-16 md:py-24">
        <h1 className="text-3xl md:text-5xl">Every customer call, searchable</h1>
        <p>Tidepool records your support calls and writes notes your team can search.</p>
        <Link href="/contact" className="mt-6 inline-block rounded-md bg-teal-700 px-5 py-3 text-white">Book a demo</Link>
      </section>
      <Image src="/screens/inbox.png" alt="The Tidepool inbox with three call notes" width={1200} height={750} />
      <Image
        src="/divider.svg"
        alt=""
        width={1200}
        height={8}
      />
    </main>
  )
}
