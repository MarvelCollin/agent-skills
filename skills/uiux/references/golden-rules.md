# Shneiderman's Eight Golden Rules

Ben Shneiderman's eight rules of interface design. Each rule below says what it means, how to apply it while building, and how to check it in a review or audit. Use them alongside Nielsen's heuristics in [heuristics.md](heuristics.md).

## 1. Strive for Consistency

Similar situations use the same actions, words, colors, layout and type.

Build:
- One component per job across the product (R8 in [build-rules.md](build-rules.md))
- One word per concept. If it is "Delete" in one place, it is not "Remove" in another
- Primary action in the same position in every form and dialog

Check: Find two screens that do similar things. Do they look and behave the same? List every inconsistency.

## 2. Seek Universal Usability

Design for novices and experts, different ages, abilities, devices and connection speeds.

Build:
- Clear labels and helper text for newcomers, keyboard shortcuts and bulk actions for experts
- WCAG AA as the floor: contrast, keyboard access, screen reader names, visible focus
- Layouts that work from 320px wide up, and touch targets of at least 44 by 44px

Check: Try the main task by keyboard only, at 375px wide, and at 200% zoom. Does it still work?

## 3. Offer Informative Feedback

Every action gets a response that fits its weight. Small actions get a subtle response and big ones get a clear confirmation.

Build:
- Hover, pressed and focus states on everything interactive
- Loading indicators for anything over about 300ms, and progress for anything over a few seconds
- Success messages that say what happened ("Schedule saved for 12 March"), not just "Success"

Check: Click every action. Did something visibly change within a moment? Did I know whether it worked?

## 4. Design Dialogs to Yield Closure

Sequences of actions have a clear start, middle and end, and the end is obvious.

Build:
- Multi-step flows show the steps and where the user is in them
- A clear completion screen or message with the next sensible step
- Group related actions into one flow instead of scattering them

Check: After finishing a task, do I know it is done and what to do next?

## 5. Prevent Errors

Make mistakes hard to make. When they happen, make them easy to fix.

Build:
- Constrain input: custom pickers for dates and options (R7), disabled actions that cannot apply yet, with a reason shown on hover or focus
- Validate inline as the user leaves a field, next to the field, in plain words that say how to fix it
- Never clear a form after an error. Keep what the user typed
- Ask for confirmation only before destructive actions that cannot be undone, and name the object ("Delete 3 test results?")

Check: Submit forms empty and with bad data. Is the error next to the field, specific, and is my input kept?

## 6. Permit Easy Reversal of Actions

Users explore more freely when they know they can undo.

Build:
- Undo for deletes and bulk changes (a message with an Undo action for a few seconds) instead of a confirmation for every action
- Cancel and Back in every flow, and Escape to close overlays
- Drafts and autosave for long forms

Check: Delete or change something by mistake. Can I get it back in one step?

## 7. Keep Users in Control

The interface responds to the user and does not surprise them.

Build:
- No content that moves, auto-advances or autoplays without a way to pause it
- No focus jumps, surprise redirects or layout shifts while the user is working
- Filters and settings stay as the user left them (R5 keeps table filters in the URL)
- Users decide when to submit. No auto-submit on field change for anything consequential

Check: Did anything happen that I did not ask for? Did anything move while I was reading or clicking?

## 8. Reduce Short-Term Memory Load

Keep what users need visible, so they recognize instead of remember.

Build:
- Keep context on screen: the selected record's name in the edit dialog, active filters above the table, the steps in a flow
- Visible labels on fields (never only placeholders), and recent or suggested values in pickers
- Do not ask users to copy information from one screen to another
- Keep related information on one screen rather than splitting it across tabs the user must compare

Check: Did I ever have to remember something from a previous screen to finish the task?

## Scoring

In a review or audit, rate each rule Pass, Partial or Fail with one line of evidence, and record it in the Golden Rules table of the report or UI review.

## Source

- [The Eight Golden Rules of Interface Design, Ben Shneiderman](https://www.cs.umd.edu/users/ben/goldenrules.html)
