# Upload, Import and Export

Getting files and data into and out of the product.

## File Upload

- A drop zone plus a visible "Choose files" button (R7). Drag and drop is never the only way. On touch screens it is a large button
- Rules next to the control before selection: "PDF or DOCX, up to 10 MB each, at most 5 files"
- Validate type and size the moment files are chosen, per file, with the file name in the message
- Each file is a row: icon or thumbnail, name, size, progress, status (queued, uploading, processing, done, failed), and actions (cancel, retry, remove)
- Uploading and server processing are separate states. A full progress bar is not "done" until processing finishes
- A stalled or failed upload says so with the reason and Retry. Never a bar stuck at 50%
- Uploads continue while the user fills the rest of the form. Submitting waits for them or says how many are still uploading
- One upload area per screen

## Import (CSV, Excel)

A staged flow, each step with its own screen and the ability to go back:

1. **Upload** with a downloadable template and the expected columns listed
2. **Map columns**: each file column matched to a field, auto matched by header name with the match shown, editable with a select, required fields marked, unmapped columns ignored visibly. Remember mappings for the next import
3. **Review**: a preview of the first rows as they will be saved, a summary ("1,200 rows, 1,180 ready, 20 with problems"), problems listed by row and column with the reason, split into blocking errors and warnings, fixable in place or downloadable as an error file
4. **Import** in the background with progress, then a result summary with links to the created records and to skipped rows

- Choose what to do with duplicates (skip, update, create new) before importing
- Never write anything before the user confirms the review

## Export

- Export what the user sees: the current filters, sort and visible columns, with an option for all columns
- Format choice where useful (CSV, Excel, PDF). File names include the object and date (`students-7b-2026-10-20.csv`)
- Small exports download at once. Large ones run in the background and notify with a download link that expires and says when
- Exports respect permissions and never include fields the user cannot see

## Check

1. Upload a wrong type, an oversized file and a good one together. Is each handled per file?
2. Import a file with misnamed columns and bad rows. Can the user map, see every problem and fix or skip before saving?
3. Does export match the filtered view?

## Sources

- [File upload, Base design system (Uber)](https://base.uber.com/6d2425e9f/p/5555b5-file-upload/b/978665)
- [File input pattern, uxpatterns.dev](https://uxpatterns.dev/patterns/forms/file-input)
- [Designing Scalable CSV Importers, mfyz](https://mfyz.com/designing-scalable-csv-importers-what-a-good-importer-should-do/)
- [Progress Indicators, NN/g](https://www.nngroup.com/articles/progress-indicators/)
