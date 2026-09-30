# Configuration and Hardening

Weaknesses in how the app and its environment are set up. Often low effort to fix and easy to confirm.

## What to Check

- **Security headers:** missing `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`, frame protection, and a sensible `Referrer-Policy`.
- **TLS:** weak or missing HTTPS, mixed content, weak ciphers, no HSTS.
- **CORS:** a policy that reflects any origin, or allows credentials with a wildcard.
- **Exposed surfaces:** admin panels, debug endpoints, `.git`, backups, config files, directory listing, source maps in production.
- **Default and weak credentials:** default admin logins, sample accounts left enabled.
- **Verbose errors:** stack traces, framework versions, and internal paths in responses.
- **Debug mode:** development mode or debug flags on in a deployed build.

## How to Test Safely

- Read response headers and the server config directly. Fast and non-invasive. A header read or the browser network panel is enough.
- Check CORS by sending an `Origin` and reading `Access-Control-Allow-Origin` and `-Allow-Credentials`.
- Probe for exposed paths with a small, targeted list, not a large scan. Confirm by reading, do not download real backups or secrets.
- For default creds, try only documented defaults for that software, once, on a system you own. Never a credential-stuffing run.

## Confirmed Finding Looks Like

A missing header, a permissive CORS policy, an exposed admin or debug surface, a verbose error leaking internals, with the response saved and impact stated.

## Fix

- Set the security headers, with a CSP tuned to the app. Enforce HTTPS and HSTS.
- Lock CORS to known origins. Never reflect the origin with credentials allowed.
- Remove or protect admin, debug, and source artifacts in production. Turn off directory listing and source maps.
- Change all default credentials. Disable sample accounts.
- Return generic errors to users, log details server-side. Turn off debug mode in deployed builds.

References: OWASP Top 10 A05, WSTG Configuration, CWE-16, CWE-942, CWE-756.
