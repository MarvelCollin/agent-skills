import { NextResponse, type NextRequest } from "next/server"
import { createServerClient } from "@supabase/ssr"

const PUBLIC_PATHS = ["/", "/pricing", "/contact", "/contact/thank-you", "/privacy", "/terms", "/login"]

export async function middleware(request: NextRequest) {
  const response = NextResponse.next()
  const supabase = createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll: (list) => list.forEach(({ name, value, options }) => response.cookies.set(name, value, { ...options, httpOnly: true, secure: true, sameSite: "lax" }))
    }
  })
  const { data } = await supabase.auth.getUser()
  const path = request.nextUrl.pathname
  if (!data.user && !PUBLIC_PATHS.includes(path) && !path.startsWith("/api/contact")) {
    return NextResponse.redirect(new URL("/login", request.url))
  }
  return response
}

export const config = { matcher: ["/((?!_next/static|_next/image|favicon.ico|icon.svg|apple-icon.png).*)"] }
