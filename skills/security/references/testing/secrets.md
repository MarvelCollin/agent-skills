# Exposed Secrets

Keys, tokens, passwords, and connection strings that should never be readable ending up in code, config, responses, or history.

## What to Check

- **In source and config:** hardcoded API keys, passwords, private keys, connection strings, cloud credentials.
- **In version control history:** secrets committed once and "removed" later, still in history.
- **In client bundles:** keys shipped to the browser in JavaScript, or in source maps.
- **In responses and errors:** internal tokens, credentials, or PII returned by an endpoint or leaked in a stack trace.
- **In logs:** secrets or tokens written to logs the app exposes.

## How to Test Safely

- Grep the tree and the client bundle for key-shaped strings and secret keywords. The `grep-audit` script in [../code-review.md](../code-review.md) covers this. Each hit needs a read to confirm it is a real, live secret and not a placeholder or a public key.
- Check version control history for the same patterns.
- Watch responses during recon for anything that looks like a credential or token that should be server-only.
- Do not use any real secret you find. Confirming it exists and is reachable is the finding. Report it, do not exercise it.

## Confirmed Finding Looks Like

A real, still-valid secret readable from source, history, a client bundle, or a response, with the location saved (redacted) and impact stated.

## Fix

- Remove the secret from code and config. Move it to a secrets manager or environment variables loaded at runtime.
- Rotate any exposed secret immediately. Removing it from the current file is not enough once it has been exposed.
- Purge it from version control history, and rotate anyway.
- Keep server-only keys off the client. Scope and restrict keys that must be public.
- Add secret scanning to CI so it does not happen again.

References: OWASP WSTG, CWE-798, CWE-540, CWE-312.
