# Session – 2026-02-24

## Topics covered
- Aggregate functions
- `MAX()`
- `AVG()`
- `SUM()`
- `COUNT()`
- `COUNT(DISTINCT ...)`
- `STDDEV()`
- `GROUP BY`
- `HAVING`
- Filtering with `WHERE`
- Group filtering vs row filtering

## What I understood
- Aggregate functions summarize data from many rows into one result.
- `MAX(column)` returns the largest value in a column.
- `AVG(column)` returns the average value.
- `SUM(column)` adds values together.
- `COUNT(column)` counts non-`NULL` values in that column.
- `COUNT(DISTINCT column)` counts unique values only.
- `GROUP BY` is used when I want aggregates for each category, such as each role or each shape.
- `WHERE` filters rows before grouping.
- `HAVING` filters groups after grouping.
- `STDDEV(DISTINCT weight)` measures how spread out the distinct weight values are.
- If I use an aggregate with another selected column, I usually need `GROUP BY` for that column.

## What is still confusing
- The exact difference between `WHERE` and `HAVING`
- When to use `COUNT(*)` vs `COUNT(column)`
- Why some aggregate queries need `GROUP BY` and others do not
- How `STDDEV()` should be interpreted in practice
- When to use `DISTINCT` inside aggregate functions

## Questions
- What is the difference between `WHERE` and `HAVING` step by step?
- When should I use `COUNT(*)` instead of `COUNT(role)`?
- Why does `SELECT role, SUM(years_employed)` usually need `GROUP BY role`?
- What does standard deviation actually tell me about the data?
- When is `DISTINCT` useful inside `COUNT()` or `STDDEV()`?

## Related concepts
- `MIN()`
- `DISTINCT`
- `NULL`
- Filtering
- Grouping
- Summary statistics

## Resources used
- SQL practice exercises
- Class notes
- `resources/`

## Notes and examples

### Maximum value in a column

**Find the maximum years employed**
```sql
SELECT MAX(years_employed)
FROM employees;