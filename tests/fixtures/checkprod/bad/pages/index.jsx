import Head from "next/head"
import Link from "next/link"
import Footer from "../components/Footer"

export default function Home() {
  return (
    <main>
      <Head>
        <title>Shopfront</title>
      </Head>
      <h1>Lorem ipsum dolor sit amet</h1>
      <img src="/hero.png" />
      <img
        src="/team.jpg"
        alt="team.jpg"
      />
      <p>"Best purchase I ever made." John Doe, Acme Inc</p>
      <p>Visit us at 123 Main St or call (555) 123-4567</p>
      <Link href="/contact">Contact</Link>
      <p>Shipping times: TODO</p>
      <Footer />
    </main>
  )
}
