# Session – 2026-04-16

## Topics covered
- Indexes in Oracle 23ai: B-Tree structure and how the Cost-Based Optimizer (CBO) decides when to use them
- Cardinality and selectivity: high vs low cardinality columns and their impact on index usefulness
- Index range scans vs full table scans: how the size of a range query affects the execution plan
- Composite indexes and the leading column rule
- Function-based index trap: how wrapping a column in a function breaks index usage
- Real-world index design decisions: OLTP vs reporting tables, unique indexes, bitmap indexes

## What I understood
- The CBO uses statistics to estimate how many rows a query returns and picks the cheapest access path
- Low cardinality columns (like site_id with 5 values) are bad candidates for B-Tree indexes because each value returns too many rows (~20%)
- A composite index (patient_id, visit_date) can be used with the leading column alone but NOT with the trailing column alone
- Applying a function to an indexed column in the WHERE clause forces a full table scan — apply the function to the literal instead
- For unique columns like email, a UNIQUE index enforces data integrity AND gives the fastest possible access (INDEX UNIQUE SCAN)

## What is still confusing
- Exactly at what percentage of rows the CBO switches from index scan to full scan (seems to vary by hardware and block size)
- When bitmap indexes are actually safe to use in practice vs when they cause lock contention
- How to interpret the Cost column in DBMS_XPLAN.DISPLAY and compare plans reliably

## Questions
- Can the CBO be forced to use an index even when it prefers a full scan (hints)?
- What happens to index performance as the table grows — does the index need to be rebuilt periodically?
- How does Oracle handle index maintenance during a bulk INSERT of millions of rows?

## Related concepts
- [Indexes](../concepts/indexes.md)

## Resources used
- See `resources/`