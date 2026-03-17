# Aggregate Functions

## My understanding
Aggregate functions are SQL operations that summarize multiple rows into a single value. 
Instead of returning every row in a table, they compute a result based on a group of rows.

Common aggregate functions include:
- COUNT() → counts rows
- SUM() → adds numeric values
- AVG() → calculates the mean
- MIN() → finds the smallest value
- MAX() → finds the largest value

When we need aggregates per category (for example, per department or role), we use GROUP BY to divide rows into groups before applying the aggregate.

WHERE filters rows before aggregation, while HAVING filters after aggregation.

## Why it matters
Aggregate functions are essential for data analysis and reporting.

They allow us to:
- Measure totals (total sales, total employees)
- Compute averages (average salary)
- Detect extremes (highest revenue, minimum score)
- Build dashboards and summaries

Without aggregates, SQL would only retrieve raw rows instead of meaningful insights.

Understanding how GROUP BY and HAVING work is critical for writing correct analytical queries and avoiding logical errors.

## Example

Count employees per department:

```sql
SELECT department_id, COUNT(*) AS num_employees
FROM employees
GROUP BY department_id;