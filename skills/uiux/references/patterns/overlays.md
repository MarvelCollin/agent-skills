# Overlays, Confirmations and Destructive Actions

Which surface to use for a task, and how to protect users from mistakes without nagging them. Overlay sizing is rule R6, form overlays are rule R14 in [../build-rules.md](../build-rules.md).

## Pick the Surface

| Surface | Use for | Not for |
|---------|---------|---------|
| Inline (in the page) | Small edits, expanding detail, errors | Anything that needs focus away from the page |
| Popover | A few controls tied to one element (a filter, a quick setting, a color pick) | Forms with a submit, long content |
| Tooltip | A short label or hint on hover and focus | Anything the user must read to finish the task, or anything interactive |
| Dropdown menu | A list of actions or navigation from one trigger | Choosing a form value (use a select) |
| Modal dialog | Short, focused, self contained decisions: confirm, a 1 to 8 field form, a critical warning | Long forms, wizards, tasks that need the page behind for reference |
| Drawer or side sheet | Sub tasks that need the context behind visible: editing a row next to the list, a record preview, filters | Critical confirmations |
| Full page | Long or multi step tasks, anything with its own URL worth sharing | Quick confirmations |

- Never stack a modal on a modal. Replace the content or move to a page
- Every overlay closes with Esc, with a visible close button, and by clicking the backdrop unless it holds unsaved input. Focus moves in on open, stays trapped in modals, and returns to the trigger on close
- Overlays the user would want to link to (a record preview) update the URL
- On mobile, modals become bottom or full screen sheets with the actions pinned

## Do Not Interrupt

- No modal on page load, no newsletter or survey pop up during a task, no upsell modal in the middle of a flow
- Ask for information in a modal only when it is required to continue an action the user started (sign in to save, pick a plan to upgrade)

## Confirmations

Confirm only when an action is destructive, irreversible, expensive, or affects other people. Never for routine actions, because users learn to click through.

- Title names the action and the object: "Delete 3 students?"
- Body states the consequence in one or two lines: "Their grades and submissions will be deleted. This cannot be undone."
- Buttons are verbs that repeat the action: "Delete 3 students" and "Cancel". Never Yes and No, never OK
- The destructive button uses the danger style and sits apart from the safe one. No default focus on the destructive button
- For the most severe actions (deleting a workspace, an account, all data), the user types the object's name to enable the button
- Disable the button while working, show progress, then close and confirm with a toast

## Undo Beats Confirm

- Make deletes soft where possible (archive, trash, or a delay before purge) and show a toast: "Invoice deleted. Undo". The toast with an action stays until dismissed or for at least 10 seconds, and is reachable by keyboard
- Bulk changes and state changes ("Mark as paid") use undo the same way
- A Trash or Archive view lets users restore later

## Placement of Dangerous Actions

- Keep destructive actions away from frequent ones. In menus, put them last after a separator. In forms and overlays, on the opposite side from the primary action
- Use the danger color plus an explicit verb ("Delete", "Remove access"), never an icon alone
- Settings that can destroy data live in a "Danger zone" section at the end (see [settings-account.md](settings-account.md))

## Disabled Actions

- Prefer an enabled button that explains the problem when clicked over a disabled button with no reason
- When disabling is right (no permission, wrong state), say why next to the control or in a tooltip that also opens on focus. Use `aria-disabled` so keyboard and screen reader users can still find it and hear the reason
- Hide actions the user can never use in this context. Disable actions they could use after a change, and say which change

## Check

1. Can every overlay be closed with Esc and does focus return to the trigger?
2. Is there any modal the user did not ask for?
3. Does every destructive action name its object and consequence, with verb buttons?
4. Is Undo offered where the action can be reversed?
5. Does every disabled control explain itself?

## Sources

- [Modal and Nonmodal Dialogs, NN/g](https://www.nngroup.com/articles/modal-nonmodal-dialog/)
- [Confirmation Dialogs Can Prevent User Errors, NN/g](https://www.nngroup.com/articles/confirmation-dialog/)
- [Dangerous UX: Consequential Options Close to Benign Options, NN/g](https://www.nngroup.com/articles/proximity-consequential-options/)
- [Modal vs. Separate Page: UX Decision Tree, Smashing Magazine](https://www.smashingmagazine.com/2026/03/modal-separate-page-ux-decision-tree/)
- [Tooltip Guidelines, NN/g](https://www.nngroup.com/articles/tooltip-guidelines/)
- [Dialog (Modal) pattern, WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/)
