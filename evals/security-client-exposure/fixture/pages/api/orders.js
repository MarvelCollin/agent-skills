import { db } from "../../lib/db"
import { getUser } from "../../lib/auth"

export default async function handler(req, res) {
  const user = getUser(req)
  const { items, price, role } = req.body

  if (role === "admin") {
    return res.json(await db.order.findMany())
  }

  const order = await db.order.create({
    data: {
      userId: user.id,
      items,
      total: price,
      status: req.body.status || "pending"
    }
  })

  res.status(201).json(order)
}
