-- Выдать моноблоки по дате выпуска, сначала самые новые.
--   Запрос построен так, чтобы отобразить на сайте
---  самые последние модели в начале выдачи, а среди
--   одинаковых по дате выпуска сначала самые дорогие.
SELECT
released_at, price_rub, model_line, model
FROM
    Products INNER JOIN Monoblocks
    ON Products.id = Monoblocks.product_id
ORDER BY released_at DESC, price_rub DESC;

-- Клиент попросил выдать все мониторы
--   2022 года, сказал, что будет
--   выбирать по отзывам.
-- Выберем ему все отзывы на мониторы,
--   для каждого отзыва последнюю ревизию.
WITH
    Products_2022(id, released_at) AS (
        SELECT
           id,
           released_at
        FROM Products
        WHERE
            date_part('year', released_at) = 2022
    ),
    Monitors_2022(product_id, model_line, model, released_at) AS (
        SELECT
            Products_2022.id AS product_id,
            Monitors.model_line AS model_line,
            Monitors.model AS model,
            Products_2022.released_at AS released_at
        FROM
            Monitors INNER JOIN Products_2022
            ON Monitors.product_id = Products_2022.id
    ),
    LastReviews(id, product_id, user_id, created_at, content) AS (
        SELECT
            Reviews.id AS review_id,
            Reviews.product_id AS product_id,
            Reviews.user_id AS user_id,
            Reviews.created_at AS created_at,
            ReviewRevs.content AS content 
        FROM
            Reviews LEFT JOIN ReviewRevs
            ON
                ReviewRevs.review_id = Reviews.id AND
                ReviewRevs.modified_at = (SELECT MAX(modified_at) FROM ReviewRevs WHERE review_id = Reviews.id)
    )
SELECT
    Monitors_2022.product_id AS product_id,
    Monitors_2022.model_line AS model_line,
    Monitors_2022.model AS model,
    Monitors_2022.released_at AS released_at,
    LastReviews.id AS review_id,
    LastReviews.user_id AS user_id,
    LastReviews.created_at AS created_at,
    LastReviews.content AS content
FROM
    Monitors_2022 INNER JOIN LastReviews
    ON Monitors_2022.product_id = LastReviews.product_id
;

-- Посчитаем среднюю цену продукта в каждый год.
--   Отчет для реководителей, в каком
--   ценовом сегменте наши продукты.
SELECT
    date_part('year', released_at) AS year,
    ROUND(AVG(price_rub)) AS avg_price_rub
FROM Products
GROUP BY date_part('year', released_at)
ORDER BY year DESC;

-- Найдем продукты, у которых нет отзывов.
--   Продукты без отзывов покупаются с
--   меньшей вероятностью.
-- У нас на все продукты есть отзывы,
--   потому результат быть пустым.
SELECT id FROM Products
EXCEPT
SELECT product_id AS id FROM Reviews;

-- Показать последние 10 отзывов для команды
--   QA (quality assurance). Они должны
--   собрать информацию о недостатках,
--   достоинствах и пожеланиях клиентов.
-- По каждому отзыву нужна последняя ревизия.
WITH
    NewReviews(id, product_id, user_id, created_at) AS (
        SELECT * FROM Reviews ORDER BY created_at DESC LIMIT 10
    )
SELECT
    NewReviews.id AS review_id,
    NewReviews.product_id AS product_id,
    NewReviews.user_id AS user_id,
    NewReviews.created_at AS created_at,
    ReviewRevs.content AS content 
FROM
    NewReviews LEFT JOIN ReviewRevs
    ON
        ReviewRevs.review_id = NewReviews.id AND
        ReviewRevs.modified_at = (SELECT MAX(modified_at) FROM ReviewRevs WHERE review_id = NewReviews.id)
;

-- Оценим количество отзывов для каждого
--   продукта. В каком-то смысле, чем больше
--   отзывов, тем выше популярность.
-- Находим самый непопулярный продукт, изучаем,
--   почему недостаточно привлекателен.
SELECT
    id AS product_id,
    (SELECT COUNT(*) FROM Reviews WHERE product_id = Products.id) AS num_reviews
FROM Products
ORDER BY num_reviews ASC;

-- Для каждого клиента выясним, сколько
--   он оставил отзывов.
--   Можно понимать, чье мнение
--   больше всего отображают отзывы.
SELECT
    Users.id AS user_id,
    Users.first_name AS first_name,
    Users.last_name AS last_name,
    Users.email AS email,
    (SELECT COUNT(*) FROM Reviews WHERE user_id = Users.id) AS num_reviews
FROM Users
ORDER BY num_reviews DESC;

-- Зашел пользователь на сайт
--   производителя, фильтрует
--   моноблоки по процессору
--   I7-13700 от Intel.
-- Выдаем такие моноблоки.
-- Подзапрос вернет одну строку,
--   если она естЬ, поскольку
--   пары (vendor, model) уникальны
--   в каждой строке по схеме таблицы.
SELECT
*
FROM Monoblocks
WHERE cpu_id = (SELECT id FROM Cpus WHERE vendor = 'Intel' AND model = 'I7-13700')
;

-- Для каждого моноблока выдать, сколько набирает
--   его процессор в cpubenchmark, его видеокарта
--   в furmark.
SELECT
    product_id,
    model_line,
    model,
    (SELECT cpubenchmark_pts FROM Cpus WHERE id = Monoblocks.cpu_id),
    (SELECT furmark_fps FROM Gpus WHERE id = Monoblocks.gpu_id)
FROM Monoblocks;

-- Во фронтенде нужно показать все отзывы заданного пользователя.
-- Покажем, какой запрос это сделает.
SELECT
*
FROM Reviews
WHERE user_id = (
    SELECT id FROM Users WHERE email = 'pushkin.as@phystech.edu'
);
