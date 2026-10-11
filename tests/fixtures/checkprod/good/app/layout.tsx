import type { Metadata } from "next"
import { Analytics } from "@vercel/analytics/react"
import Footer from "@/components/Footer"
import "./globals.css"

export const metadata: Metadata = {
  metadataBase: new URL("https://tidepool.studio"),
  title: { default: "Tidepool", template: "%s | Tidepool" },
  description: "Tidepool turns customer calls into searchable notes for small support teams.",
  openGraph: {
    title: "Tidepool",
    description: "Turn customer calls into searchable notes.",
    images: [{ url: "/opengraph-image.png", width: 1200, height: 630 }]
  },
  twitter: { card: "summary_large_image" }
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Footer />
        <Analytics />
      </body>
    </html>
  )
}
