import { useEffect, useState } from 'react'
import { getOrder } from './orders.api'
import type { Order } from './OrderCard.types'

export function useOrder(orderId: string) {
  const [order, setOrder] = useState<Order | null>(null)
  useEffect(() => {
    getOrder(orderId).then(setOrder)
  }, [orderId])
  return order
}
