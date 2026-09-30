# Injection

Untrusted input changes the meaning of a query or command. Covers SQL, NoSQL, OS command, LDAP, and template injection (SSTI). Map from the leads in `recon.md`: inputs that reach a query, a shell call, or a template.

## What to Check

- **SQL and NoSQL:** any input used to build a query. Look for string concatenation instead of parameters.
- **OS command:** input passed to a shell, `exec`, or a process call.
- **LDAP:** input in a directory filter.
- **Template (SSTI):** input rendered by a server-side template engine.

## How to Test Safely

Prove the issue with the lightest input that shows the parser is confused. Do not run destructive or data-exfiltrating payloads on a system you are only reviewing.

- Prefer reading the code: if the query is parameterized and the input is bound, it is safe. If it is concatenated, it is a lead.
- Dynamic check with a minimal probe:
  - SQL: a value that would break or change a query syntactically, and a matching pair that should behave the same versus different (a true versus false condition), observed through app behavior, not by dumping data.
  - Command and SSTI: an input that would evaluate to a harmless, observable result if injected (a simple arithmetic expression for SSTI, an echo of a benign marker), never a system-altering command.
- Time-based or blind checks: keep any delay tiny and run it once. Never loop it.

Stop at proof of the flaw. Do not extract real data, read system files, or run further commands.

## Confirmed Finding Looks Like

The probe changed how the query or command was parsed, reproduced twice, with the request and response saved. Impact stated in terms of what an attacker could reach.

## Fix

- Parameterized queries or prepared statements. Never build queries from strings.
- Safe process APIs with argument arrays, never a shell string. Avoid shelling out at all where possible.
- Allowlist and type-check input that must be part of an identifier (table or column names).
- For templates, never render user input as a template. Pass it as data to a fixed template, with auto-escaping on.
- ORM and query builders used correctly, with binding.

References: OWASP WSTG Injection, CWE-89, CWE-78, CWE-94, CWE-1336.
