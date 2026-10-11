import { query } from "../../../lib/db"

export default async function handler(req, res) {
  const { rows } = await query("SELECT id, email, role FROM users")
  res.json(rows)
}
