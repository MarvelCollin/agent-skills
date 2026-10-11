import { useState } from "react"
import { Link } from "react-router-dom"
import { askCoach } from "./lib/ai"
import Footer from "./Footer"

export default function App() {
  const [answer, setAnswer] = useState("")
  async function ask() {
    setAnswer(await askCoach("Plan my week"))
  }
  return (
    <main className="hero">
      <img src="/hero.png" />
      <h1>Your AI coach in your pocket</h1>
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
      <img src="/team.jpg" alt="IMG_2041.jpg" />
      <section>
        <p>"PocketCoach changed my life." Jane Doe, CEO at Acme Corp</p>
      </section>
      <button onClick={ask}>Learn more</button>
      <p>{answer}</p>
      <Link to="/pricing">Pricing</Link>
      <Footer />
    </main>
  )
}
