import type { Order } from './OrderCard.types'

export async function getOrder(id: string): Promise<Order> {
  const response = await fetch(`/api/orders/${id}`, { signal: AbortSignal.timeout(5000) })
  return response.json()
}
