import express from "express"
import cors from "cors"
import Stripe from "stripe"
import admin from "firebase-admin"

admin.initializeApp()
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY)
const app = express()
app.use(cors())
app.use(express.json())

app.post("/api/checkout", async (req, res) => {
  console.log("checkout request", req.body)
  const session = await stripe.checkout.sessions.create({
    mode: "payment",
    line_items: [{ price_data: { currency: "usd", unit_amount: req.body.price, product_data: { name: req.body.planId } }, quantity: 1 }],
    success_url: "https://pocketcoach.example.com/thanks",
    cancel_url: "https://pocketcoach.example.com/pricing"
  })
  res.json({ url: session.url })
})

app.get("/api/admin/users", async (req, res) => {
  const users = await admin.auth().listUsers()
  res.json(users)
})

app.post("/api/contact", async (req, res) => {
  await admin.firestore().collection("messages").add(req.body)
  res.json({ ok: true })
})

app.use((err, req, res, next) => {
  res.status(500).send(err.stack)
})

app.listen(3000)
