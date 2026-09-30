# Reconnaissance

Map the attack surface inside scope. The goal is a clear picture of where user input enters, where it lands, and who is allowed to do what. Confirm the target is in `scope.md` before you start (see [authorization.md](authorization.md)).

For an app the user owns, the fastest and safest recon is reading its own source and watching its traffic, not hammering it from outside.

## Start from the Inside

If you have the source:

- Map routes and endpoints from the router or framework config
- List every input: query and path params, body fields, headers, cookies, file uploads, websocket messages
- Find the sinks: database queries, shell calls, file reads and writes, HTTP calls out, template rendering, HTML output, deserialization
- Note where input reaches a sink without validation or encoding. Those are your leads
- Map the auth model: how login works, how sessions or tokens are issued, what roles exist, how access is checked
- Note the stack: language, framework, database, key libraries and versions, reverse proxy

## From the Running App

Drive the app in the browser (see [browser-protocol.md] equivalents in the uiux skill, or use agent-browser) and watch the network panel:

- Walk the main flows while logged in as the test user. Record each request and response
- Note every endpoint, parameter, and content type actually used
- Note security headers, cookie flags, CORS behavior, and error verbosity
- Note client-side routes and any API the front end calls

Keep external, noisy scanning to a minimum. If you use a scanner, keep it rate-limited and inside scope. Prefer targeted checks over broad fuzzing.

## Build recon.md

```markdown
# Recon: <target>

## Stack
- <language, framework, db, proxy, notable libs and versions>

## Auth model
- Login: <how>
- Session or token: <cookie, JWT, etc, with flags>
- Roles: <list>
- Access checks: <where and how>

## Endpoints
| Method | Path | Auth required | Inputs | Reaches sink |
|--------|------|---------------|--------|--------------|

## Inputs to sinks (leads)
- <input> -> <sink> in <file:line or endpoint>, validation: <none/partial/encoded>

## Observations
- Headers, CORS, cookie flags, error verbosity, anything odd
```

Use the leads table to drive [testing](testing/). Match each vulnerability class to the inputs and sinks you found, rather than testing everything everywhere.
