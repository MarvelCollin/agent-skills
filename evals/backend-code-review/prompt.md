---
tags: [backend, review]
runs: 1
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Bash, Write]
---

Review this Express router for backend best practices before we launch. It feels slow already with a few hundred orders. Tell me what to fix first.

```js
const express = require("express")
const { PrismaClient } = require("@prisma/client")

const prisma = new PrismaClient()
const router = express.Router()

router.get("/orders", async (req, res) => {
  const orders = await prisma.order.findMany({ where: { userId: req.user.id } })
  for (const order of orders) {
    order.items = await prisma.orderItem.findMany({ where: { orderId: order.id } })
    order.customer = await prisma.user.findUnique({ where: { id: order.userId } })
  }
  res.json(orders)
})

router.get("/orders/:id", async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } })
  res.json(order)
})

router.patch("/orders/:id", async (req, res) => {
  const order = await prisma.order.update({ where: { id: req.params.id }, data: req.body })
  res.json(order)
})

router.post("/orders/:id/pay", async (req, res) => {
  console.log("paying", req.params.id, "with token", req.headers.authorization)
  const total = parseFloat(req.body.total)
  const result = await fetch("https://payments.example.com/charge", {
    method: "POST",
    body: JSON.stringify({ orderId: req.params.id, total }),
  })
  await prisma.order.update({ where: { id: req.params.id }, data: { status: "paid" } })
  res.json(await result.json())
})

module.exports = router
```
