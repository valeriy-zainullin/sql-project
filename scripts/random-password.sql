CREATE EXTENSION pgcrypto;

WITH
  password(value) AS (SELECT random()::text AS value)
SELECT password.value, digest(password.value, 'sha256') from password;