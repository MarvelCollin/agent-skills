# App Shell

The frame every SaaS screen lives in: sidebar, top bar, page header, workspace switcher, global search and command palette. The user's question here: where am I, what can I reach, and how do I get there fast? General navigation rules live in [../navigation.md](../navigation.md).

## Layout

- The shell is a fixed height layout (`height: 100dvh`, grid of sidebar, top bar and content). Only the content region scrolls (R19). The sidebar scrolls on its own only when its items overflow
- Sidebar for apps with more than about 5 areas or any hierarchy. A top bar alone for 3 to 6 flat areas. Most products combine them: top bar for global context (search, notifications, help, account), sidebar for primary navigation
- Sidebar width 240 to 280px expanded, 56 to 64px collapsed. Collapse is a user choice that is remembered, never automatic on desktop. Collapsed items show a tooltip with the label on hover and focus
- Under 1024px the sidebar becomes an overlay drawer opened from a visible "Menu" button. Under 640px use a bottom tab bar for up to 5 main areas plus "More"

## Sidebar Content

- Top: workspace or organization switcher showing the current workspace's name and logo
- Middle: primary areas ordered by frequency of use, each with an icon and a text label. Group with small section headings when there are more than about 7. Labels use the user's words, not internal feature names
- Bottom: settings, help, and the account menu (avatar, name, sign out). Always the same place
- Active item: filled or tinted background plus weight or a marker bar plus `aria-current="page"`. Never color alone
- Counts that need action ("Inbox 3") sit at the right of the item. No counts for things that do not need action
- Items the user's role cannot use are hidden from navigation. Inside a page, a disabled action explains why (see [overlays.md](overlays.md))

## Workspace Switcher

- Always shows which workspace is active, on every screen
- Opens a list with search when the user has more than about 7 workspaces, the current one checked, recent ones first, plus "Create workspace" and "Join workspace" at the end
- Users with one workspace still see its name, without a dropdown chevron
- After switching, land on the same area in the new workspace (or its home if that page does not exist there), never on a page that still shows the old workspace's data. The URL contains the workspace slug so links never act on the wrong one
- Switching workspace is separate from account settings and sign out

## Page Header

Every app page opens with the same header, sticky when the content scrolls (R19):

- Breadcrumbs when the page is two or more levels deep
- The page title (h1), matching the navigation label. On a list page, the total count next to it ("Students 1,240")
- One primary action on the right ("New student"). Secondary actions as buttons next to it, rarely used ones in a "More" menu
- Tabs under the title when the page has sections (see [detail-pages.md](detail-pages.md))
- The same height, padding and button size on every page

## Global Search and Command Palette

- A visible search field or button in the top bar showing its shortcut (`Ctrl K` or `⌘ K`). Not hidden behind a setting
- The palette opens instantly, focuses the input, shows recent items and common actions before typing, then searches records, pages and commands together, grouped by type with clear group labels
- Each command shows its keyboard shortcut on the right, so users learn shortcuts by using the palette
- Arrow keys move, Enter runs, Escape closes and returns focus to where it was. Works with the APG Combobox pattern

## Keyboard Shortcuts

- Follow conventions: `Ctrl K` or `⌘ K` palette, `/` focus search, `?` shortcut list, `Esc` close, `G` then a letter to go to an area, `J` and `K` to move in lists, `E` to edit, `C` to create
- Never override browser or screen reader shortcuts (Ctrl S, Ctrl F, Ctrl L, arrow keys outside widgets)
- Single key shortcuts never fire while the user types in a field, and can be turned off (WCAG 2.1.4)
- Show the shortcut next to the action in menus and tooltips, and list all of them under `?`

## Avoid

- Hamburger menus on desktop
- Icon only sidebars with no way to see labels
- Mega menus in an app
- Two navigation systems that disagree (a top bar and a sidebar listing the same areas in a different order)
- Moving the account menu or settings between pages

## Check

1. From any page, can the user tell the product, the workspace and the page within 3 seconds?
2. Is the active area marked in more than color?
3. Does the sidebar collapse state survive reload? Does the drawer work at 768px and the tab bar at 375px?
4. Does `Ctrl K` open the palette, and do arrow keys, Enter and Escape work?
5. Does switching workspace keep the user oriented and update the URL?

## Sources

- [SaaS Navigation UX Patterns, saasui.design](https://www.saasui.design/blog/saas-navigation-ux-patterns)
- [Workspace and Org Switcher UX Patterns, saasui.design](https://www.saasui.design/blog/saas-workspace-organization-switcher-ux-patterns)
- [Menu Design Checklist, NN/g](https://www.nngroup.com/articles/menu-design/)
- [UI Copy: Command Names and Keyboard Shortcuts, NN/g](https://www.nngroup.com/articles/ui-copy/)
- [Character Key Shortcuts (WCAG 2.1.4)](https://www.w3.org/WAI/WCAG22/Understanding/character-key-shortcuts.html)
