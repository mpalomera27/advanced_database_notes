
### `sql_challenges/challenge-01/README.md`

```md
# SQL Challenge 01 – Aggregations part 1

## Problem
Practice of using aggregations in SQLBolt

```sql
SELECT MAX(Years_employed) FROM employees;

SELECT Role, AVG(Years_employed) AS Years_Employed_AVG
FROM employees
GROUP BY Role;

SELECT Building, SUM(Years_employed) AS Years_Employed_SUM
FROM employees
GROUP BY Building;

--PART 2
SELECT COUNT(Role) AS ARTISTS 
FROM employees 
WHERE Role=="Artist";

SELECT Role,COUNT(Role) AS Counted_Roles 
FROM employees 
GROUP BY Role;

SELECT Role,SUM(Years_employed) AS Years_Employed 
FROM employees 
WHERE Role=="Engineer" 
GROUP BY Role;

```md
# SQL Challenge 02 – Aggregations part 2

## Problem
Aggregations in Oracle SQL

```sql
select COUNT(distinct shape) AS number_of_shapes,
       STDDEV(unique weight) AS distinct_weight_stddev
from   bricks;

select shape, SUM(weight) AS shape_weight
from   bricks
GROUP BY shape;

select shape, sum ( weight )
from   bricks
group  by shape
HAVING SUM(weight) < 4;

