# Просто по 30 строк в каждую из таблиц.
# В Products по 60 строк, т.к. на
#   каждый монитор и моноблок нужно
#   по строчке в таблице продуктов.

-- COPY statement is specific to PostgreSQL!
--   https://www.postgresqltutorial.com/postgresql-tutorial/import-csv-file-into-posgresql-table/
--   https://www.postgresql.org/docs/current/sql-copy.html

COPY Products(id, price_rub, registered_at, released_at)
FROM '2-data-products.csv'
DELIMITER ','
CSV HEADER;



Products

-- Monitors

-- Cpus

-- Gpus

-- Monoblocks

-- Users

-- Reviews

-- ReviewRevs
