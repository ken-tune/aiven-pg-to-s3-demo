CREATE EXTENSION aiven_extras CASCADE;
SELECT * FROM aiven_extras.pg_create_publication_for_all_tables('products_publication','INSERT,UPDATE,DELETE');

CREATE SCHEMA IF NOT EXISTS demo;

CREATE TABLE IF NOT EXISTS demo.products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS demo.heartbeat(
    id SERIAL PRIMARY KEY,
    status VARCHAR(20)
);
