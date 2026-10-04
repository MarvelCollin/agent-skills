CREATE TABLE payments (
  id bigint PRIMARY KEY,
  amount_cents bigint NOT NULL,
  created_at timestamptz NOT NULL
);
CREATE INDEX CONCURRENTLY payments_created_idx ON payments (created_at);
SELECT id, amount_cents FROM payments WHERE id = 1;
