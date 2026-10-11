import { NextResponse } from "next/server"
import { z } from "zod"
import { createClient } from "@/lib/supabase"
import { requireUser } from "@/lib/auth"
import { ratelimit } from "@/lib/ratelimit"

const OrderInput = z.object({ planId: z.string().uuid(), seats: z.number().int().min(1).max(500) })

export async function POST(request: Request) {
  const user = await requireUser()
  const { success } = await ratelimit.limit(user.id)
  if (!success) return NextResponse.json({ error: "Too many requests" }, { status: 429 })
  const input = OrderInput.safeParse(await request.json())
  if (!input.success) return NextResponse.json({ error: "Invalid order" }, { status: 400 })
  const supabase = createClient()
  const { data: plan } = await supabase.from("plans").select("id, seat_price").eq("id", input.data.planId).single()
  if (!plan) return NextResponse.json({ error: "Unknown plan" }, { status: 404 })
  const { data: order } = await supabase
    .from("orders")
    .insert({ user_id: user.id, plan_id: plan.id, seats: input.data.seats, total_cents: plan.seat_price * input.data.seats })
    .select("id, seats, total_cents, created_at")
    .single()
  return NextResponse.json(order, { status: 201 })
}
