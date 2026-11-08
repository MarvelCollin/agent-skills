# All Mode

`/uiux all [path]` redesigns the whole frontend, or only the folder in `path`, so every screen and component follows R1 to R20 and the pattern files. The user asked for everything, so the scope rule in Build Mode step 1 is lifted: existing layouts, colors, tokens and components are replaced where a rule asks for it. Everything else in Build Mode still applies.

## What Changes and What Stays

| Changes | Stays |
|---------|-------|
| Palette, type, spacing, radius, elevation and motion tokens | Routes and URLs |
| Shared UI components (field, button, dialog, table, select, date picker, tabs, scroll area, toast, empty state) | Data fetching, API calls, request and response shapes |
| App shell and navigation | Business logic, validation rules, permissions |
| Layout, hierarchy and copy of every screen | Every feature and every field the user can see today |
| File layering where R13 asks for it | Tests, analytics events, test ids and accessible names they rely on |
| Every state: loading, empty, error, success | Logos, brand assets and legal text |

Nothing the user can do today disappears. A redesign that drops a feature, a field or a filter is a regression, not a cleanup. Copy is rewritten only where a rule asks for it (R9, R15, R20), never its facts.

The palette is replaced with a new one from the picker, unless the user named colors in the arguments or the project's colors come from a brand guide the user points to. Then keep those and still meet the contrast rules.

## Before Changing Anything

1. **Safety net.** Run `git status`. If the working tree has uncommitted changes, stop and ask the user to commit or stash them. Then create a branch `uiux-all-<YYYYMMDD>` and work only there. If the project is not a git repository, copy the untouched frontend (sources, styles, config, not `node_modules`) into `uiux-all-<YYYYMMDD>/original/`, say so, and continue. Never commit unless the user's own instructions say to
2. **Baseline.** Run the project's build, type check, lint and tests, and record what passes. Run the rule scan on the whole frontend and save the counts per rule. If the app runs, screenshot every route at 1440x900 and 375x812 into `uiux-all-<YYYYMMDD>/before/`
3. **Inventory.** List every route, layout, shared component and overlay, from the router config and the pages folder. For each screen note its main task, the pattern file it matches (Patterns by Screen in SKILL.md), the components it uses and its rule scan findings
4. **Plan.** Show the user, in one short message: the screen count, the new palette with its Color Hunt link, the type pairing, the tokens, the shared components to build or replace, the navigation, and the order of work. Then start without waiting, unless the user asked to approve the plan first

## Order of Work

Work from the foundation out, so each screen is built from finished parts:

1. **Tokens.** Palette from the picker checked by `palette-check` (R1), type scale and pairing, spacing, radius, elevation and motion tokens (R8, R18), in the project's token file or theme config
2. **Shared components.** One component per job (R8), built or restyled once: field and form grid (R17), buttons, custom controls and scrollbars (R7), dialog and sheet with pinned actions (R6, R14), table with search, column filters and server paging (R5, R10), status labels without pills (R4), avatar (R11), skeletons and empty states, toast, tabs
3. **App shell and navigation.** Sidebar or top bar, page header, current location, mobile pattern, sticky headers (R19, [navigation.md](navigation.md), [app-shell.md](patterns/app-shell.md))
4. **Screens.** One at a time, most used first: the dashboard or home, then the main list and detail pages, then forms, settings, auth, error pages. Each screen uses only the shared components, follows its pattern file, fits the screen (R19), and has every state
5. **Public pages.** Landing, pricing and docs get the launch ready items (R16) and lose the AI template tells (R15)
6. **Polish.** The twenty item pass in [polish.md](polish.md) across every screen (R20)

After each screen, run the build and type check. Fix what broke before the next screen. A screen is done when its rule scan findings are fixed or written down as false positives.

On a large project with the Agent tool available, steps 4 and 5 may run in parallel subagents once steps 1 to 3 are finished. Give each one a disjoint set of screens, the skill directory, the token file, the list of shared components it must use, and this file. Subagents never edit tokens or shared components. They report what they need changed and you change it once.

## Finish

1. Run the build, type check, lint and tests again. Everything that passed at the baseline passes now
2. Run the rule scan on the whole frontend. Report the counts before and after per rule. Every remaining finding is a false positive with a one line reason, or is listed under Still Open
3. Screenshot every route again into `uiux-all-<YYYYMMDD>/after/` at the same sizes and compare with the baseline. Click through every main task once to confirm nothing the user could do before is gone
4. Run the UI Review in [ui-review.md](ui-review.md) on the three most used screens, and the R20 Check list on all of them
5. Give the user a summary: the branch name, the new palette and tokens, the screens changed, the rule scan counts before and after, the test results, and Still Open. Tell them how to see it (the dev server command) and how to drop it (`git checkout <previous-branch>` and delete the branch, or restore the copy in `original/`)
