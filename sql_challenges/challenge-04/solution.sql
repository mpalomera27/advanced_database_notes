
WITH ranked AS (
    SELECT
        d.department_name,
        e.name,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employee e
    JOIN department d
        ON d.department_id = e.department_id
)
SELECT
    department_name,
    name,
    salary
FROM ranked
WHERE salary_rank <= 3
ORDER BY
    department_name ASC,
    salary DESC,
    name ASC;

-- Si dos personas tienen el mismo 3er salario, DENSE_RANK
-- las incluye a ambas. RANK tambien pero se saltaria el 4.
-- ROW_NUMBER excluiria arbitrariamente a una de ellas.
-- ============================================================
