import { compare } from "bcryptjs"
import { db } from "../../lib/db"
import { signToken } from "../../lib/auth"

export default async function handler(req, res) {
  const user = await db.user.findUnique({ where: { email: req.body.email } })

  if (!user || !(await compare(req.body.password, user.passwordHash))) {
    return res.status(401).json({ error: "Invalid credentials" })
  }

  res.json({
    token: signToken(user),
    user: { id: user.id, email: user.email, role: user.role }
  })
}
