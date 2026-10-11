import jwt from "jsonwebtoken"
import { query } from "../../lib/db"

export default async function handler(req, res) {
  const { email, password } = req.body
  console.log("login attempt", email, password)
  const { rows } = await query("SELECT id, role, password_hash FROM users WHERE email = '" + email + "'")
  const token = jwt.sign({ id: rows[0].id, role: rows[0].role }, process.env.JWT_SECRET)
  res.setHeader("Set-Cookie", `token=${token}; Path=/`)
  res.status(200).json({ user: rows[0], passwordHash: rows[0].password_hash })
}
