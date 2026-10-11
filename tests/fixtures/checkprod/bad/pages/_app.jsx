import Script from "next/script"
import "../styles/globals.css"

export default function App({ Component, pageProps }) {
  return (
    <>
      <Script src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX" strategy="afterInteractive" />
      <Script id="ga" strategy="afterInteractive">
        {`window.dataLayer = window.dataLayer || []
        function gtag(){dataLayer.push(arguments)}
        gtag("js", new Date())
        gtag("config", "G-XXXXXXXXXX")`}
      </Script>
      <Component {...pageProps} />
    </>
  )
}
