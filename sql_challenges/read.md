# SQL Challenge 03 – Aggregates (SQLBolt + FreeSQL)

## Problem
Complete the following:
1) SQLBolt: Select queries with aggregates (Lesson 10)
2) SQLBolt: Select queries with aggregates pt. 2 (Lesson 11)
3) FreeSQL: Aggregating Rows (Databases for Developers) – copy the three "Try It!" queries into solution.sql

## Concepts
- Aggregate functions: COUNT, SUM, AVG, MIN, MAX
- GROUP BY
- HAVING (filter after aggregation)
- ROLLUP (generate subtotals / grand total)

## Reasoning
Aggregate functions summarize multiple rows into a single value (e.g., COUNT counts rows, AVG computes mean).
When we need aggregates per category (e.g., per role, per department), we use GROUP BY to partition rows into groups and then apply the aggregate per group.

WHERE filters rows before grouping; HAVING filters groups after aggregation.
ROLLUP extends GROUP BY by adding subtotal/grand total rows, useful for reporting.

## Files
- solution.sql: all required queries (SQLBolt + FreeSQL Try It)
- notes.md: short notes and key takeaways