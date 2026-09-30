# Session and Token Handling

How the app remembers who you are, and whether that can be stolen, forged, or reused.

## What to Check

- **Cookie flags:** session cookies without `HttpOnly`, `Secure`, and `SameSite`.
- **Session lifecycle:** session id not rotated on login, not invalidated on logout, no idle or absolute timeout.
- **Session fixation:** an attacker-set session id that survives login.
- **Token strength:** predictable or short session ids or reset tokens.
- **JWT flaws:** `alg: none` accepted, weak or shared signing key, signature not verified, no expiry, sensitive data in the payload, no revocation.
- **OAuth flows:** missing state parameter (CSRF on the flow), redirect_uri not strictly validated, tokens leaked in the URL.

## How to Test Safely

- Read the cookie flags and JWT config directly where you can. It is the fastest confirmation.
- Confirm the session id changes after login and dies after logout, using your test account.
- For JWT, check whether the server verifies the signature and rejects `none` and a tampered token. Test with your own token, not anyone else's.
- For OAuth, check for a `state` value and strict `redirect_uri` matching.

Never harvest or replay another person's real session or token.

## Confirmed Finding Looks Like

A cookie missing a flag with a stated impact, a session that survives logout, a token the server accepts without verifying, reproduced with evidence.

## Fix

- Set `HttpOnly`, `Secure`, and `SameSite` on session cookies.
- Rotate the session id on login, invalidate on logout, add timeouts.
- Generate ids and tokens from a CSPRNG, long enough to resist guessing.
- JWT: verify the signature, pin the algorithm, reject `none`, set short expiry, keep secrets out of the payload, support revocation.
- OAuth: require and check `state`, match `redirect_uri` exactly, keep tokens out of URLs.

References: OWASP WSTG Session Management, CWE-384, CWE-613, CWE-1004, CWE-347.
