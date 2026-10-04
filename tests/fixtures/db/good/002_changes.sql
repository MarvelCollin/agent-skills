SET lock_timeout = '5s';
ALTER TABLE orders ADD COLUMN status text;
ALTER TABLE orders ADD CONSTRAINT orders_status_not_null CHECK (status IS NOT NULL) NOT VALID;
ALTER TABLE orders VALIDATE CONSTRAINT orders_status_not_null;
CREATE INDEX CONCURRENTLY orders_status_idx ON orders (status);
UPDATE orders SET status = 'paid' WHERE id BETWEEN 1 AND 5000;
