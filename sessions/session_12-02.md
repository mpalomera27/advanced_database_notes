# Session – 2026-02-12

## Topics covered
- Mental model of SQL
- SELECT vs SELECT *
- Filtering data with WHERE
- Numerical and boolean logic
- Filtering text with LIKE
- Deleting duplicates with DISTINCT
- Sorting results with ORDER BY
- Uses of LIMIT and OFFSET
- Logical execution order of a SQL query

## What I understood
- SQL helps us to show specific data by asking precise questions. It's not just about retrieving everything.
- Tables represent entities, rows instances and columns properties.
- WHERE filters rows, SELECT chooses columns, and ORDER BY gives form to the output.
- The logical order in which we write queries and the order in which the database executes them is not the same.
- LIMIT and OFFSET help to paginate and slice our results. 

## What is still confusing
- Remembering the order of the logical execution without mixing it up.
- When it's better to use BETWEEN instead of explicit comparisons in filters that are more complex.
- How to use DISTINCT when also using ORDER BY and LIMIT.

## Questions
- If we use JOINs, does the logical order change and how?
- Are there any differences in performance when we use IN instead of various OR conditions?
- When should we be filtering in SQL and when in application code?

## Related concepts
- [SQL Mental Model](../concepts/sql-mental-model.md)
- [WHERE Clause](../concepts/where-clause.md)
- [ORDER BY](../concepts/order-by.md)
- [LIMIT & OFFSET](../concepts/limit-offset.md)

## Resources used
- See `resources/`