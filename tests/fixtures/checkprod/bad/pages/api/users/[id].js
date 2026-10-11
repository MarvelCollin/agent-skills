import { createClient } from "@supabase/supabase-js"

const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY)

export default async function handler(req, res) {
  const user = await findById(req.query.id)
  res.json(user)
}

async function findById(id) {
  const { data } = await supabase.from("users").select("*").eq("id", id).single()
  return data
}
