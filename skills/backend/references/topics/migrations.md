# Safe Schema Migrations

A migration that takes an exclusive lock on a busy table can stall every request for minutes. The rules below keep schema changes online. Examples use Postgres. MySQL notes are at the end.

## Expand, Migrate, Contract

During a rolling deploy, the old and new app versions run at the same time against one schema. Every migration must work with both.

1. **Expand:** add the new column, table or index. Nullable or with a default. Old code ignores it
2. **Dual write:** deploy code that writes both the old and new shape
3. **Backfill:** copy existing data in batches
4. **Switch reads:** deploy code that reads the new shape
5. **Contract:** after the old code is gone, drop the old column in a later release

Renaming a column in one step breaks the old version mid-deploy. Do it as add new, dual write, backfill, switch, drop old.

## Operation by Operation

| Change | Risk | Safe approach |
|--------|------|---------------|
| Create index | `CREATE INDEX` blocks writes for the whole build | `CREATE INDEX CONCURRENTLY`, outside a transaction. If it fails it leaves an invalid index, so drop and retry |
| Add column with constant default | Fast since Postgres 11 | Fine |
| Add column with volatile default (`now()`, `gen_random_uuid()`) | Rewrites the table | Add nullable, backfill in batches, then set the default |
| Add `NOT NULL` | Full scan under lock | Add `CHECK (col IS NOT NULL) NOT VALID`, then `VALIDATE CONSTRAINT`, then `SET NOT NULL` (Postgres 12 and later uses the validated check) |
| Add foreign key | Locks both tables while it scans | `ADD CONSTRAINT ... NOT VALID`, then `VALIDATE CONSTRAINT` separately |
| Change column type | Usually rewrites the table | New column, dual write, backfill, switch, drop old |
| Drop column | Old code still selects it | Stop using it in code first, deploy, then drop |
| Rename table or column | Breaks the running version | Expand and contract, or a view during transition |
| Add unique constraint | Index build locks | `CREATE UNIQUE INDEX CONCURRENTLY`, then `ADD CONSTRAINT ... USING INDEX` |

## Lock Safety

Even a fast `ALTER` waits for an exclusive lock, and while it waits it blocks every query queued behind it. Set a short lock timeout in every migration and retry instead of queueing:

```sql
SET lock_timeout = '5s'
```

```sql
SET statement_timeout = '15min'
```

Run migrations at low traffic for anything that rewrites data, and watch for long-running transactions before you start (`pg_stat_activity`).

## Backfills

- In batches of 1,000 to 10,000 rows by primary key range, with a pause between batches
- Idempotent and resumable: `UPDATE ... WHERE new_col IS NULL AND id BETWEEN $1 AND $2`
- Run as a job or script, not inside the schema migration transaction
- Watch replication lag and stop if it grows

## Process

- Migrations run once per deploy from one place (a release job or init container), not on every app instance at startup
- Never edit a migration that has run anywhere shared. Add a new one
- Every migration is reviewed for locks and rewrites. Lint it: `squawk` for Postgres SQL, `strong_migrations` for Rails, `django-pg-zero-downtime-migrations` for Django
- Test on a copy of production-sized data and time it
- Prefer forward fixes over down migrations for data changes. Keep down migrations for pure schema additions
- Back up before destructive changes and know the restore time

## MySQL Notes

- InnoDB online DDL (`ALGORITHM=INPLACE, LOCK=NONE` or `ALGORITHM=INSTANT` in 8.0) covers many changes. State the algorithm so MySQL fails instead of silently copying the table
- For big tables use `gh-ost` or `pt-online-schema-change`
- Metadata locks behave like Postgres lock queues. Set `lock_wait_timeout` low for migrations

## Checklist

- [ ] Compatible with the previous app version
- [ ] Indexes built concurrently, constraints added `NOT VALID` then validated
- [ ] `lock_timeout` set
- [ ] Backfills batched, idempotent, outside the migration transaction
- [ ] Tested on production-sized data
