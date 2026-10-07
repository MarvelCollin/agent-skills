import { db } from "../../../lib/db"

export default async function handler(req, res) {
  const user = await db.user.findUnique({ where: { id: Number(req.query.id) } })

  if (!user) {
    return res.status(404).json({ error: "Not found" })
  }

  res.json(user)
}
