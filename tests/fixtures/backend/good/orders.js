const { z } = require('zod')
const logger = require('./logger')

const ListQuery = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(20),
  cursor: z.string().optional(),
})

async function listOrders(req, res) {
  const { limit, cursor } = ListQuery.parse(req.query)
  const orders = await prisma.order.findMany({
    where: { userId: req.user.id },
    include: { items: true },
    take: limit + 1,
    ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    orderBy: { id: 'desc' },
  })
  logger.info({ count: orders.length }, 'orders listed')
  res.json(orders.slice(0, limit))
}

async function getOrder(req, res) {
  const order = await prisma.order.findFirst({ where: { id: req.params.id, userId: req.user.id } })
  const rates = await fetch(RATES_URL, { signal: AbortSignal.timeout(2000) })
  res.json({ order, rates: await rates.json() })
}

const mapsKey = process.env.NEXT_PUBLIC_MAPS_API_KEY
const claims = jwt.verify(token, publicKey, { algorithms: ['RS256'] })
const decoded = jwt.decode(token, publicKey, { algorithms: ['RS256'] })
res.cookie('sid', sessionId, { httpOnly: true, secure: true, sameSite: 'lax' })
