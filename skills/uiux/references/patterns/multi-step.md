# Multi Step Flows

Wizards, setup flows, applications and checkouts. Use steps when the input is long, branches on earlier answers, or has a natural order. Do not split a short form into steps just to look simpler.

## Choose the Shape

| Shape | Use when |
|-------|----------|
| One page form | Under about 8 to 10 related fields |
| Linear stepper | 3 to 7 steps that must happen in order, each depending on the previous |
| Task list | Many independent sections the user may finish in any order and over several sessions |
| One question per page | Public or low confidence users, mobile first, complex branching |

More than 7 steps means the flow should be regrouped or split.

## Steps

- Each step has a name, not "Step 2". The stepper shows names, the current step and done steps: "Step 2 of 4, Class details"
- Each step has its own URL so Back and reload work
- Back never loses data. Going back and forward keeps every answer
- Validate a step when the user continues, errors as in [forms.md](forms.md)
- Done steps can be revisited from the stepper. Future steps cannot be jumped to in a linear flow
- Save progress automatically. A user who leaves can resume where they stopped, and the flow says so ("Your progress is saved")
- Show only the steps that apply to this user
- In an overlay, the frame keeps a fixed height and the footer stays pinned (R14). Prefer a full page for more than 3 steps

## Task List

- Groups of tasks with a status each: "Not started", "In progress", "Completed", "Cannot start yet" (with the reason)
- Completed status is quiet, so tasks that need action stand out
- Tasks named with a verb ("Add students", "Set grading scale")
- Shown at the start and on every return, with the overall progress ("3 of 6 done")

## Check Answers

Before a submit that commits something important:

- A summary of every answer grouped by section, with a "Change" link per answer that returns to the page and then straight back to the summary
- Skipped optional answers show "Not provided"
- No new information appears for the first time here
- The submit button names the action ("Create class and invite students")

## Confirmation

- A clear success state: what was done, its reference number, what happens next and when, and where to go now
- Never a blank "Success!" page

## Check

1. Leave on step 3 and come back. Are answers kept?
2. Press Back in the browser on each step. Does it go to the previous step with data?
3. Change an answer from check answers. Do you return to the summary?
4. Does the confirmation say what happens next?

## Sources

- [Question pages, GOV.UK Design System](https://design-system.service.gov.uk/patterns/question-pages)
- [Check answers, GOV.UK Design System](https://design-system.service.gov.uk/patterns/check-answers/)
- [Complete multiple tasks, GOV.UK Design System](https://design-system.service.gov.uk/patterns/complete-multiple-tasks/)
- [One thing per page, GDS](https://designnotes.blog.gov.uk/2015/07/03/one-thing-per-page/)
- [Modal and Nonmodal Dialogs, NN/g](https://www.nngroup.com/articles/modal-nonmodal-dialog/)
