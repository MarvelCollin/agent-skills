CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  country char(2),
  created_at timestamp NOT NULL
);

CREATE TABLE orders (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id uuid NOT NULL REFERENCES customers (id),
  total_price double precision NOT NULL,
  meta json
);

CREATE TABLE order_events (
  order_id bigint NOT NULL,
  kind text NOT NULL
);

CREATE INDEX orders_id_idx ON orders (id);
