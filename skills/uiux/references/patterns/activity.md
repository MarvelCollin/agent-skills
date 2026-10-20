# Activity, Comments and Audit Log

Who did what and when. Activity feeds help teams follow work. Audit logs help admins investigate.

## Activity Feed (on a record or a project)

- Newest first, grouped by day ("Today", "Yesterday", "12 Oct")
- Each entry: actor with avatar (R11), a plain sentence ("Ana changed the due date from 12 Oct to 15 Oct"), the object linked, and the time (relative for recent, exact on hover, see [content-format.md](content-format.md))
- Merge bursts from the same actor on the same object ("Ana edited 5 fields")
- System and automated actions are labelled as such ("Automation", "API")
- Filter by type (comments, changes, files) when the feed is long. Load older entries with "Show older" or pagination
- New entries appear without moving what the user is reading. A "3 new updates" marker brings them in

## Comments

- The input stays reachable (top of the feed or pinned at the bottom), grows with text, supports mentions with a people picker, and keeps a draft
- Enter adds a new line and Ctrl Enter or ⌘ Enter sends, or the reverse when the product already chose it. Show the hint
- Each comment: author, time, edited marker, reply, and edit or delete for the author. Deleting a comment confirms or offers Undo
- Mentions notify the person and link back to the exact comment

## Audit Log (admin)

- A filterable table: time (exact, with timezone), actor (user, API key or system), action, target object, result, IP or location
- Filters for actor, action type, object, date range and result, kept in the URL. Export of the filtered set
- Entries are read only. Clicking one shows the full detail, including before and after values for changes
- Retention period stated on the page

## Version History (documents, configurations)

- A list of versions with author and time, a readable diff of what changed, and "Restore this version" that creates a new version rather than deleting history

## Check

1. Can a user answer "who changed this and when" in one click from the record?
2. Can an admin filter the audit log to one person and one week, and export it?
3. Do new feed entries arrive without shifting what is on screen?

## Sources

- [Audit log guide, EnterpriseReady](https://www.enterpriseready.io/features/audit-log/)
- [Activity feed pattern, uxpatterns.dev](https://uxpatterns.dev/patterns/social/activity-feed)
- [Designing an Activity Feed for B2B SaaS, Wolf Tech](https://wolf-tech.io/blog/designing-an-activity-feed-for-b2b-saas-events-aggregation-and-privacy-safe-logging)
