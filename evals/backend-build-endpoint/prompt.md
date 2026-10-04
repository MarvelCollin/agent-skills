---
tags: [backend, build]
runs: 1
max_turns: 40
timeout_seconds: 900
allowed_tools: [Skill, Read, Glob, Grep, Bash, Write, Edit]
---

Write `src/routes/orders.js` for our Express API: a GET /api/orders route that returns the signed-in user's orders with their line items and product names. Some users have thousands of orders. Our auth middleware already sets `req.user.id`, we log with pino-http, and zod is installed. This is the Prisma schema:

```prisma
model User {
  id     String  @id @default(uuid())
  email  String  @unique
  orders Order[]
}

model Order {
  id         String      @id @default(uuid())
  userId     String
  user       User        @relation(fields: [userId], references: [id])
  totalCents Int
  createdAt  DateTime    @default(now())
  items      OrderItem[]
}

model OrderItem {
  id        String  @id @default(uuid())
  orderId   String
  order     Order   @relation(fields: [orderId], references: [id])
  productId String
  product   Product @relation(fields: [productId], references: [id])
  quantity  Int
}

model Product {
  id         String      @id @default(uuid())
  name       String
  priceCents Int
  items      OrderItem[]
}
```
