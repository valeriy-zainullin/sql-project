CREATE OR REPLACE VIEW Products_2022 AS (
    SELECT *
    FROM Products
    WHERE
        date_part('year', released_at) = 2022
);

SELECT * FROM Products_2022;

CREATE OR REPLACE VIEW Products_MostPopular AS (
    SELECT
        *,
        (
            SELECT COUNT(*)
            FROM Reviews
            WHERE
                product_id = Products.id
        ) AS num_reviews
    FROM Products
    ORDER BY num_reviews DESC
);

SELECT * FROM Products_MostPopular;

