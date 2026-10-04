# Config, Secrets and Deployment

Build once, configure per environment, deploy without downtime, roll back fast.

## Configuration

- All config comes from environment variables or a secrets manager (twelve-factor). Nothing environment-specific is baked into the build
- One typed config module loads and validates everything at startup and exits with a clear message when something is missing or malformed. The rest of the code imports the typed object, never `process.env` directly

| Stack | Config validation |
|-------|-------------------|
| Node | zod or envalid over `process.env` |
| Python | pydantic-settings |
| Go | envconfig or viper plus validation |
| Java Spring | `@ConfigurationProperties` with `@Validated` |
| .NET | Options pattern with `ValidateDataAnnotations` and `ValidateOnStart` |
| Rails | credentials plus `ENV.fetch` (raises when missing) |

- No defaults for secrets. `process.env.JWT_SECRET || "dev-secret"` ships the dev secret to production the day the variable is missing
- Non-secret defaults are fine when safe (port, log level)

## Secrets

- Stored in a secrets manager (Vault, AWS Secrets Manager or SSM, GCP Secret Manager, Azure Key Vault, Doppler, 1Password) or encrypted in the repo with SOPS
- Never in source, Dockerfiles, CI logs, images, or committed `.env` files. Add secret scanning (gitleaks, trufflehog, GitHub push protection) to CI and pre-commit
- Rotate on a schedule and immediately on exposure. Design for two valid secrets during rotation
- Prefer short-lived credentials: cloud IAM roles, workload identity, database IAM auth, over long-lived keys
- Each service gets its own credentials with least privilege. The app's database user cannot drop tables or alter schema. Migrations use a separate role

## Feature Flags

- Ship dark, release with a flag, roll out by percentage or tenant
- Kill switches for risky dependencies and expensive features
- Remove flags after full rollout. Old flags are tech debt and hidden branches

## Containers

- Multi-stage builds. Small runtime images (distroless, slim, alpine where libc differences are understood)
- Run as a non-root user with a read-only root filesystem where possible
- Pin base images by version or digest and rebuild regularly for patches
- One process per container. Proper PID 1 signal handling (`exec` form entrypoint, `tini`)
- Resource requests and limits set. Runtime memory set below the container limit: Node `--max-old-space-size`, JVM `-XX:MaxRAMPercentage`, Go `GOMEMLIMIT`
- `TZ=UTC`
- Scan images for vulnerabilities (Trivy, Grype) in CI

## Deployment

- **Build once, promote:** the same image moves from staging to production with different config
- **Zero downtime:** rolling updates gated on readiness, or blue-green, or canary releases that watch error rate and latency and roll back automatically
- **Database changes** are decoupled from code changes with expand and contract (see [migrations.md](migrations.md)). Migrations run once per release in a separate step
- **Rollback** is one command and practiced. Know which migrations make rollback unsafe
- **Graceful shutdown** so deploys do not drop requests (see [resilience.md](resilience.md))

## CI Pipeline

1. Install with a lockfile (`npm ci`, `pip install --require-hashes` or `uv sync --frozen`, `go mod download`)
2. Lint, format check, type check
3. Unit and integration tests, migration check
4. Dependency audit (`npm audit`, `pip-audit`, `govulncheck`, OWASP Dependency-Check, osv-scanner) and secret scan
5. Build the image, scan it, generate an SBOM
6. Deploy to staging, smoke test, load smoke on hot paths
7. Promote to production with a canary

Keep dependencies current with Renovate or Dependabot and small, frequent updates.

## Backups and Recovery

- Automated backups with point-in-time recovery for the primary database
- Defined RPO (how much data you can lose) and RTO (how long you can be down)
- Restore tested on a schedule. An untested backup is a hope
- Backups encrypted, in a separate account or region, with access restricted

## Runbooks

Each service has a short runbook: what it does, dependencies, dashboards, common alerts and what to do, how to roll back, how to scale, and who owns it.

## Checklist

- [ ] Typed config validated at startup, no secret defaults
- [ ] Secrets in a manager, scanning in CI, rotation possible
- [ ] Non-root, pinned, scanned container with resource limits
- [ ] Same artifact promoted, zero-downtime rollout, tested rollback
- [ ] Migrations decoupled from deploys
- [ ] Backups with tested restores
