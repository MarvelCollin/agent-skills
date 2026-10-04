CREATE TABLE payments (
  id bigint PRIMARY KEY,
  amount float NOT NULL,
  created_at timestamp NOT NULL
);
CREATE INDEX payments_created_idx ON payments (created_at);
SELECT * FROM payments WHERE id = 1;
