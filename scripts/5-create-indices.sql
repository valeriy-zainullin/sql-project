-- Индексы нужны на вторичные столбцы, primary key
--   должен быстро искаться. Мне так кажется..
--   Он же используется для построения структуры
---  хранения.

-- Самая частая операция -- получить отзывы на товар.
CREATE INDEX ON Reviews(product_id);

-- Бывает нужно находить ревизии отзывов по отзыву.
CREATE INDEX ON ReviewRevs(review_id);

-- Может быть нужно искать отзывы по пользователю,
--   какое мнение у него о товарах.
CREATE INDEX ON Reviews(user_id);
