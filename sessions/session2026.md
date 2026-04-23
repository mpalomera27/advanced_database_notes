# Session – 2026-04-23

## Topics covered
- Transaction fundamentals: what a transaction is and why atomicity matters
- COMMIT: permanently saving all changes made since the last commit
- ROLLBACK: undoing all uncommitted changes back to the last commit point
- SAVEPOINT: creating named checkpoints inside a transaction for partial rollback
- The CHECK constraint as a passive guard vs transactions as an active control flow
- Stored procedures with transaction control: COMMIT on success, ROLLBACK + re-raise on error
- Transaction boundary ownership: who should call COMMIT — the procedure or the caller?
- Functions vs procedures in SQL context: why functions can appear in SELECT but procedures cannot

## What I understood
- A transaction groups multiple DML statements (INSERT, UPDATE, DELETE) into a single atomic unit — either all succeed or none do
- ROLLBACK TO SAVEPOINT lets you undo only part of a transaction while keeping earlier changes intact; useful when one step in a multi-step flow fails and the rest are still valid
- Stored procedures should validate inputs first, then execute DML, then COMMIT — and ROLLBACK + re-raise in the EXCEPTION block so the caller knows something went wrong
- Putting COMMIT inside a procedure that gets called from a larger transaction is dangerous: it permanently saves the outer transaction's work too, removing the caller's ability to roll back
- Functions return a value and can be used in SQL expressions (SELECT, WHERE); procedures execute logic and can only be called from PL/SQL blocks or with EXEC — never from a query

## What is still confusing
- At what point does Oracle automatically roll back vs requiring an explicit ROLLBACK from the developer?
- How transaction isolation levels (READ COMMITTED, SERIALIZABLE) affect what one session can see while another has uncommitted changes
- Whether SAVEPOINT names need to be unique within a transaction or can be reused

## Questions
- If a stored procedure calls another stored procedure that also has a COMMIT, does the inner COMMIT affect the outer transaction?
- Can you set a SAVEPOINT inside a stored procedure and have the caller roll back to it from outside the procedure?
- What happens to open transactions if a session disconnects without committing?

## Related concepts
- [Transactions](../concepts/transactions.md)

## Resources used
- Class exercises: accounts table (Alice, Bob, Charlie) — manual transfers with BEGIN/COMMIT/ROLLBACK/SAVEPOINT
- deposit_funds stored procedure — input validation, COMMIT on success, ROLLBACK + re-raise on exception