import ContactForm from "@/components/ContactForm"

export const metadata = {
  title: "Contact",
  description: "Book a demo or ask a question. We reply within one working day."
}

export default function ContactPage() {
  return (
    <main className="mx-auto max-w-xl px-4 py-16">
      <h1>Book a demo</h1>
      <ContactForm />
    </main>
  )
}
