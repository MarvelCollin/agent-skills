# Broken Authentication and Access Control

The most common and most impactful class. The app either lets the wrong person in, or lets a logged-in person reach data and actions that are not theirs.

## What to Check

- **Broken authentication:** weak or missing login controls, username enumeration, no lockout or rate limit on login, weak password reset, credentials in the URL.
- **IDOR (insecure direct object reference):** an object id in a request that the server does not check the caller owns. Change the id to another user's and see if you get their data.
- **Missing function-level access control:** an admin or privileged endpoint reachable by a normal user, or by no auth at all.
- **Privilege escalation:** a normal user reaching admin actions, horizontally (another peer) or vertically (higher role).
- **Forced browsing:** protected pages reachable by direct URL without going through the check.

## How to Test Safely

Use two test accounts you are allowed to use (for example a low-privilege user and, if permitted, a second peer). Never use real users' accounts or data.

- For each object-scoped request, swap the id for one belonging to the other test account. If you get their data or can act on it, that is an IDOR.
- For each privileged endpoint, call it as the low-privilege user and as no user. If it works, access control is missing.
- Check that access is enforced on the server for every state-changing and data-returning route, not just hidden in the UI.
- For reset and login, check for enumeration (different responses for valid versus invalid users), missing rate limits, and predictable tokens. Keep attempts low, do not run a brute force.

Read the code where you can: the presence of an ownership or role check on the route is the fastest confirmation either way.

For a role, owner or tenant that the client sends (body, header, cookie, JWT claim), see [tampering.md](tampering.md).

## Confirmed Finding Looks Like

Test account A reached account B's data or action, or a normal user reached an admin function, reproduced twice, with both requests saved and the missing check identified.

## Fix

- Enforce authorization on the server for every request, checking both authentication and that the caller may access the specific object.
- Deny by default. Add the check at a central layer so no route is missed.
- Use unguessable ids where helpful, but never rely on that alone. The ownership check is the control.
- Rate-limit and lock out login and reset. Return the same response for valid and invalid users.

References: OWASP Top 10 A01 and A07, WSTG Authentication and Authorization, CWE-639, CWE-284, CWE-285, CWE-862.
