# Empty, Error and Edge States

Every view has more states than the happy path. A screen is not done until each of these is designed. Generic loading and messages are in [feedback.md](feedback.md).

## The States

| State | What the user sees |
|-------|--------------------|
| Loading | A skeleton of the real layout |
| First use, nothing yet | What this space is for, the action to create the first item, and a link to learn more or import |
| No results | The query or filters, "Clear filters", and suggestions (see [search.md](search.md), [filters-sort.md](filters-sort.md)) |
| All done | Positive and calm: "No overdue assignments" or "You're all caught up" |
| Partial | The content that did load, plus an inline error for the part that failed with Retry |
| Error | What failed in plain words, Retry, and the user's work kept |
| No permission | That the user cannot see this, why, and who can grant access ("Ask a workspace admin"), with a request access button when the product supports it |
| Not found | That the item does not exist or was deleted, plus a link back to the list and search |
| Locked by plan | What the feature does, which plan includes it, and the upgrade path (see [settings-account.md](settings-account.md)) |
| Offline | An app banner, cached content where possible, and what will happen to changes |
| Too much | Very long text, many tags, a huge number: truncation, "+12 more", compact number format, nothing breaks the layout |

## Empty State Rules

- Title as a plain statement ("No students in this class yet"), one line of explanation, one primary action ("Add students"), an optional secondary ("Import from CSV")
- Use the space to teach: what will appear here and why it is useful
- A small product specific illustration or a preview of what it will look like is fine. No generic cartoon, no jokes in serious products
- The same component everywhere, sized to its container. A table's empty state sits inside the table frame, under the header, so the columns still explain the data
- First use and no results never share wording

## Error Pages

- 404 inside the app keeps the app shell and navigation, says the page was not found, and offers search and the main areas. Returns HTTP 404
- 403 keeps the shell, explains the missing permission and who to ask
- 500 and maintenance pages are calm, say it is not the user's fault, show status and when to retry, and give a reference code
- Expired session: a dialog or page to sign in again that returns to the same place with unsaved work kept

## Check

1. For each list and panel, trigger: empty, no results, error, slow, no permission. Is each designed?
2. Paste a 300 character name and 40 tags. Does the layout hold?
3. Open a deleted record's URL. Is it helpful?

## Sources

- [Designing Empty States in Complex Applications, NN/g](https://www.nngroup.com/articles/empty-state-interface-design/)
- [Empty states pattern, Carbon Design System](https://carbondesignsystem.com/patterns/empty-states-pattern/)
- [Error Message Guidelines, NN/g](https://www.nngroup.com/articles/error-message-guidelines/)
