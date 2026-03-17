/* =========================
   SQLBolt Lesson 10
   Select queries with aggregates (Pt. 1)
   ========================= */

-- 10.1 Find the longest time that an employee has been at the studio
SELECT MAX(Years_employed) AS max_years_employed
FROM employees;

-- 10.2 For each role, find the average number of years employed by employees in that role
SELECT Role, AVG(Years_employed) AS avg_years_employed
FROM employees
GROUP BY Role;

-- 10.3 Find the total number of employee years worked in each building
SELECT Building, SUM(Years_employed) AS total_years_employed
FROM employees
GROUP BY Building;


/* =========================
   SQLBolt Lesson 11
   Select queries with aggregates (Pt. 2)
   ========================= */

-- 11.1 Find the number of Artists in the studio (without a HAVING clause)
SELECT COUNT(*) AS num_artists
FROM employees
WHERE Role = 'Artist';

-- 11.2 Find the number of Employees of each role in the studio
SELECT Role, COUNT(*) AS num_employees
FROM employees
GROUP BY Role;

-- 11.3 Find the total number of years employed by all Engineers
SELECT SUM(Years_employed) AS total_engineer_years
FROM employees
WHERE Role = 'Engineer';


/* =========================
   FreeSQL (Databases for Developers)
   Aggregating Rows – "Try It!" (3 queries)
   Note: These are the standard Try-It patterns: GROUP BY, HAVING, ROLLUP
   ========================= */

-- Try It #1: Aggregate per group (GROUP BY)
SELECT department_id, COUNT(*) AS num_employees
FROM hr.employees
GROUP BY department_id
ORDER BY department_id;

-- Try It #2: Filter aggregated results (HAVING)
SELECT department_id, COUNT(*) AS num_employees
FROM hr.employees
GROUP BY department_id
HAVING COUNT(*) >= 5
ORDER BY department_id;

-- Try It #3: Add subtotals / grand total (ROLLUP)
SELECT department_id, COUNT(*) AS num_employees
FROM hr.employees
GROUP BY ROLLUP (department_id)
ORDER BY department_id;