import psycopg2
from datetime import datetime
from decimal import Decimal


try:
    conn = psycopg2.connect("dbname='dbproject' user='valeriy' host='localhost' password='abacabadabacaba'")
except:
    print("Couldn't connect to the database")
    raise


def test_monoblocks_order():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
            released_at, price_rub, model_line, model
            FROM
                Products INNER JOIN Monoblocks
                ON Products.id = Monoblocks.product_id
            ORDER BY released_at DESC, price_rub DESC;
        """)
        assert set(cursor.fetchall()) == set([
            (datetime(2023, 1, 1, 0, 0), 169789, 'Inspiron', '7720-1607'),
            (datetime(2023, 1, 1, 0, 0), 150348, 'Optiplex', '7410P-7651'),
            (datetime(2023, 1, 1, 0, 0), 150348, 'Optiplex', '7410P-7658'),
            (datetime(2023, 1, 1, 0, 0), 105990, 'Optiplex', '7410-3821'),
            (datetime(2022, 1, 1, 0, 0), 189248, 'Inspiron', '5400-5838'),
            (datetime(2021, 1, 1, 0, 0), 189506, 'Optiplex', '7490-0167'),
            (datetime(2021, 1, 1, 0, 0), 137750, 'Optiplex', '7490-3411'),
            (datetime(2021, 1, 1, 0, 0), 90000, 'Inspiron', '5400-2430'),
            (datetime(2020, 1, 1, 0, 0), 210260, 'Optiplex', '5490-3381'),
            (datetime(2020, 1, 1, 0, 0), 200750, 'Optiplex', '7490-9393'),
            (datetime(2020, 1, 1, 0, 0), 119420, 'Optiplex', '7480-7007'),
            (datetime(2020, 1, 1, 0, 0), 117354, 'Optiplex', '5490-7487'),
            (datetime(2020, 1, 1, 0, 0), 114910, 'Optiplex', '7480-6994'),
            (datetime(2020, 1, 1, 0, 0), 97290, 'Optiplex', '7410-3820'),
            (datetime(2016, 1, 1, 0, 0), 55476, 'Inspiron', '3459-9725')
        ])


def test_monitors_2022():
    with conn.cursor() as cursor:
        cursor.execute("""
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
        """)
        assert set(cursor.fetchall()) == set([
            (12, 'UltraSharp', 'U3423WE', datetime(2022, 1, 1, 0, 0), 12, 12, datetime(2023, 5, 3, 13, 42, 32, 186799), 'Разъемы для подключения кабелей расположены неудобно — трудно добраться при желании поменять кабель.'),
            (13, None, 'P2422HE', datetime(2022, 1, 1, 0, 0), 13, 13, datetime(2023, 5, 3, 13, 43, 32, 186799), 'Неприятный запах пластика при первом включении монитора — требуется продолжительная вытяжка.'),
            (15, None, 'G2722HS', datetime(2022, 1, 1, 0, 0), 15, 15, datetime(2023, 5, 3, 13, 45, 32, 186799), 'Монитор греется слишком сильно при длительном использовании, что вызывает беспокойство о его надежности.')
        ])


def test_monitors_last_year_avg_price():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
                date_part('year', released_at) AS year,
                ROUND(AVG(price_rub)) AS avg_price_rub
            FROM Products
            GROUP BY date_part('year', released_at)
            ORDER BY year DESC;
        """)
        assert set(cursor.fetchall()) == set([
            (2023.0, Decimal('129095')),
            (2022.0, Decimal('89627')),
            (2021.0, Decimal('139085')),
            (2020.0, Decimal('143331')),
            (2018.0, Decimal('42528')),
            (2017.0, Decimal('31234')),
            (2016.0, Decimal('70937')),
            (2014.0, Decimal('24640')),
            (2006.0, Decimal('6300'))
        ])


def test_products_without_reviews():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT id FROM Products
            EXCEPT
            SELECT product_id AS id FROM Reviews;
        """)
        assert set(cursor.fetchall()) == set([(8,), (23,)])


def test_last_10_reviews():
    with conn.cursor() as cursor:
        cursor.execute("""
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
        """)
        assert set(cursor.fetchall()) == set([
            (30, 30, 15, datetime(2023, 5, 3, 14, 0, 32, 186799), 'Этот моноблок — настоящая находка! Мощный процессор и прекрасный дисплей.'),
            (29, 29, 14, datetime(2023, 5, 3, 13, 59, 32, 186799), 'Огромное пространство на жестком диске позволяет сохранить множество файлов и документов без проблем.'), 
            (28, 28, 13, datetime(2023, 5, 3, 13, 58, 32, 186799), 'Звук из встроенных динамиков низкого качества — необходимо использовать внешние акустические системы.'), 
            (27, 27, 12, datetime(2023, 5, 3, 13, 57, 32, 186799), 'Экран имеет ограниченный угол обзора, что затрудняет комфортное просмотр видео и изображений.'),
            (26, 26, 11, datetime(2023, 5, 3, 13, 56, 32, 186799), 'Разъемы и порты расположены неудобно, это затрудняет доступ к ним при подключении дополнительных устройств.'), 
            (25, 25, 10, datetime(2023, 5, 3, 13, 55, 32, 186799), 'Определенные модели моноблоков имеют проблемы с соединением Wi-Fi, что влияет на скорость работы онлайн-приложений.'),
            (24, 24, 9, datetime(2023, 5, 3, 13, 54, 32, 186799), 'Моноблок компактный и занимает минимум места, идеально подходит для маленьких рабочих пространств.'),
            (22, 22, 7, datetime(2023, 5, 3, 13, 52, 32, 186799), 'Стильный и интуитивно понятный интерфейс операционной системы делает использование моноблока максимально комфортным.'),
            (21, 21, 6, datetime(2023, 5, 3, 13, 51, 32, 186799), 'Недостаточное уровень гарантии и непрофессиональная поддержка со стороны производителя в случае возникновения проблем.'),
            (20, 20, 5, datetime(2023, 5, 3, 13, 50, 32, 186799), 'Громоздкий блок питания, который занимает слишком много места на столе.')
        ])


def test_reviews_per_product():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
                id AS product_id,
                (SELECT COUNT(*) 
                FROM Reviews WHERE product_id = Products.id) AS num_reviews
            FROM Products
            ORDER BY num_reviews ASC;
        """)
        assert set(cursor.fetchall()) == set([
            (23, 0), (8, 0), (3, 1), (4, 1), (5, 1), (6, 1),
            (7, 1), (9, 1), (10, 1), (11, 1), (12, 1), (13, 1),
            (14, 1), (15, 1), (16, 1), (17, 1), (18, 1), (19, 1),
            (20, 1), (21, 1), (22, 1), (24, 1), (25, 1), (26, 1),
            (27, 1), (28, 1), (29, 1), (1, 1), (30, 1), (2, 1)
        ])


def test_client_reviews():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
                Users.id AS user_id,
                Users.first_name AS first_name,
                Users.last_name AS last_name,
                Users.email AS email,
                (SELECT COUNT(*) FROM Reviews WHERE user_id = Users.id) AS num_reviews
            FROM Users
            ORDER BY num_reviews DESC;
        """)
        assert set(cursor.fetchall()) == set([
            (1, 'Alexander', 'Pushkin', 'pushkin.as@phystech.edu', 2),
            (2, 'Lev', 'Tolstoy', 'tolstoy.ln@phystech.edu', 2),
            (3, 'Pavel', 'Lebedev', 'lebedev.pi@phystech.edu', 2), 
            (4, 'Natalia', 'Solovyova', 'solovyova.np@phystech.edu', 2),
            (5, 'Maxim', 'Zhukov', 'zhukov.ma@phystech.edu', 2),
            (6, 'Andrey', 'Belov', 'belov.as@phystech.edu', 2),
            (7, 'Yulia', 'Morozova', 'morozova.yn@phystech.edu', 2), 
            (9, 'Alexandra', 'Petrova', 'petrova.ad@phystech.edu', 2),
            (10, 'Olga', 'Nikitina', 'nikitina.oa@phystech.edu', 2), 
            (11, 'Ekaterina', 'Kozlova', 'kozlova.ev@phystech.edu', 2),
            (12, 'Victoria', 'Ivanova', 'ivanova.va@phystech.edu', 2),
            (13, 'Ivan', 'Ivanov', 'ivanov.im@phystech.edu', 2),
            (14, 'Sergey', 'Kuznetsov', 'kuznetsov.syu@phystech.edu', 2),
            (15, 'Dmitry', 'Smirnov', 'smirnov.dv@phystech.edu', 2)
        ])


def test_monoblocks_selected_processor():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
            *
            FROM Monoblocks
            WHERE cpu_id = (SELECT id FROM Cpus WHERE vendor = 'Intel' AND model = 'I7-13700')
            ;
        """)
        assert set(cursor.fetchall()) == set([
            (22, 'Optiplex', '7410P-7651', 7, 6, 6, 16),
            (26, 'Optiplex', '7410P-7658', 11, 6, 6, 16)
        ])


def test_cpu_benchmark_pts():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
                product_id,
                model_line,
                model,
                (SELECT cpubenchmark_pts FROM Cpus WHERE id = Monoblocks.cpu_id),
                (SELECT furmark_fps FROM Gpus WHERE id = Monoblocks.gpu_id)
            FROM Monoblocks;
        """)
        assert set(cursor.fetchall()) == set([
            (16, 'Inspiron', '5400-5838', 9842, 25),
            (17, 'Optiplex', '5490-7487', 10049, 13),
            (18, 'Optiplex', '7490-9393', 16469, 61),
            (19, 'Optiplex', '7410-3820', 13240, 11),
            (20, 'Inspiron', '3459-9725', 2636, 9),
            (21, 'Optiplex', '7490-3411', 16469, 13),
            (22, 'Optiplex', '7410P-7651', 37799, 14),
            (23, 'Optiplex', '7490-0167', 12235, 13),
            (24, 'Optiplex', '5490-3381', 10049, 13),
            (25, 'Optiplex', '7410-3821', 13240, 14),
            (26, 'Optiplex', '7410P-7658', 37799, 14),
            (27, 'Optiplex', '7480-7007', 16469, 61),
            (28, 'Inspiron', '7720-1607', 15257, 25),
            (29, 'Inspiron', '5400-2430', 9842, 25),
            (30, 'Optiplex', '7480-6994', 16469, 61)
        ])


def test_user_reviews():
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT
            *
            FROM Reviews
            WHERE user_id = (
                SELECT id FROM Users WHERE email = 'pushkin.as@phystech.edu'
            );
        """)
        assert set(cursor.fetchall()) == set([
            (1, 1, 1, datetime(2023, 5, 3, 13, 31, 32, 186799)),
            (16, 16, 1, datetime(2023, 5, 3, 13, 46, 32, 186799))
        ])
