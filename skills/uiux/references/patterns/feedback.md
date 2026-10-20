# Feedback and System Status

How the product tells users what is happening: loading, saving, success, warnings, errors and notifications. Users should never wonder whether something worked.

## Response Times

| Wait | What the user sees |
|------|--------------------|
| Under 100ms | The result. The pressed state shows on the first frame |
| 100ms to 1s | The result, with the control in a busy state. No spinner flash (show one only after about 400ms) |
| 1s to 10s | A skeleton for page or panel content, a spinner for a small module or a button ("Saving") |
| Over 10s | A determinate progress bar with what is happening, an estimate, and a way to leave or cancel. Let the work continue in the background and notify when done |

- Skeletons only for loading content in a known layout. Spinners for small regions and actions. Progress bars for uploads, imports, exports and long jobs
- Optimistic updates for small, safe writes (toggle, rename, reorder): update at once, roll back with a message if the server rejects it
- Keep previous content visible and dimmed while refreshing it. Never blank the screen for a refetch

## Pick the Message Surface

| Surface | Use for | Behavior |
|---------|---------|----------|
| Inline next to the element | Field errors, a row that failed, a section that could not load | Stays until resolved |
| Inline save status | "Saving", "Saved", "Could not save" next to the edited area | Updates in place |
| Toast | Confirming an action the user just took ("Invoice sent"), with Undo when possible | Bottom or top corner, no more than 2 lines. Without an action it hides after about 5 to 6 seconds and pauses on hover and focus. With an action it stays at least 10 seconds or until dismissed. Never the only place an error appears |
| Banner under the page header | A condition on this page or workspace ("This class is archived", "Trial ends in 3 days") | Stays until resolved or dismissed. One at a time. Not sticky over content |
| App level banner | System wide issues (outage, maintenance, offline) | Top of the app, one at a time |
| Modal | A critical problem that blocks continuing and needs a decision | Rare |
| Badge or count | Something waiting for attention elsewhere (unread items) | Quiet, numeric, cleared when seen |

- Toasts are announced with an `aria-live` region (`polite` for success, `assertive` only for urgent errors). Focus does not move to a toast
- Stack at most 3 toasts. Newer on top, older ones collapse
- Success messages name what happened. "Saved" is fine next to a field, but a toast says "Ana Putri added to Class 7B"

## Error Messages

- Say what happened, why if known, and what to do next, in plain words
- Put the error where the problem is (a field, a row, a panel), not in a generic toast
- Keep the user's work. Offer Retry. Offer a way to contact support with a reference code for unexpected errors
- Never show raw codes, stack traces or "Something went wrong" alone. A code can follow the human message: "We could not load invoices. Try again. (Ref 4F2A)"
- Distinguish: the user's input (fix it), permission (ask someone), the network (retry), the system (we are on it)

## Long Running Work

- Start the job, confirm it started ("Import started, we will notify you"), let the user keep working
- Show progress where the user will look (the list's header, a jobs panel)
- Notify when done with a link to the result and a summary ("1,180 imported, 20 skipped, view report")

## Notification Center

- A bell in the top bar with an unread count. Opens a panel with the newest first, unread marked by a dot and heavier title
- Each item: who, what, which object, when, and a link to the object. Opening marks it read
- Group related items ("5 new comments on Essay 3") instead of one per event
- Filters for "All", "Unread", and "Mentions" or "Assigned to me". "Mark all as read". Mark as unread per item
- A link to notification preferences (per type and per channel, see [settings-account.md](settings-account.md))
- Empty state: "You're all caught up"

## Offline and Connection

- Detect offline and show an app level banner. Queue safe writes and say so, or block actions that need the server with a clear reason
- On reconnect, sync and confirm. Never silently drop a change

## Check

1. Throttle the network to Slow 3G. Do pages show skeletons, buttons show busy states, and nothing goes blank?
2. Make a request fail. Is the error next to the problem, with retry and the user's input kept?
3. Are toasts announced and do they pause on hover?
4. Does every long job confirm start, show progress and notify at the end?

## Sources

- [Response Time Limits, NN/g](https://www.nngroup.com/articles/response-times-3-important-limits/)
- [Skeleton Screens 101, NN/g](https://www.nngroup.com/articles/skeleton-screens/)
- [Progress Indicators, NN/g](https://www.nngroup.com/articles/progress-indicators/)
- [Indicators, Validations and Notifications, NN/g](https://www.nngroup.com/articles/indicators-validations-notifications/)
- [Error Message Guidelines, NN/g](https://www.nngroup.com/articles/error-message-guidelines/)
- [Notification pattern, Carbon Design System](https://carbondesignsystem.com/patterns/notification-pattern/)
- [Notification center best practices, Courier](https://www.courier.com/guides/how-to-build-a-notification-center/chapter-3-best-practices-for-notification-centers)
