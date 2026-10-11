import formidable from "formidable"
import fs from "fs"
import path from "path"

export const config = { api: { bodyParser: false } }

export default async function handler(req, res) {
  const form = formidable({})
  const [, files] = await form.parse(req)
  const file = files.file[0]
  fs.copyFileSync(file.filepath, path.join(process.cwd(), "public/uploads", file.originalFilename))
  res.json({ url: "/uploads/" + file.originalFilename })
}
