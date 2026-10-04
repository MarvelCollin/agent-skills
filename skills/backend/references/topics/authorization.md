# Authorization

Authentication says who the caller is. Authorization decides what they may do to which object. Broken authorization is the top API risk in the OWASP API Security Top 10 (2023): API1 broken object level, API3 broken object property level, and API5 broken function level authorization.

## Principles

- **Deny by default.** No permission means no access. A new route or field is closed until a rule opens it
- **Enforce on the server, every request.** Hiding a button is UX, not security
- **One policy layer.** Decisions go through one place (`can(user, action, resource)`, a policy class, or a policy engine), not ad hoc `if` checks scattered across handlers
- **Enforce in the domain or service layer**, not only in route middleware, so GraphQL resolvers, websockets, jobs, admin scripts and internal calls all get the same checks
- **Identity from the session.** User id, role and tenant come from the verified principal. Never from the body, query string, or a client-set header like `X-User-Id`
- **Least privilege.** Grant the smallest role that does the job. Service accounts and database users too

## The Three Levels

### Object level (BOLA, IDOR)

Every lookup by an id the client supplied must prove the caller may access that object.

Scope in the query, so the check and the fetch are one step and cannot drift apart:

```js
const order = await prisma.order.findFirst({
  where: { id: req.params.id, tenantId: req.user.tenantId },
})
if (!order) throw new NotFound()
```

```python
order = get_object_or_404(Order, pk=pk, owner=request.user)
```

```sql
SELECT id, status, total_cents FROM orders WHERE id = $1 AND tenant_id = $2
```

- Return 404, not 403, for objects outside the caller's scope, so ids cannot be probed
- For lists, the filter is part of the query. Never fetch a page and then drop rows the user may not see, which breaks counts and pagination and leaks through timing
- Nested resources check the whole chain: `/projects/:p/tasks/:t` verifies the task belongs to that project and the project to the caller
- Random or UUID ids make guessing harder but are not authorization

### Function level

- Admin and privileged endpoints check the permission on the server. Put them behind a separate router with its own required permission so a missing check is visible
- Check the action, not just the role name: `invoice:refund` rather than `role == "admin"` scattered everywhere. Roles map to permissions in one table
- HTTP method matters. A user who may `GET /users/:id` may not `DELETE /users/:id`

### Property level

- **Writes:** an explicit allowlist of fields per role. Never pass the raw request body to `create`, `update`, `save` or `Object.assign` (mass assignment). A user must not set `role`, `is_admin`, `tenant_id`, `balance`, `verified` or `owner_id`
- **Reads:** a response DTO per endpoint and role. Fields like `email`, `cost_price` or internal notes appear only for callers allowed to see them

## Multi-Tenancy

- The tenant id is resolved from the authenticated principal, once, at the edge, and carried in request context
- Every tenant-owned table has a `tenant_id` column with an index, usually leading composite indexes
- Enforce scoping centrally: a base repository that always adds the tenant filter, an ORM default scope or global query filter (EF Core `HasQueryFilter`, Hibernate filters, Django custom managers, Laravel global scopes, Prisma client extensions)
- Defense in depth with Postgres Row Level Security:

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY
```

```sql
CREATE POLICY tenant_isolation ON invoices
  USING (tenant_id = current_setting('app.tenant_id')::uuid)
```

  Set the value per transaction with `SET LOCAL app.tenant_id = '...'` (safe with transaction-level pooling). Table owners and superusers bypass RLS unless you use `FORCE ROW LEVEL SECURITY`, so the app should connect as a non-owner role
- Unique constraints include the tenant: `UNIQUE (tenant_id, email)`
- Cache keys, search indexes, file storage paths and job payloads all include the tenant
- Background jobs re-establish tenant context from the job payload and recheck authorization if the actor's permissions might have changed

## Choosing a Model

| Model | Fits | Tools |
|-------|------|-------|
| RBAC (roles to permissions) | Most business apps with a handful of roles | Framework guards, CASL, Pundit, django-guardian, Spatie Permission |
| ABAC (rules on attributes of user, resource, context) | Rules like "managers approve expenses under 5000 in their department" | OPA and Rego, Cedar, Casbin, Oso |
| ReBAC (relationships, Google Zanzibar style) | Sharing and nested ownership: docs, folders, orgs, teams | OpenFGA, SpiceDB, Permify |

Start with RBAC plus ownership checks. Move to a policy engine when rules multiply or need to be shared across services. Keep policy decisions testable as plain functions.

## Sensitive Flows

- Step-up authentication for destructive or high-value actions
- Four-eyes approval for admin actions on money or access
- Rate limits and anomaly checks on flows that can be abused even when authorized (OWASP API6): mass export, referral credit, gift cards, ticket purchase
- Impersonation by support staff is explicit, time-limited, audited, and visible to the user

## Audit

Log every authorization denial as a security event and every sensitive allowed action in the audit log (who, action, resource, tenant, time, source IP, outcome). A spike in denials from one account is an attack signal.

## Testing

Build an authorization matrix and test it automatically:

| Endpoint | Anonymous | Owner | Other user, same tenant | Other tenant | Admin |
|----------|-----------|-------|------------------------|--------------|-------|
| GET /orders/:id | 401 | 200 | 404 | 404 | 200 |
| PATCH /orders/:id | 401 | 200 | 404 | 404 | 200 |
| POST /admin/refunds | 401 | 403 | 403 | 403 | 201 |

- Each cell is a test. Negative cells matter most
- Include a mass assignment test: send `role: "admin"` in a profile update and assert it is ignored or rejected
- Run the matrix in CI so a new route without a policy fails the build

## Checklist

- [ ] Default deny, one policy layer, enforced in the service layer
- [ ] Every id lookup is scoped by owner or tenant in the query
- [ ] No identity, role or tenant taken from client input
- [ ] Write allowlists and read DTOs per role
- [ ] Tenant isolation enforced centrally, ideally with RLS as a backstop
- [ ] Authorization matrix tests in CI
