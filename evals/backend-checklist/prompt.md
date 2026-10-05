---
tags: [backend, checklist]
runs: 1
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Bash, Write]
---

Run the backend essentials checklist on this service. I want to know what is missing before launch.

```js
const express = require("express")
const jwt = require("jsonwebtoken")
const cors = require("cors")
const { Pool } = require("pg")

const pool = new Pool({ connectionString: "postgres://admin:hunter2@db.internal/app" })
const app = express()
app.use(cors({ origin: true, credentials: true }))
app.use(express.json())

app.post("/login", async (req, res) => {
  const { rows } = await pool.query(`SELECT * FROM users WHERE email = '${req.body.email}'`)
  if (!rows[0] || rows[0].password !== req.body.password) return res.status(401).send("bad login")
  const token = jwt.sign({ id: rows[0].id }, process.env.JWT_SECRET || "dev")
  res.cookie("token", token)
  res.json({ ok: true })
})

app.get("/products", async (req, res) => {
  const { rows } = await pool.query("SELECT * FROM products")
  for (const p of rows) {
    p.stock = (await pool.query("SELECT COUNT(*) FROM inventory WHERE product_id = " + p.id)).rows[0].count
  }
  res.json(rows)
})

app.use((err, req, res, next) => res.status(500).send(err.stack))
app.listen(3000)
```
