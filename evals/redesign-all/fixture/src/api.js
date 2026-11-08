const BASE = "/api"

async function request(path, options) {
  const response = await fetch(`${BASE}${path}`, { headers: { "Content-Type": "application/json" }, ...options })
  if (!response.ok) throw new Error(`Request failed with ${response.status}`)
  return response.json()
}

export function getStats() {
  return request("/stats")
}

export function getStudents({ page, pageSize, q, role }) {
  const params = new URLSearchParams({ page, pageSize, q, role })
  return request(`/students?${params}`)
}

export function getStudent(id) {
  return request(`/students/${id}`)
}

export function deleteStudent(id) {
  return request(`/students/${id}`, { method: "DELETE" })
}

export function getSettings() {
  return request("/settings")
}

export function saveSettings(settings) {
  return request("/settings", { method: "PUT", body: JSON.stringify(settings) })
}
