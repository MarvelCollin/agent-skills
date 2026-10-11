---
type: llm
---

The fixture is a small Vite React app with an Express server and Firebase. It has these planted launch gaps:

1. The OpenAI key sits behind the public `VITE_` prefix in `.env` and is sent from browser code in `src/lib/ai.js`, so it ships in the bundle.
2. `.env` is not in `.gitignore`, and `vite.config.js` turns on public source maps.
3. `firestore.rules` allows anyone to read and write every document (`allow read, write: if true`).
4. The Express server takes the price from `req.body.price` for the Stripe checkout, so a buyer can set their own price.
5. `/api/admin/users` lists every user with no auth and no role check.
6. No rate limiting, `cors()` allows every origin, and the error handler returns `err.stack`.
7. `console.log` prints the whole checkout request body.
8. `public/robots.txt` disallows every path for every crawler, and there is no sitemap.
9. Placeholder content: lorem ipsum, a "Jane Doe, CEO at Acme Corp" testimonial, 123 Main St, a 555 phone number and hello@example.com, plus `pocketcoach.example.com` in the Stripe return URLs.
10. Google Analytics loads with a placeholder ID (`G-XXXXXXXXXX`) and no consent banner.
11. The page title is the Vite default, with no meta description, no Open Graph tags and only the default vite.svg icon.
12. No privacy policy page, no terms page and no 404 route.
13. An image has no alt text and another uses a file name as its alt text.
14. The contact form has no inline error state and no success state.
15. No lockfile, so the dependencies cannot be audited.

PASS if the reply identifies at least ten of these fifteen gaps with the file or setting involved, lists the backend blockers (items 1, 3, 4 and 5 at least) ahead of cosmetic items, and gives a concrete fix for each blocker (for example: move the OpenAI call to a server route and rotate the key, scope Firestore rules to the signed in owner, look up the price on the server from the plan id, add a server side admin role check).
FAIL if it finds fewer than ten, does not put the leaked key or the open database rules among the first fixes, treats the Firebase web `apiKey` as a leaked secret, or invents real contact details, legal text or an analytics ID to fill the gaps.
