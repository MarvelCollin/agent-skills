import type { MetadataRoute } from "next"

export default function sitemap(): MetadataRoute.Sitemap {
  const base = "https://tidepool.studio"
  return ["", "/pricing", "/contact", "/privacy", "/terms"].map((path) => ({ url: base + path, lastModified: new Date("2026-09-01") }))
}
