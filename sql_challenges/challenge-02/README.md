# Challenge 02 — SQLBolt Lessons 6–7

## Tema
Consultas multi-tabla usando JOINs sobre `movies`, `boxoffice`, `buildings` y `employees`.

## Conceptos practicados
- `INNER JOIN` — combinar filas con coincidencia en ambas tablas
- `LEFT JOIN` (OUTER JOIN) — incluir todas las filas de la tabla izquierda
- Filtrar con `WHERE ... IS NOT NULL` tras un LEFT JOIN
- `DISTINCT` para evitar duplicados en resultados de JOIN

## Tablas utilizadas
- `movies` (id, title, director, year, length_minutes)
- `boxoffice` (movie_id, rating, domestic_sales, international_sales)
- `buildings` (building_name, capacity)
- `employees` (role, name, building, years_employed)

## Solución
Ver [solution.sql](./solution.sql)
