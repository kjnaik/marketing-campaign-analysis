-- Creates the database and the normalized schema.
-- Re-running this file rebuilds all tables from scratch.
CREATE DATABASE IF NOT EXISTS marketing_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE marketing_db;

-- Drop child tables first because of the foreign keys
DROP TABLE IF EXISTS customer_segments;
DROP TABLE IF EXISTS campaign_responses;
DROP TABLE IF EXISTS channel_activity;
DROP TABLE IF EXISTS spending;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id     INT UNSIGNED      NOT NULL,
    year_birth      SMALLINT UNSIGNED NOT NULL,
    age             TINYINT UNSIGNED  NOT NULL,
    age_band        VARCHAR(10),
    education       VARCHAR(30)       NOT NULL,
    marital_status  VARCHAR(20)       NOT NULL,
    country         VARCHAR(30)       NOT NULL,
    income          DECIMAL(10,2)     NOT NULL,
    income_band     VARCHAR(12),
    kidhome         TINYINT UNSIGNED  NOT NULL,
    teenhome        TINYINT UNSIGNED  NOT NULL,
    children        TINYINT UNSIGNED  NOT NULL,
    dt_customer     DATE              NOT NULL,
    tenure_days     SMALLINT UNSIGNED NOT NULL,
    recency         SMALLINT UNSIGNED NOT NULL,
    complain        TINYINT(1)        NOT NULL,
    PRIMARY KEY (customer_id),
    KEY idx_country (country),
    KEY idx_education (education),
    KEY idx_marital (marital_status)
) ENGINE=InnoDB;

CREATE TABLE spending (
    customer_id        INT UNSIGNED NOT NULL,
    mnt_wines          INT UNSIGNED NOT NULL,
    mnt_fruits         INT UNSIGNED NOT NULL,
    mnt_meat_products  INT UNSIGNED NOT NULL,
    mnt_fish_products  INT UNSIGNED NOT NULL,
    mnt_sweet_products INT UNSIGNED NOT NULL,
    mnt_gold_prods     INT UNSIGNED NOT NULL,
    total_spend        INT UNSIGNED NOT NULL,
    PRIMARY KEY (customer_id),
    CONSTRAINT fk_spending_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE channel_activity (
    customer_id             INT UNSIGNED NOT NULL,
    num_deals_purchases     SMALLINT UNSIGNED NOT NULL,
    num_web_purchases       SMALLINT UNSIGNED NOT NULL,
    num_catalog_purchases   SMALLINT UNSIGNED NOT NULL,
    num_store_purchases     SMALLINT UNSIGNED NOT NULL,
    num_web_visits_month    SMALLINT UNSIGNED NOT NULL,
    total_purchases         SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (customer_id),
    CONSTRAINT fk_channel_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE campaign_responses (
    customer_id         INT UNSIGNED NOT NULL,
    accepted_cmp1       TINYINT(1) NOT NULL,
    accepted_cmp2       TINYINT(1) NOT NULL,
    accepted_cmp3       TINYINT(1) NOT NULL,
    accepted_cmp4       TINYINT(1) NOT NULL,
    accepted_cmp5       TINYINT(1) NOT NULL,
    response            TINYINT(1) NOT NULL,
    campaigns_accepted  TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (customer_id),
    KEY idx_response (response),
    CONSTRAINT fk_campaign_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE customer_segments (
    customer_id               INT UNSIGNED NOT NULL,
    seg_high_income           TINYINT(1) NOT NULL,
    seg_young_customer        TINYINT(1) NOT NULL,
    seg_campaign_responder    TINYINT(1) NOT NULL,
    seg_high_web_engagement   TINYINT(1) NOT NULL,
    seg_family_customer       TINYINT(1) NOT NULL,
    seg_high_spender          TINYINT(1) NOT NULL,
    seg_underserved           TINYINT(1) NOT NULL,
    PRIMARY KEY (customer_id),
    CONSTRAINT fk_segments_customer FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;