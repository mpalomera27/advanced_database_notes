# Session – 2026-02-26

## Topics covered
- Aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- GROUP BY
- HAVING
- Difference between WHERE and HAVING
- ROLLUP for subtotals and totals
- SQLBolt Lessons 10 and 11
- FreeSQL: Aggregating Rows

## What I understood
- Aggregate functions summarize multiple rows into a single value.
- GROUP BY is required when selecting a non-aggregated column together with an aggregate.
- WHERE filters rows before grouping happens.
- HAVING filters grouped results after aggregation.
- ROLLUP extends GROUP BY to generate subtotal and grand total rows.
- COUNT(*) counts rows, while SUM() and AVG() operate on numeric columns.

## What is still confusing
- How ROLLUP behaves with multiple grouping columns.
- When it is more appropriate to use ROLLUP vs CUBE.
- Performance implications of aggregates on large datasets.

## Questions
- How does the database internally execute GROUP BY?
- Does HAVING always require GROUP BY?
- How do indexes affect aggregate queries performance?

## Related concepts
- [Indexing](../concepts/indexing.md)
- [Query execution plan](../concepts/query-execution-plan.md)
- [Relational algebra](../concepts/relational-algebra.md)

## Resources used
- SQLBolt – Select queries with aggregates (Lessons 10 and 11)
- FreeSQL – Aggregating Rows: Databases for Developers
- See `resources/`