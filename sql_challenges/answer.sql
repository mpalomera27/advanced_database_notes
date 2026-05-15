-- ============================================================
-- Lesson 04 — Transactions: Answers
-- advanced_database_notes / sql_challenges
-- Branch: session-2026-04-23
-- Date: 2026-04-23
-- ============================================================


-- ============================================================
-- SETUP — Run this first
-- ============================================================

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50)  NOT NULL,
    balance      NUMBER(10,2)  NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',   1000.00);
INSERT INTO accounts VALUES (2, 'Bob',      500.00);
INSERT INTO accounts VALUES (3, 'Charlie',  250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250


-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- Transfer $50 from Charlie (3) to Alice (1)
-- ============================================================

-- Before: verify balances
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;

BEGIN
    UPDATE accounts SET balance = balance - 50 WHERE account_id = 3; -- Charlie -50
    UPDATE accounts SET balance = balance + 50 WHERE account_id = 1; -- Alice   +50
    COMMIT;
END;
/

-- After: verify balances
-- Expected: Alice=1050, Bob=500, Charlie=200
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;


-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- Attempt $10,000 transfer from Bob (2) to Charlie (3)
-- ============================================================

-- Start the transfer
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2; -- Bob
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3; -- Charlie

-- Check mid-transaction (Bob goes negative — violates CHECK constraint,
-- but if it didn't, we'd catch it here visually)
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;
-- Bob would show -9500, which is invalid. ROLLBACK.

ROLLBACK;

-- Verify balances restored
-- Expected: Alice=1050, Bob=500, Charlie=200
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;


-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- 1. Add $25 to Alice
-- 2. Savepoint
-- 3. Deduct $25 from Charlie (wrong — meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob instead
-- 6. Commit
-- ============================================================

-- Step 1: Add $25 to Alice
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;

-- Step 2: Set savepoint
SAVEPOINT before_deduct;

-- Step 3: Deduct $25 from Charlie (wrong account)
UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;

-- Verify — realise the mistake
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Step 4: Rollback to savepoint (Alice's +25 is preserved)
ROLLBACK TO SAVEPOINT before_deduct;

-- Step 5: Deduct $25 from Bob (correct account)
UPDATE accounts SET balance = balance - 25 WHERE account_id = 2;

-- Step 6: Commit everything
COMMIT;

-- Final verify
-- Expected: Alice=1075, Bob=475, Charlie=200
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;


-- ============================================================
-- EXERCISE 4: Stored procedure — deposit_funds
-- ============================================================

CREATE OR REPLACE PROCEDURE deposit_funds (
    p_account_id IN accounts.account_id%TYPE,
    p_amount     IN accounts.balance%TYPE
)
AS
BEGIN
    -- Validate: amount must be positive
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Deposit amount must be greater than zero.');
    END IF;

    -- Add amount to balance
    UPDATE accounts
    SET    balance = balance + p_amount
    WHERE  account_id = p_account_id;

    -- Raise error if account not found
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Account ID ' || p_account_id || ' not found.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE; -- re-raise the original error
END deposit_funds;
/

-- Test
EXEC deposit_funds(3, 75);

-- Verify: Charlie should now be 275
SELECT account_id, owner_name, balance
FROM   accounts
ORDER  BY account_id;


-- ============================================================
-- EXERCISE 5: Discussion answers
-- ============================================================

/*
Q1 — Patient appointment booking system:
   Steps: a) Reserve time slot, b) Create appointment record, c) Send notification

   INSIDE the transaction: a) and b)
   These two operations must be atomic — if the appointment record fails to insert,
   the time slot reservation must also roll back, and vice versa.
   A reserved slot with no appointment record (or vice versa) would leave the system
   in an inconsistent state.

   OUTSIDE the transaction: c) Send confirmation notification
   Notifications are a side effect that touches an external system (email/SMS service).
   Sending cannot be rolled back once dispatched. The correct pattern is to COMMIT
   the data first, then trigger the notification. If the notification fails, the
   booking is still valid and the notification can be retried independently.


Q2 — Stored procedure with COMMIT called inside a larger outer transaction:

   Problem: the procedure's COMMIT will permanently save ALL uncommitted work done
   so far in the outer transaction, not just the procedure's own changes.
   The developer can no longer roll back the earlier steps of their transaction.
   This breaks the "all-or-nothing" guarantee they expected.

   Best practice: stored procedures should generally NOT call COMMIT internally
   unless they are designed as top-level units of work. Let the caller control
   transaction boundaries.


Q3 — calculate_copay() function vs post_payment() procedure in a SELECT:

   calculate_copay() — YES, it can be used inside a SELECT statement.
   Functions in Oracle can be called from SQL context as long as they are
   "pure" (no DML, no transaction control). They take inputs, compute a value,
   and return it — exactly what SQL expressions expect.

   post_payment() — NO, procedures cannot be called from a SELECT statement.
   Procedures do not return a value in the SQL sense; they execute procedural
   logic (often including DML or COMMIT/ROLLBACK). Oracle SQL does not have
   a mechanism to call a procedure within a query. You call procedures with
   EXEC or from a PL/SQL block, never from SELECT.
*/