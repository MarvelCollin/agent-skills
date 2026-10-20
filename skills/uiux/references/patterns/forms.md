# Forms

Creating and editing data. What to ask, how to label it, when to validate, how to save. Geometry and alignment are rule R17 in [../form-layout.md](../form-layout.md). Form overlays are rule R14. Multi step flows are in [multi-step.md](multi-step.md).

## Ask Less

- Know why each field exists. Remove fields the product does not use now
- Never ask for something the system already knows (the user's email, their workspace, a value from the previous step)
- Prefill smart defaults (today, the current user, the last used value) that the user can change
- Ask optional and rare things later, or put them in a collapsed "More options" section
- Allow "I don't know" or "Not sure" when it is a valid answer

## Labels and Help

- Every field has a visible label above it, in plain words, sentence case. Placeholders are hints only and never replace a label
- Mark both required and optional fields, or follow one clear rule: when most fields are required, add "(optional)" to the rest. Explain the convention once if it is asterisks
- Constraints come before typing: "At least 12 characters", "PDF up to 10 MB". Never revealed only by an error
- Say why sensitive data is needed, right next to the field
- Help that is needed to answer sits under the label. Extra background can sit in a popup tip (see [components.md](components.md))

## Pick the Control

| Answer | Control |
|--------|---------|
| One of 2 to 5 options | Radio group, all visible |
| One of 5 to about 15 | Select |
| One of many (countries, people, products) | Combobox with type to filter |
| Several of a few | Checkboxes |
| Several of many | Multi select combobox with chips |
| On or off, saved with the form | Single checkbox |
| On or off, applied instantly | Switch (settings only) |
| A small number with a usual value | Number field with steppers |
| A date | Date picker with a typed input (R7) |
| A short text | Text input, width matching the answer |
| A long text | Textarea that grows with content |

Set `type`, `inputmode` and `autocomplete` correctly so phones show the right keyboard and browsers autofill (`email`, `tel`, `name`, `street-address`, `one-time-code`, `new-password`). Allow paste everywhere, including passwords and codes.

## Validation

- Validate a field when the user leaves it, not while typing. Exception: show requirements being met live for complex fields (password rules, username availability)
- Once a field shows an error, re-check it on every keystroke so the error clears as soon as it is fixed
- Errors appear next to the field, in text and with an icon, not color alone, linked with `aria-describedby` and `aria-invalid`
- On submit with errors: an error summary at the top that lists each error as a link to its field, focus moves to the summary, and the document title starts with "Error:". The summary uses the same wording as the field messages
- Never clear what the user typed because of an error
- Never disable the submit button until the form is valid (R14). Let them submit and show what is missing
- If the same error repeats, add more help or a way to get support

## Error Wording

Say what went wrong and how to fix it, in the user's words, without blame, "please", "sorry", "invalid" or codes.

| Problem | Write |
|---------|-------|
| Empty | "Enter your email address" |
| Wrong format | "Enter an email address like name@school.id" |
| Too long | "Name must be 60 characters or fewer" |
| Too short | "Password must be at least 12 characters" |
| Out of range | "Enter a score between 0 and 100" |
| Date rule | "Due date must be after the start date" |
| Not chosen | "Select a class" |
| Taken | "This email is already used by another account. Sign in instead" |
| Server failed | "We could not save the student. Check your connection and try again" |

## Saving

- One save model per form. Pick one:
  - **Explicit save** for related fields that must be valid together, money, permissions and anything affecting other people. A primary button named with the verb ("Create invoice", "Save changes")
  - **Autosave** for long text and documents, with a visible status ("Saving", "Saved 2 min ago") and version history
  - **Instant** for independent settings toggles (see [settings-account.md](settings-account.md))
- The button shows progress while saving ("Saving") and blocks double submits
- After saving: say what happened and where the user is now. A create form lands on the new record or back on the list with the new row highlighted. An edit form stays and shows "Saved"
- Unsaved changes: warn before the user leaves the page, closes the overlay or switches tab, with "Discard changes" and "Keep editing". Long forms keep a draft so a reload or crash does not lose work
- A failed save keeps every value, says why, and offers retry

## Page Forms

- One column, about 40rem wide, sections with headings (R17)
- Actions at the end on the form's left edge, primary first, then Cancel as a secondary or text button
- When a form is longer than the screen, pin a save bar at the bottom that appears once there are changes ("Unsaved changes, Discard, Save") (R19)

## Check

1. Submit empty. Do you get a summary, links to fields, focus moved, and the same wording next to each field?
2. Type a wrong value, leave the field, fix it. Does the error clear while typing?
3. Do phones get the right keyboards, and does autofill work?
4. Leave with changes. Are you warned?
5. Run the alignment check in [../form-layout.md](../form-layout.md)

## Sources

- [10 Design Guidelines for Reporting Errors in Forms, NN/g](https://www.nngroup.com/articles/errors-forms-design-guidelines/)
- [Hostile Patterns in Error Messages, NN/g](https://www.nngroup.com/articles/hostile-error-messages/)
- [Error message, GOV.UK Design System](https://design-system.service.gov.uk/components/error-message/)
- [Error summary, GOV.UK Design System](https://design-system.service.gov.uk/components/error-summary/)
- [Mark Both Required and Optional Fields, Baymard](https://baymard.com/blog/required-optional-form-fields)
- [Does Your Form Really Need a Dropdown List, NN/g](https://www.nngroup.com/articles/dropdown-list/)
- [Saving pattern, Primer](https://primer.style/product/ui-patterns/saving/)
