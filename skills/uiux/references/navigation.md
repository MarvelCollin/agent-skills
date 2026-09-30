# Navigation

How to design navigation when building, and what to check when auditing. A user who lands on any page, from any link, should be able to answer three questions in a few seconds: Where am I? What is here? Where can I go next?

## Show Where the User Is

- The logo or product name sits in the same corner on every page and links home
- The current section is clearly marked in the navigation. Use more than a color change: weight, a marker bar, an underline or a filled background, plus `aria-current="page"` on the link. The most common navigation mistake is a location cue too subtle to notice
- The page title (h1) matches the navigation label the user clicked
- Pages deeper than two levels get breadcrumbs (see below)
- Multi-step flows show the step number, the total and the step names

## Keep Navigation Visible

- On desktop, show the main navigation. Do not hide it behind a hamburger or any single menu button, because hidden navigation roughly halves discoverability and slows tasks
- On mobile, use a persistent tab bar for up to 5 top-level destinations. With more than 5, use a menu, but keep the 2 or 3 most important tasks visible on the page as well
- Make a mobile menu button look like a button: an outline or filled shape plus the word "Menu"
- Navigation links must stand out clearly from the background (see [color.md](color.md))

## Labels and Structure

- Use the words users use, not internal or clever names. A label should predict what is behind it
- Order items by importance and frequency of use, and keep that order on every page
- Group related items. Keep top-level items to about 7 or fewer so the menu can be scanned at a glance
- Put all items of a menu at the same level of the hierarchy
- Every link and button leads somewhere the label promised. Strong information scent matters more than click count

## Local Navigation

When users move between sibling pages in one section (comparing items, working through related settings), show those siblings in a local navigation list next to the content. That way they do not have to go back up the hierarchy after every page.

## Breadcrumbs

- Place them at the top of the content, below the global navigation
- They show the page's place in the hierarchy, not the user's history
- Start at the root, link every level except the current page, and use `>` or `/` as separators
- They add to the main navigation, never replace it
- On desktop, show the full trail. On mobile, a link to the parent page is enough

## Menus and Dropdowns

- Open submenus on click, or on hover with a short delay. They stay open while the pointer travels to them
- Do not cover the whole screen with a mega menu on large displays
- Menus work fully by keyboard: arrow keys move, Enter or Space opens, Escape closes and returns focus to the trigger
- Show a submenu indicator (an arrow or chevron) on items that open more options

## Back, Forward and Deep Links

- The browser back button always goes to the previous view. Tabs, filters, pagination and opened panels that users think of as places update the URL
- Every meaningful view has a shareable URL that restores it, including table filters (R5 in [build-rules.md](build-rules.md))
- After a form submit or delete, land users somewhere sensible and tell them what happened

## Search

- Show a search field, not just an icon, when search is a main way in. Keep it in the same place on every page
- Results show the query, the count and a way to refine it. A "no results" page suggests next steps

## Footer

Use the footer for secondary navigation: contact, help, legal and the sitemap. It is the fallback for users who scrolled to the end, not a replacement for the main navigation.

## Checks

For every page tested:
1. Can I tell which site this is and which page I am on within 5 seconds?
2. Is my current location marked in the navigation, in more than color?
3. Can I reach the main tasks without hunting? Count the clicks and note where the label did not predict the destination
4. Does the back button do what I expect after filters, tabs and dialogs?
5. On mobile, can I see the main destinations without opening a menu?
6. Does the navigation work with the keyboard alone?

## Sources

- [Navigation: You Are Here, NN/g](https://www.nngroup.com/articles/navigation-you-are-here/)
- [Menu-Design Checklist: 17 UX Guidelines, NN/g](https://www.nngroup.com/articles/menu-design/)
- [Breadcrumbs: 11 Design Guidelines for Desktop and Mobile, NN/g](https://www.nngroup.com/articles/breadcrumbs/)
- [Local Navigation Is a Valuable Orientation and Wayfinding Aid, NN/g](https://www.nngroup.com/articles/local-navigation/)
- [Basic Patterns for Mobile Navigation, NN/g](https://www.nngroup.com/articles/mobile-navigation-patterns/)
- [Hamburger Menus and Hidden Navigation Hurt UX Metrics, NN/g](https://www.nngroup.com/articles/hamburger-menus/)
