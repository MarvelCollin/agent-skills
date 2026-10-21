# items.json and boxes.json

## Folder

```
<folder>/
  items.json
  before/
    boxes.json
    <role>/NN-name.png
  after/
    boxes.json
    <role>/NN-name.png
  boxed/            written by the build, safe to delete
  <output>.docx     written by the build
```

## items.json

```json
{
  "title": "Laporan Revisi 21 Oktober 2026",
  "intro": "Hiring System, sebelum dan sesudah tiap perubahan. Kotak merah menandai bagian yang berubah. Ukuran layar 1440x900, bahasa Indonesia, login sebagai HR.",
  "lang": "id",
  "viewport": 1440,
  "output": "Laporan Revisi 21 Okt 2026.docx",
  "items": [
    {
      "title": "Daftar bagian di kiri tetap terlihat saat discroll",
      "asked": ["Daftar bagian di sisi kiri tab Detail ikut tergulir saat halaman discroll, jadi pengguna harus scroll ke atas lagi untuk pindah bagian."],
      "changed": ["Daftar bagian sekarang menempel saat halaman discroll"],
      "checked": ["Browser: tab Detail discroll 700px, daftar tetap terlihat", "Semua test FE lolos"],
      "before": "hr/01-flow-scrolled-nav.png",
      "after": "hr/01-flow-scrolled-nav.png"
    },
    {
      "title": "Pesan error langsung terlihat",
      "asked": ["Saat simpan gagal, pesan error muncul di atas halaman sementara pengguna ada di bawah, jadi pengguna tidak tahu kenapa gagal."],
      "changed": ["Halaman menggulir ke pesan error saat simpan ditolak"],
      "checked": ["Browser: simpan dari bawah halaman, pesan tampil di layar"],
      "before_note": "Sebelumnya pesan ada di atas halaman dan tidak terlihat dari tombol simpan.",
      "after": "hr/04b-error-visible.png"
    }
  ]
}
```

| Field | Required | Meaning |
|-------|----------|---------|
| `title` | yes | Document title, also the Word title property |
| `intro` | no | One paragraph under the title: product, screen size, language, account, how shots were taken |
| `lang` | no | `id` (default) or `en`, sets the labels Masalah, Diubah, Dicek, Sebelum, Sesudah or Asked, Changed, Checked, Before, After |
| `labels` | no | Override any label, for example `{"asked": "Permintaan"}` |
| `viewport` | no | CSS width of the screenshots, default 1440, used to scale boxes |
| `output` | no | File name of the docx, default `<title>.docx` |
| `items[].title` | yes | Short name of the change, what the user sees |
| `items[].asked` | no | List of problem statements behind the user's requests: what was wrong, where, and the effect on the user. Not the chat prompt itself |
| `items[].changed` | no | List of what changed |
| `items[].checked` | no | List of how it was checked |
| `items[].before`, `after` | one of the pair | Path relative to `before/` or `after/` |
| `items[].before_note`, `after_note` | when the shot is missing | Text shown in place of the picture |

## boxes.json

One file in `before/` and one in `after/`. Keys are the same relative paths used in `items.json`. Values are lists of boxes in CSS pixels of the viewport.

```json
{
  "hr/01-flow-scrolled-nav.png": [{ "x": 298, "y": 170, "w": 220, "h": 160 }],
  "hr/04-save-ok.png": [
    { "x": 640, "y": 390, "w": 731, "h": 194 },
    { "x": 1048, "y": 824, "w": 356, "h": 52 }
  ]
}
```

Get coordinates from the page itself (`element.getBoundingClientRect()` in the browser) rather than guessing from the image. Leave a few pixels of padding around the changed area.

## Script output

`build` prints `OUTPUT`, `AUTHOR`, `ITEMS`, `IMAGES`, `THUMBNAIL` and `COPIED`, plus `MISSING_IMAGE: <side>/<path>` for each picture it could not find. `INVALID:` lines and exit code 2 mean `items.json` is malformed.

`check` prints `AUTHOR`, `THUMBNAIL` and `IMAGES`, plus a `PROBLEM:` line and exit code 1 when the author is empty or python-docx, or when the thumbnail is missing.
