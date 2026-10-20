# Words, Numbers and Dates

How text and values look across the product. Consistency here makes an app feel trustworthy. All copy follows R9: no semicolons, no em dashes.

## Labels and Microcopy

- Use the user's words, the same word for the same thing everywhere. If it is a "class" on one screen, it is never a "group" on another
- Buttons start with a verb and name the object when it is not obvious: "Create invoice", "Invite members", "Save changes". Never "Submit", "OK" or "Click here"
- Links predict where they go: "View all 48 assignments", not "Learn more" or "See more"
- Sentence case for titles, buttons, labels and menu items
- Headings and labels front load the keyword ("Email notifications", not "Do you want to receive emails")
- Write for scanning: short sentences, one idea each, numbers as digits

## Numbers

- Locale aware formatting through `Intl.NumberFormat` with the user's locale (for Indonesian: `1.250.000`, decimals with a comma)
- Currency with its symbol or code in the user's convention (`Rp 1.250.000`, `$1,250.00`) and a consistent number of decimals per currency
- Right align numbers in tables with `font-variant-numeric: tabular-nums` so digits line up
- Compact large numbers in dashboards (`12,4 rb`, `12.4k`) with the exact value on hover. Never compact in tables where users compare
- Percentages with the same decimals across a view. Show the sign for changes (`+12%`, `−3%`)
- Units after the number with a space (`8.2 GB`, `45 min`)

## Dates and Times

- Format with `Intl.DateTimeFormat` in the user's locale and timezone. Unambiguous month names in the UI (`20 Okt 2026`, `Oct 20, 2026`), never `10/11/12`
- Relative time for recent events in feeds and "last updated" ("5 min ago", "Yesterday"), switching to the date after about a week. The exact date, time and timezone in a tooltip and a `time` element with `datetime`
- Absolute dates in tables, due dates, invoices, audit logs and anything legal
- Show the timezone when users are in several, and store everything in UTC
- Date ranges as "12 to 18 Oct 2026", not two full dates
- Durations in words ("2 h 15 min"), not `02:15:00`, unless it is a timer

## Names and Identifiers

- People by display name with avatar (R11). Email shown where it disambiguates
- IDs in a monospace font with a copy button when users need to share them
- Truncate long names in the middle when the end matters (file names, IDs: `report-fin…2026.pdf`), at the end otherwise, and show the full value on hover

## Empty and Unknown Values

- "Not set" or "None" in muted text for empty fields, "Unknown" when the system cannot know. Never a blank cell, never a lone dash

## Check

1. Pick one concept (a student, an invoice). Is it named the same on every screen?
2. Do numbers and dates follow the user's locale everywhere?
3. Do all buttons start with a verb?

## Sources

- [Writing Hyperlinks, NN/g](https://www.nngroup.com/articles/writing-links/)
- [Learn More Links: You Can Do Better, NN/g](https://www.nngroup.com/articles/learn-more-links/)
- [Timestamps pattern, Cloudscape](https://cloudscape.design/patterns/general/timestamps/)
- [Date and time, GitLab Pajamas](https://design.gitlab.com/content/date-and-time)
- [Numerics, PatternFly](https://www.patternfly.org/ux-writing/numerics/)
