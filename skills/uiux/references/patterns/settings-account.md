# Settings, Team, Billing and Account

The administrative side of a SaaS product: preferences, workspace settings, members and roles, billing, security and the danger zone.

## Settings Structure

- Separate personal settings (profile, notifications, appearance, security) from workspace settings (general, members, roles, billing, integrations, API). Label both clearly
- A local navigation list on the left with one page per group, each with its own URL. Not one endless page (R19)
- A search box when there are more than about 20 settings
- Within a page: sections with a title and one line of description, then the controls. The same two column split on every page (see [../form-layout.md](../form-layout.md))
- Labels describe the setting's effect in a few keywords ("Email notifications"), not a question
- Put settings in context too: a display option belongs next to the view it changes, and the settings page repeats it

## Saving Settings

- One save model per page, never mixed:
  - **Instant** for independent switches and choices. A switch applies on change, shows a brief "Saved", and rolls back with an error if it fails
  - **Explicit** for groups of related fields, anything affecting other people, security and money. A save bar appears when something changes ("Unsaved changes, Discard, Save") and stays pinned
- Warn before leaving with unsaved changes
- Risky instant changes offer Undo in the toast

## Notification Preferences

- A grid of notification types (rows) by channels (columns: in app, email, push, SMS) with a checkbox per cell
- Frequency per type where it applies (instant, daily digest, weekly)
- Quiet hours and a global pause
- Required notices (security, billing) are shown as always on with the reason

## Members and Roles

- Members list: name, email, role, status (active, invited, suspended), last active. Search and role filter. Pending invites in their own section
- Invite: several emails at once, the role chosen in the same step with a safe default, an optional message. Show what each role can do right there
- Pending invites can be resent, have their link copied, or be revoked. Show when they expire
- Change a role inline with a select. Removing a member confirms with what happens to their work. Transferring ownership confirms by typing
- Roles: a few clear built in roles, each with a plain description and a permissions table. Custom roles only for products that need them
- The server enforces permissions. A hidden button is not access control

## Billing and Plans

- Current plan, price, billing period, next invoice date and amount at the top
- Usage against limits as bars with numbers ("18 of 25 seats", "8.2 of 10 GB"), with warnings at about 80% and a clear path to upgrade before the limit is hit
- Plan comparison shows the current plan, the differences that matter, and price per seat and total
- Changing plans shows before and after: new price, proration on the next invoice, what features and limits change, and when it takes effect. Downgrades say what will be lost
- Payment method with brand and last four digits, update in place. Invoices list with date, amount, status and a download
- Trials: show the end date with a timeline, what happens at the end (downgrade or charge), and a reminder before it ends
- Hitting a limit during work: name the action that was blocked, the plan that unlocks it, and the cost. Let the user finish or save what they were doing. Never a paywall that throws away work
- Cancel is findable, takes few steps, says what happens to data, and may offer a pause or downgrade once

## Security

- Change password with the current one, show password toggles, and the rules visible before typing
- Two factor setup with an authenticator app as default, backup codes to download, and recovery explained
- Active sessions and devices with location and last active, "Sign out" per session and "Sign out of all other sessions"
- Personal API tokens: name, scope, expiry, last used. The token is shown once with a copy button

## Danger Zone

- The last section of workspace or account settings, visually separated
- Each action states its consequence ("Delete this workspace and all its classes, students and grades")
- Export data before deleting is offered
- Deletion confirms by typing the workspace or account name, and says if there is a grace period to restore

## Check

1. Can each setting be found in under 10 seconds by navigation or search?
2. Is the save model obvious on every page?
3. Can an admin invite with a role, resend, revoke and change roles without leaving the members page?
4. Does the billing page show usage before limits are hit, and does a plan change preview its cost?
5. Is account or workspace deletion findable, explained and protected?

## Sources

- [Toggle Switch Guidelines, NN/g](https://www.nngroup.com/articles/toggle-switch-guidelines/)
- [Saving pattern, Primer](https://primer.style/product/ui-patterns/saving/)
- [SaaS Settings Page UX Patterns, saasui.design](https://www.saasui.design/blog/saas-settings-page-ux-patterns)
- [SaaS Permissions and Roles UX Patterns, saasui.design](https://www.saasui.design/blog/saas-permissions-roles-ux-patterns)
- [SaaS Billing UX Patterns, saasui.design](https://www.saasui.design/blog/saas-billing-subscription-ux-patterns)
- [Notification Preference Center, SuprSend](https://www.suprsend.com/post/notification-preference-center)
