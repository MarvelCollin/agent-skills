export async function askCoach(question) {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${import.meta.env.VITE_OPENAI_API_KEY}`
    },
    body: JSON.stringify({ model: "gpt-4o-mini", messages: [{ role: "user", content: question }] })
  })
  const data = await response.json()
  return data.choices[0].message.content
}
