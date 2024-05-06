-- https://stackoverflow.com/a/3972983
CREATE OR REPLACE FUNCTION GEN_RANDOM_STRING(length INT)
RETURNS TEXT AS
$$
DECLARE
  chars TEXT[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
  result TEXT := '';
  i INT := 0;
begin
  IF length < 0 THEN
    RAISE EXCEPTION 'Length cannot be less than 0';
  end IF;
  FOR i in 1..length LOOP
    -- RANDOM выдает число от 0 до 1, умножаем на длину массива-1,
    --   получаем индекс в 0 индексации. Нужно именно умножать
    --   на длину массива -1, т.к. иначе отрезком значений будет
    --   [0; len], а нам бы [0, len - 1].
    -- Дальше добавляем единицу.
    result := result || chars[1+RANDOM()*(ARRAY_LENGTH(chars, 1)-1)];
  END LOOP;
  RETURN result;
end;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION SHA256_HASH(str TEXT)
RETURNS TEXT
LANGUAGE SQL
AS
$$
    SELECT
        SUBSTRING(CAST(DIGEST(str, 'sha256') AS TEXT) FROM 3) AS hash
$$;
SELECT SHA256_HASH('123');

-- Создание случайного пароля, например, при восстановлении
--   аккаунта. Дальше его можно выслать по электронной почте.
CREATE OR REPLACE FUNCTION GEN_RANDOM_PASSWORD()
RETURNS TABLE (password TEXT, hash TEXT)
LANGUAGE SQL
AS $$
    WITH
        password(value) AS (SELECT GEN_RANDOM_STRING(8) AS value)
    SELECT
        password.value AS password,
        SHA256_HASH(password.value) AS hash
    FROM password
$$;
SELECT GEN_RANDOM_PASSWORD();

CREATE OR REPLACE FUNCTION TRY_LOGIN(_email TEXT, _password TEXT)
RETURNS TABLE (userid INT)
LANGUAGE SQL
AS $$
    SELECT id as userid
    FROM Users
    WHERE
        Users.email = _email AND
        LOWER(Users.password_sha256_hash) = LOWER(SHA256_HASH(_password))
    LIMIT 1
$$;
SELECT *
FROM
    TRY_LOGIN('zainullin.vv@phystech.edu', 'DJ9E7QnB');
SELECT *
FROM
    TRY_LOGIN('zainullin.vv@phystech.edu', 'Yo?');

-- Отметить пользователя как бота. Его отзывы не объективны.
--   Могут быть проплачены конкурентами. Тяжелая жизнь бизнеса,
--   кому как вам об этом не знать)
-- Пока удаляет пользователя и его отзывы. В будущем может просто
--   деактивировать аккаунт, помечать отзывы как проплаченые. 
-- Нужна отдельная функция, потому что в будущем в таблицу
--   может быть добавлен функционал активации и деактивации
--   пользователей. Тогда можно будет добавить и поле последнего
--   логина и деактивировать пользователей, которых долго не было
--   на сайте. Активация только после восстановления пароля.
--   Защищает от утечек паролей и т.п.
-- Выводит все удаленные строки.
CREATE OR REPLACE PROCEDURE MARK_USER_AS_BOT(_email TEXT)
LANGUAGE SQL
AS $$
    DELETE FROM Reviews
    WHERE user_id = (
        SELECT id
        FROM Users
        WHERE email = _email
    );
    DELETE FROM Users WHERE email = _email;
$$;
SELECT COUNT(*) FROM Users;
CALL MARK_USER_AS_BOT('zainullin.vv@phystech.edu');
SELECT COUNT(*) FROM Users;
