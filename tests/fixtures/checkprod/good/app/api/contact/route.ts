import { NextResponse } from "next/server"
import { z } from "zod"
import { ratelimit } from "@/lib/ratelimit"

const ContactInput = z.object({ email: z.string().email(), message: z.string().min(1).max(2000) })

export async function POST(request: Request) {
  const ip = request.headers.get("x-forwarded-for") ?? "unknown"
  const { success } = await ratelimit.limit(ip)
  if (!success) return NextResponse.json({ error: "Too many requests" }, { status: 429 })
  const form = await request.formData()
  const input = ContactInput.safeParse({ email: form.get("email"), message: form.get("message") })
  if (!input.success) return NextResponse.json({ error: "Enter a valid work email" }, { status: 400 })
  return NextResponse.json({ ok: true })
}
