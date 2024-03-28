
-- https://stackoverflow.com/a/31833279
CREATE DOMAIN uint AS int4
   CHECK(VALUE >= 0);

CREATE TYPE CpuVendor AS ENUM('Intel', 'AMD');
CREATE TYPE GpuVendor AS ENUM('AMD', 'Nvidia', 'Intel');


CREATE TABLE Products (
  id            UINT      PRIMARY KEY,
  price_rub     UINT      NOT NULL,
  registered_at TIMESTAMP NOT NULL DEFAULT(NOW()),
  released_at   TIMESTAMP NOT NULL
);

CREATE TABLE Monitors (
  product_id           UINT        PRIMARY KEY,
  model_line           VARCHAR(16),
  model                VARCHAR(16) NOT NULL UNIQUE,
  resolution_width_px  UINT        NOT NULL CHECK(resolution_width_px >= 1),
  resolution_height_px UINT        NOT NULL CHECK(resolution_height_px >= 1),
  diagonal_inches      FLOAT4      NOT NULL CHECK(diagonal_inches > 0),
  glossy               BOOL        NOT NULL,
  dc_dimming           BOOL        NOT NULL,

  FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE
);

CREATE TABLE Cpus (
  id                   UINT        PRIMARY KEY,
  vendor               CpuVendor   NOT NULL,
  model                VARCHAR(32) NOT NULL CHECK(model = UPPER(model)),
  cpubenchmark_pts     UINT        NOT NULL
);

CREATE TABLE Gpus (
  id          UINT        PRIMARY KEY,
  vendor      GpuVendor   NOT NULL,
  model       VARCHAR(16) NOT NULL CHECK(model = UPPER(model)),
  furmark_fps UINT        NOT NULL
);

CREATE TABLE Monoblocks (
  product_id      UINT        PRIMARY KEY,
  model_line      VARCHAR(16),
  model           VARCHAR(16) NOT NULL UNIQUE,
  monitor_part_id UINT        NOT NULL,
  cpu_id          UINT        NOT NULL,
  gpu_id          UINT        NOT NULL,
  ram_gb          UINT        NOT NULL CHECK(ram_gb > 0),

  FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE CASCADE,
  FOREIGN KEY (monitor_part_id) REFERENCES Monitors(product_id) ON DELETE RESTRICT,
  FOREIGN KEY (cpu_id) REFERENCES Cpus(id) ON DELETE RESTRICT,
  FOREIGN KEY (gpu_id) REFERENCES Gpus(id) ON DELETE RESTRICT
);

CREATE TABLE Users (
  id                   UINT          PRIMARY KEY,
  first_name           VARCHAR(32)   NOT NULL,
  last_name            VARCHAR(32)   NOT NULL,
  email                VARCHAR(128)  NOT NULL UNIQUE,
  registered_at        TIMESTAMP     NOT NULL,
  password_sha256_hash TEXT          NOT NULL,
  yandex_oauth_token   TEXT
);

CREATE TABLE Reviews (
  id         UINT      PRIMARY KEY,
  product_id UINT      NOT NULL,
  user_id    UINT      NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT(NOW()),

  FOREIGN KEY (product_id) REFERENCES Products(id) ON DELETE RESTRICT,
  FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE RESTRICT
);

CREATE TABLE ReviewRevs (
  id          UINT      PRIMARY KEY,
  review_id   UINT      NOT NULL,
  content     TEXT      NOT NULL,
  modified_at TIMESTAMP NOT NULL DEFAULT(NOW()),

  CONSTRAINT ReviewRevUq UNIQUE (review_id, modified_at),

  FOREIGN KEY (review_id) REFERENCES Reviews(id) ON DELETE CASCADE
);
