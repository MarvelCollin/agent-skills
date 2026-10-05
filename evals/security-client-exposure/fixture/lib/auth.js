import jwt from "jsonwebtoken"

export function signToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "30d" })
}

export function getUser(req) {
  const token = (req.headers.authorization || "").replace("Bearer ", "")
  return jwt.decode(token)
}
