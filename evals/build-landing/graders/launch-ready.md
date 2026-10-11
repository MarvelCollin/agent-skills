---
type: llm
focus: { source: file, path: index.html }
---

This is the landing page that was built.

PASS if all of these hold:
1. The head has a `<title>`, a meta description, a viewport meta, `<html lang>`, Open Graph title, description and image tags, and a favicon link
2. The main call to action (join the waitlist) sits in the hero, so it shows without scrolling at 375px and at 1440px wide, and on narrow screens a sticky action or an equally reachable path to the form exists on the long page
3. Every `<img>` has an `alt` attribute
4. The waitlist form shows errors inline next to each field (not `alert()` and not only browser bubbles), and shows a success state after a valid submit that says what happens next
5. The footer links to a privacy policy and terms, and shows contact details or a clearly marked placeholder for them, never an invented street address or a 555 phone number
6. Pricing shows exactly the two real plans (Free and Team at $12 per location per month), not a third invented tier

FAIL if any of the six is missing.
