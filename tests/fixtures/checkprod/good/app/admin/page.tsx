import { requireAdmin } from "@/lib/auth"

export const metadata = {
  title: "Admin",
  description: "Team and billing settings."
}

export default async function AdminPage() {
  const admin = await requireAdmin()
  return (
    <main className="px-4 py-8">
      <h1>Admin</h1>
      <p>Signed in as {admin.email}</p>
    </main>
  )
}
