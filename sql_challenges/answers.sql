-- ============================================================
-- Lesson 03 — Indexes: Answers
-- advanced_database_notes / sql_challenges
-- Branch: session-2026-04-16
-- Date: 2026-04-16
-- ============================================================


-- ============================================================
-- SETUP — Run this first
-- ============================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE patient_visits';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE patient_visits (
    visit_id     NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id   NUMBER         NOT NULL,
    site_id      NUMBER         NOT NULL,
    visit_date   DATE           NOT NULL,
    status       VARCHAR2(20)   NOT NULL,
    diagnosis    VARCHAR2(100),
    amount_usd   NUMBER(10,2)
);

INSERT INTO patient_visits (patient_id, site_id, visit_date, status, diagnosis, amount_usd)
SELECT
    TRUNC(DBMS_RANDOM.VALUE(1, 10001))          AS patient_id,
    TRUNC(DBMS_RANDOM.VALUE(1, 6))              AS site_id,
    SYSDATE - TRUNC(DBMS_RANDOM.VALUE(0, 730)) AS visit_date,
    CASE TRUNC(DBMS_RANDOM.VALUE(1, 4))
        WHEN 1 THEN 'scheduled'
        WHEN 2 THEN 'completed'
        ELSE        'cancelled'
    END                                         AS status,
    CASE TRUNC(DBMS_RANDOM.VALUE(1, 6))
        WHEN 1 THEN 'Hypertension'
        WHEN 2 THEN 'Diabetes'
        WHEN 3 THEN 'Routine checkup'
        WHEN 4 THEN 'Fracture'
        ELSE        'Respiratory infection'
    END                                         AS diagnosis,
    ROUND(DBMS_RANDOM.VALUE(50, 500), 2)        AS amount_usd
FROM dual
CONNECT BY LEVEL <= 100000;

COMMIT;

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'PATIENT_VISITS',
        cascade => TRUE
    );
END;
/


-- ============================================================
-- EXERCISE 1 — Find the slow query
-- ============================================================

EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE site_id = 3;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
  ANSWERS:
  a) Scan type: TABLE ACCESS FULL
     Oracle reads every block in the table because no index exists on site_id.

  b) site_id cardinality: LOW — only 5 distinct values (1–5).
     Each value matches ~20,000 rows (~20% of the table).

  c) Would an index on site_id help? NO.
     Returning ~20k rows via random I/O (one index lookup per row) is MORE
     expensive than a single sequential full scan. Oracle would ignore the
     index even if it existed. Indexes are beneficial when the query returns
     roughly less than 5–10% of rows (high selectivity).
*/


-- ============================================================
-- EXERCISE 2 — Create an index and see if it helps
-- ============================================================

-- Step 1: Create the index on visit_date
CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3a: Range query — last 30 days
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Step 3b: Range query — last 7 days (more selective)
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 7 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Step 3c: Range query — last 700 days (almost full table)
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 700 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
  ANSWERS:
  a) Last 30 days (~4% of rows): Oracle USES the index — INDEX RANGE SCAN.
     Selective enough that random I/O is cheaper than a full scan.

  b) Last 7 days (~1% of rows): Oracle USES the index — even more aggressively.
     Very few rows returned, index navigation is clearly the cheapest path.

  c) Last 700 days (~95% of rows): Oracle IGNORES the index — TABLE ACCESS FULL.
     Reading 95k rows via random I/O is far more expensive than one sequential
     full scan. The optimizer switches back to full scan automatically.

  d) Why does range size matter?
     The Cost-Based Optimizer (CBO) estimates the number of rows the predicate
     will return using column statistics. Each row fetched via index requires
     one random I/O (index lookup + table row fetch). For small ranges this
     is fast; for large ranges, sequential I/O of a full scan wins.
     The crossover point is typically around 5–15% of table rows.
*/


-- ============================================================
-- EXERCISE 3 — Composite index
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Both columns — optimal use of the composite index
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Leading column only — index CAN be used
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 1234;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Trailing column only — index CANNOT be used from the middle
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
  ANSWERS:
  a) Both columns: YES — INDEX RANGE SCAN on idx_pv_patient_date.
     Oracle enters the B-Tree on patient_id=1234, then scans only the
     visit_date sub-range within that patient. Very efficient.

  b) Trailing column only (visit_date, no patient_id): NO.
     The composite index is sorted first by patient_id, then by visit_date
     within each patient. Without anchoring on patient_id there is no entry
     point into the tree — Oracle cannot jump to the middle of the index.
     Result: TABLE ACCESS FULL.

  c) Column order rule for composite indexes:
     - Put the EQUALITY column first (patient_id = value).
     - Put the RANGE column second (visit_date > value).
     This maximises the contiguous range Oracle can scan in the index.
     A leading column alone can always use the index; a trailing column
     alone cannot.
*/


-- ============================================================
-- EXERCISE 4 — Function that breaks an index
-- ============================================================

-- This query CAN use the index on patient_id
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 5432;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This query CANNOT — function applied to the indexed column
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
  ANSWERS:
  a) Second query scan type: TABLE ACCESS FULL.
     Oracle cannot use the index on patient_id because the column value
     is transformed before comparison.

  b) Why does wrapping a column in a function break index use?
     The B-Tree index stores raw column values (NUMBER in this case).
     TO_CHAR(patient_id) produces a VARCHAR2 result that does not exist
     in the index. To find matching rows Oracle would have to evaluate the
     function on every row — at that point a full scan is equivalent and
     simpler for the optimizer.

  c) Rewrite to allow index use:
     -- Option 1: cast the literal, not the column
     SELECT * FROM patient_visits WHERE patient_id = TO_NUMBER('5432');

     -- Option 2: use a numeric literal directly (best)
     SELECT * FROM patient_visits WHERE patient_id = 5432;

     -- Option 3: if you MUST filter by function, create a function-based index
     CREATE INDEX idx_pv_patient_char ON patient_visits(TO_CHAR(patient_id));
     -- Then the query WHERE TO_CHAR(patient_id) = '5432' can use it.

  Golden rule: never apply a function to an indexed column in the WHERE clause.
  Apply the function to the comparison value instead.
*/


-- ============================================================
-- EXERCISE 5 — Discussion: real-world scenarios
-- ============================================================

/*
  SCENARIO A — Reporting table, 50M rows, batch ETL nightly, range queries by date
  ---------------------------------------------------------------------------------
  a) Add an index? YES — on the date column.
  b) Column(s): visit_date (or equivalent date column).
  c) Concerns:
     - Each nightly INSERT updates the index, slowing the ETL.
     - Solution: disable the index before the bulk load and rebuild after:
         ALTER INDEX idx_report_date UNUSABLE;
         -- run ETL inserts here
         ALTER INDEX idx_report_date REBUILD;
     - Consider a range-partitioned table on date + local index for even
       better pruning on large datasets.


  SCENARIO B — OLTP orders, 10k inserts/min, lookups by customer_id or order_status
  -----------------------------------------------------------------------------------
  a) Add indexes? YES on customer_id, MAYBE on order_status.
  b) Columns:
     - CREATE INDEX idx_orders_customer ON orders(customer_id);
       High cardinality — very selective, index pays off immediately.
     - order_status (4 values): do NOT add a standard B-Tree index.
       Low cardinality means ~25% of rows per value — full scan is cheaper.
       Bitmap indexes work for low-cardinality columns but cause lock
       contention under heavy writes — avoid on OLTP tables.
  c) Concerns:
     - 10k inserts/min means every index adds write overhead.
     - Keep indexes to the minimum necessary. Monitor with AWR/ADDM.


  SCENARIO C — Patients table, 5M rows, frequent lookup by unique email
  ----------------------------------------------------------------------
  a) Add an index? YES — this is the ideal case for an index.
  b) Column(s): email
  c) Best index type: UNIQUE index.
     CREATE UNIQUE INDEX idx_patient_email ON patients(email);
     Advantages:
     - Enforces uniqueness at the database level (data integrity).
     - Lookup returns at most 1 row — Oracle uses INDEX UNIQUE SCAN,
       the fastest possible access path (O(log n) → single row).
     - Add NOT NULL constraint on email so every row is indexed.
*/


-- ============================================================
-- CLEANUP
-- ============================================================

DROP INDEX idx_pv_visit_date;
DROP INDEX idx_pv_patient_date;
-- DROP INDEX idx_pv_patient_char; -- only if created in Exercise 4 option 3