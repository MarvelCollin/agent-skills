# Dashboards and Home Screens

The first screen after sign in. Its job: show what needs the user's attention now and get them to it in one click. It is not a place to show every chart the product can draw. Chart craft follows the dataviz skill if available, and these rules.

## Decide the Type

| Type | Question it answers | Shape |
|------|---------------------|-------|
| Operational | What needs action right now? | A work queue first (overdue, assigned to me, waiting for review), then status. Updates live |
| Analytical | How are we doing and why? | A few trend charts with a shared date range and comparisons, drill down into lists |
| Home | Where do I continue? | Recent items, my tasks, shortcuts to the main areas, setup checklist for new accounts |

Pick one per screen. Mixing all three is how dashboards become walls of cards (slop L01).

## Layout

- Fits 1366x768 without scrolling for the top priority content (R19). Things that need action go top left
- Group by question, not by chart type. Each group has a heading that states the question
- No decorative icons on metrics (R2). A metric is a label, a number, and a comparison

## Metrics

- Every number has context: the period, a comparison ("+12% vs last month"), and whether that is good (color plus an arrow or word, never color alone)
- Every number is a link to the filtered list behind it ("23 overdue" opens overdue assignments)
- Units and formats follow [content-format.md](content-format.md). Large numbers compact ("12.4k") with the exact value on hover
- Show when data was last updated

## Charts

- Bar charts for comparing categories, line charts for trends over time. Avoid pie, donut, area and treemap for comparisons, because people judge length and position far better than area or angle
- Start bar axes at zero. Label directly instead of legends where possible. At most about 5 series
- Hover and focus show exact values. Charts have a text alternative (a summary or a data table toggle)
- One global date range control with presets (Today, Last 7 days, Last 30 days, This quarter, Custom) that every widget follows, stored in the URL
- Highlight color only for what needs attention (a threshold crossed). Everything else neutral

## Loading and Empty

- Each widget loads on its own with a skeleton, so one slow query does not block the page
- New accounts see a setup checklist and example previews, not empty charts with zeros

## Customization

- Optional: users can hide, reorder and pin widgets, remembered per user. Defaults must be good without it

## Check

1. In 5 seconds, can the user tell what needs attention?
2. Does every number click through to the list behind it?
3. Does every metric have a period and a comparison?
4. Does the date range apply to every widget and survive reload?

## Sources

- [Dashboards: Making Charts and Graphs Easier to Understand, NN/g](https://www.nngroup.com/articles/dashboards-preattentive/)
- [8 Design Guidelines for Complex Applications, NN/g](https://www.nngroup.com/articles/complex-application-design/)
- [Dashboard Design Patterns, Bach et al.](https://arxiv.org/abs/2205.00757)
