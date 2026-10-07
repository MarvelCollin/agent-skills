import type { OrderCardProps } from './OrderCard.types'
import { useOrder } from './useOrder'

export function OrderCard({ orderId }: OrderCardProps) {
  const order = useOrder(orderId)
  if (!order) return null
  return <article>{order.id}</article>
}
