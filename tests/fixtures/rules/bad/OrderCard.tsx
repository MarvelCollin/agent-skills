import { useEffect, useState } from 'react'

export interface Order {
  id: string
  total: number
}

type Props = { orderId: string }

export function OrderCard({ orderId }: Props) {
  const [order, setOrder] = useState<Order | null>(null)
  useEffect(() => {
    fetch(`/api/orders/${orderId}`).then((r) => r.json()).then(setOrder)
  }, [orderId])
  return <article>{order?.id}</article>
}
