import { useEffect, useState } from "react"
import { getSettings, saveSettings } from "../api"

export default function Settings() {
  const [form, setForm] = useState({ schoolName: "", termStart: "", emailNotifications: false })
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    getSettings().then(setForm)
  }, [])

  async function submit(e) {
    e.preventDefault()
    try {
      await saveSettings(form)
      setSaved(true)
    } catch (error) {
      alert("Something went wrong")
    }
  }

  return (
    <div className="page">
      <h2>Settings</h2>
      <form onSubmit={submit}>
        <input placeholder="School name" value={form.schoolName} onChange={(e) => setForm({ ...form, schoolName: e.target.value })} />
        <input type="date" value={form.termStart} onChange={(e) => setForm({ ...form, termStart: e.target.value })} />
        <label><input type="checkbox" checked={form.emailNotifications} onChange={(e) => setForm({ ...form, emailNotifications: e.target.checked })} /> Email notifications</label>
        <button className="btn">Submit</button>
      </form>
      {saved && (
        <div className="modal" style={{ width: 600, height: 400 }}>
          <p>Settings saved; you can close this.</p>
          <button className="btn" onClick={() => setSaved(false)}>OK</button>
        </div>
      )}
    </div>
  )
}
