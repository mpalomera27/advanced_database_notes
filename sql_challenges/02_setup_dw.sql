-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- File: 02_setup_dw.sql
-- Purpose: Create star schema tables for the data warehouse
--
-- Self-contained — run after 01_setup_oltp.sql.
-- Run this on https://freesql.com/
-- ============================================================

-- Clean up if re-running (child before parent)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_task_daily';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_status';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_date';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_user';         EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- DIM_USER — user attributes (denormalized)
-- Surrogate key separates DW from source system.
-- user_id references the source users.id — but the DW does
-- NOT use a foreign key: if the source changes, the DW keeps
-- the historical snapshot intact.
-- ============================================================
CREATE TABLE dim_user (
    user_key    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     NUMBER        NOT NULL,  -- source system ID
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  NOT NULL,
    CONSTRAINT uq_dim_user_source UNIQUE (user_id)
);

-- ============================================================
-- DIM_DATE — calendar hierarchy
-- Pre-computing year, quarter, month, day_name, is_weekend
-- here means reporting queries never need to call TO_CHAR
-- or EXTRACT — they just filter on integer columns.
-- ============================================================
CREATE TABLE dim_date (
    date_key    NUMBER       PRIMARY KEY,  -- integer: YYYYMMDD
    full_date   DATE         NOT NULL,
    year        NUMBER(4)    NOT NULL,
    quarter     NUMBER(1)    NOT NULL,
    month       NUMBER(2)    NOT NULL,
    month_name  VARCHAR2(10) NOT NULL,
    day         NUMBER(2)    NOT NULL,
    day_name    VARCHAR2(10) NOT NULL,
    is_weekend  NUMBER(1)    NOT NULL,  -- 1 = Saturday/Sunday, 0 = weekday
    CONSTRAINT uq_dim_date UNIQUE (full_date)
);

-- ============================================================
-- DIM_STATUS — task status categories
-- Small dimension table. Separating it enables grouping by
-- category (active vs done vs cancelled) without CASE logic
-- scattered across every report query.
-- ============================================================
CREATE TABLE dim_status (
    status_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name VARCHAR2(20) NOT NULL,
    category    VARCHAR2(20) NOT NULL,  -- 'active', 'done', 'cancelled'
    CONSTRAINT uq_dim_status UNIQUE (status_name)
);

-- Seed the status dimension (these values never change)
INSERT INTO dim_status (status_name, category) VALUES ('open',        'active');
INSERT INTO dim_status (status_name, category) VALUES ('in_progress', 'active');
INSERT INTO dim_status (status_name, category) VALUES ('blocked',     'active');
INSERT INTO dim_status (status_name, category) VALUES ('completed',   'done');
INSERT INTO dim_status (status_name, category) VALUES ('cancelled',   'cancelled');
COMMIT;

-- ============================================================
-- FACT_TASK_DAILY — daily task metrics (the grain)
-- One row per (date, user, status, priority) combination.
--
-- user_key reflects the HISTORICAL assignee from task_assignments,
-- NOT the current assigned_to column.
-- - tasks_created credit goes to the assignee at created_at
-- - tasks_completed credit goes to the assignee at completed_at
-- This distinction only matters for reassigned tasks,
-- but it ensures the DW answers "who did the work?" correctly.
-- ============================================================
CREATE TABLE fact_task_daily (
    fact_key             NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key             NUMBER       NOT NULL REFERENCES dim_date(date_key),
    user_key             NUMBER       NOT NULL REFERENCES dim_user(user_key),
    status_key           NUMBER       NOT NULL REFERENCES dim_status(status_key),
    priority             VARCHAR2(10) NOT NULL,
    tasks_created        NUMBER       DEFAULT 0,
    tasks_completed      NUMBER       DEFAULT 0,
    avg_completion_hours NUMBER       DEFAULT NULL,
    CONSTRAINT uq_fact UNIQUE (date_key, user_key, status_key, priority)
);

-- Verify (dim_date and fact will be empty until ETL runs)
SELECT 'dim_user: '   || COUNT(*) AS table_count FROM dim_user
UNION ALL
SELECT 'dim_status: ' || COUNT(*) AS table_count FROM dim_status
UNION ALL
SELECT 'dim_date: '   || COUNT(*) AS table_count FROM dim_date
UNION ALL
SELECT 'fact_task_daily: ' || COUNT(*) AS table_count FROM fact_task_daily;
