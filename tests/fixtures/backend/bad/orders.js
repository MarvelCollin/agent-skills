const db = require('./db')

async function listOrders(req, res) {
  const orders = await prisma.order.findMany()
  for (const order of orders) {
    order.items = await db.query('SELECT * FROM items WHERE order_id = $1', [order.id])
  }
  const users = await Promise.all(orders.map((o) => fetch(`http://users/${o.userId}`)))
  console.log('orders loaded', orders.length)
  res.json(orders)
}

async function getOrder(req, res) {
  const order = await Order.findById(req.params.id)
  res.json(order)
}

async function updateProfile(req, res) {
  const user = await prisma.user.update({ where: { id: req.user.id }, data: req.body })
  const role = req.body.role
  res.json({ user, role })
}

async function charge(req, res) {
  try {
    const amount = parseFloat(req.body.amount)
    await pay(amount)
  } catch (e) {}
  logger.info('charged with token', req.headers.authorization)
  const page = await db.query('SELECT id FROM orders ORDER BY id OFFSET $1', [req.query.offset])
  const cfg = fs.readFileSync('config.json')
  const secret = process.env.JWT_SECRET || 'dev-secret'
  res.status(500).json(err)
}

async function legacy() {
  try {
    await work()
  } catch (err) {
  }
}

const stripeKey = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY
const nextConfig = { productionBrowserSourceMaps: true }
function showConfig(req, res) { res.json(process.env) }
localStorage.setItem('access_token', token)
function checkout(req) { return { total: req.body.total, role: req.headers['x-user-role'] } }
const claims = jwt.decode(req.headers.authorization)
res.cookie('sid', sessionId)
