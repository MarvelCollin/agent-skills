import { randomUUID } from "crypto"
import { NextResponse } from "next/server"
import { z } from "zod"
import { fileTypeFromBuffer } from "file-type"
import { createClient } from "@/lib/supabase"
import { requireUser } from "@/lib/auth"

const MAX_FILE_SIZE = 5 * 1024 * 1024
const ALLOWED_TYPES = ["image/png", "image/jpeg", "application/pdf"]
const UploadInput = z.object({ file: z.instanceof(File) })

export async function POST(request: Request) {
  const user = await requireUser()
  const form = await request.formData()
  const input = UploadInput.safeParse({ file: form.get("file") })
  if (!input.success || input.data.file.size > MAX_FILE_SIZE) {
    return NextResponse.json({ error: "Files must be under 5 MB" }, { status: 413 })
  }
  const bytes = Buffer.from(await input.data.file.arrayBuffer())
  const type = await fileTypeFromBuffer(bytes)
  if (!type || !ALLOWED_TYPES.includes(type.mime)) {
    return NextResponse.json({ error: "Only PNG, JPEG or PDF files" }, { status: 415 })
  }
  const supabase = createClient()
  const path = `${user.id}/${randomUUID()}.${type.ext}`
  await supabase.storage.from("attachments").upload(path, bytes, { contentType: type.mime })
  const { data } = await supabase.storage.from("attachments").createSignedUrl(path, 300)
  return NextResponse.json({ url: data?.signedUrl })
}
