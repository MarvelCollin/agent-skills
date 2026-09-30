# Client-Side Attacks

Issues that execute in the victim's browser or trick it into acting.

## What to Check

- **XSS:** user input reflected into HTML, an attribute, JavaScript, or the DOM without encoding. Stored, reflected, and DOM-based.
- **CSRF:** state-changing requests that rely only on the cookie, with no anti-CSRF token or same-site protection.
- **Open redirect:** a redirect target taken from user input.
- **Clickjacking:** pages that can be framed, with no frame-busting or frame-ancestors control.
- **DOM issues:** client code that writes user input into `innerHTML`, `document.write`, or similar sinks.

## How to Test Safely

- XSS: prove that input reaches an executable context. Use a harmless marker that shows execution to you alone (a benign popup or a console write), never a payload that steals cookies, calls out to an attacker server, or acts on other users. On a stored XSS, put the proof where only your test account sees it.
- CSRF: check whether a state-changing request succeeds without a token and cross-site. Confirm by reading whether a token is required and checked, and whether cookies are same-site.
- Open redirect: give a redirect param an in-scope or benign external value and confirm the app sends the browser there.
- Clickjacking: check for `X-Frame-Options` or a `frame-ancestors` policy. Absence plus a sensitive action is the finding.

Keep every proof to yourself and your test account. Never target real users.

## Confirmed Finding Looks Like

Input executed in the browser context, or a cross-site state change succeeded, reproduced with evidence, impact stated, no real user affected.

## Fix

- XSS: encode output for the context (HTML, attribute, JS, URL). Use the framework's auto-escaping. Add a Content-Security-Policy. Avoid dangerous DOM sinks, use `textContent`.
- CSRF: require an anti-CSRF token on state changes, and set cookies `SameSite=Lax` or stricter.
- Open redirect: allowlist redirect targets, or only allow relative paths.
- Clickjacking: set `frame-ancestors` in CSP (or `X-Frame-Options: DENY`) on sensitive pages.

References: OWASP WSTG, CWE-79, CWE-352, CWE-601, CWE-1021.
