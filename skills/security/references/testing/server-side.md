# Server-Side Attacks

Input that makes the server do something on the attacker's behalf: fetch a URL, read a file, parse hostile data.

## What to Check

- **SSRF:** the server fetches a URL the user controls. Try to point it at internal addresses or the cloud metadata endpoint, and see if the response comes back or behavior changes.
- **Path traversal:** user input in a file path. Try to step outside the intended directory to reach another file.
- **File upload:** what types are accepted, where files land, whether they can be executed or served back, and whether the content type is checked, not just the extension.
- **XXE:** an XML parser that resolves external entities on user-supplied XML.
- **Insecure deserialization:** untrusted data deserialized into objects.

## How to Test Safely

- SSRF: aim at a benign in-scope or local address you control and confirm the server reached it. Do not pivot into out-of-scope internal systems. Stop at proof the server fetched an address it should not. Note the metadata endpoint risk without harvesting real credentials.
- Traversal: target a known-harmless file to prove you left the directory (a predictable app file), not system secrets. Prove the flaw, then stop.
- Upload: upload a benign test file, check where it lands and how it is served. Do not upload a working web shell to a system you do not own outright, and never to shared or production hosts.
- XXE and deserialization: prefer reading the parser and library config. A dynamic check uses a harmless marker (a benign external reference to a host you control, or an object that proves parsing), never a payload that runs code or reads secrets.

## Confirmed Finding Looks Like

The server fetched an address, read a file, or parsed an entity it should not have, reproduced with evidence, impact stated, and no out-of-scope system touched.

## Fix

- SSRF: allowlist the hosts the server may call. Block private ranges and the metadata endpoint. Resolve and validate the final address after redirects.
- Traversal: never build paths from raw input. Canonicalize and confine to a base directory, or use ids that map to safe paths server-side.
- Upload: validate content, store outside the web root, serve with a safe content type and no execution, generate the stored name.
- XXE: disable external entity resolution and DTDs in the parser.
- Deserialization: do not deserialize untrusted data. Use a data format without code execution, and validate against a schema.

References: OWASP WSTG, CWE-918, CWE-22, CWE-434, CWE-611, CWE-502.
