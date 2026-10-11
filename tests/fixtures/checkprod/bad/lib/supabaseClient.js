import { createClient } from "@supabase/supabase-js"

export const supabase = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)

export async function uploadAvatar(userId, file) {
  await supabase.storage.from("avatars").upload(`${userId}/${file.name}`, file)
  return supabase.storage.from("avatars").getPublicUrl(`${userId}/${file.name}`).data.publicUrl
}
