import { cookies } from "next/headers"
import { createServerClient } from "@supabase/ssr"

export function createClient() {
  const store = cookies()
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => store.getAll(),
      setAll: (list) => list.forEach(({ name, value, options }) => store.set(name, value, { ...options, httpOnly: true, secure: true, sameSite: "lax" }))
    }
  })
}
