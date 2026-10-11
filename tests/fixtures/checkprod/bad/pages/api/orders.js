import { query } from "../../lib/db"

export default async function handler(req, res) {
  const { rows } = await query(`SELECT * FROM orders WHERE id = ${req.query.id}`)
  if (req.method === "POST") {
    const order = { item: req.body.item, price: req.body.price, status: req.body.status }
    await query("INSERT INTO orders (item, price, status) VALUES ($1, $2, $3)", [order.item, order.price, order.status])
  }
  res.setHeader("Access-Control-Allow-Origin", "*")
  res.status(200).json(rows)
}
