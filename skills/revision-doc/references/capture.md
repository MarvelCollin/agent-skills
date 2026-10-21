# Capturing Before and After Shots

## Same screen, same conditions

- One viewport for the whole batch, 1440x900 unless the change is about another size. Mobile changes get their own shots at the mobile size.
- Same account, same company or tenant, same data, same language and same scroll position for the before and the after of a page.
- Name files `NN-what-it-shows.png` and group them by role (`hr/`, `candidate/`, `admin/`). The after shot uses the same name as its before shot.
- Capture the viewport, not the full page, unless the change is far down the page. A full page shot shrinks to an unreadable strip in the document.

## Before shots

- Take them before editing the code. That is the only time the old screen is free.
- When the code is already changed, export the last commit to a separate folder (`git archive <sha> | tar -x -C <dir>`) and run it on another port. Never use `git stash` in a tree that other people or sessions also edit.
- A bug shot shows the bug happening: the error message on screen, the broken state, or the moment before the failure.
- Say when a before shot cannot exist and write a `before_note` instead.

## Moving or short lived states

- To photograph a dialog while it closes, a toast, or any animation, slow it down first with injected CSS, for example `[data-closed]{animation-duration:4s!important}`, trigger it, and take the shot a second later. Say in the intro that the animation was slowed.
- For hover and focus states, hover or focus the element with the browser tool, then take the shot.
- For numbers that prove a change (a height that no longer jumps, a load time), measure them in the page and put the numbers under Checked.

## Browser tips

- Wait for the page to settle (network idle, skeletons gone) before the shot.
- Scroll the changed element into view with `scrollIntoView({block: "center"})` so before and after line up.
- Close dev overlays and cookie banners that cover the change, the same way in both shots.
