-- ============================================================
-- SQLBOLT LESSON 6 — Multi-table queries with JOINs
-- Tablas: movies (id, title, director, year, length_minutes)
--         boxoffice (movie_id, rating, domestic_sales, international_sales)
-- ============================================================

-- Task 1: Domestic and international sales for each movie
SELECT m.title,
       b.domestic_sales,
       b.international_sales
FROM movies m
INNER JOIN boxoffice b ON m.id = b.movie_id;

-- Task 2: Movies that did better internationally than domestically
SELECT m.title,
       b.domestic_sales,
       b.international_sales
FROM movies m
INNER JOIN boxoffice b ON m.id = b.movie_id
WHERE b.international_sales > b.domestic_sales;

-- Task 3: All movies listed by rating descending
SELECT m.title,
       b.rating
FROM movies m
INNER JOIN boxoffice b ON m.id = b.movie_id
ORDER BY b.rating DESC;


-- ============================================================
-- SQLBOLT LESSON 7 — OUTER JOINs
-- Tablas: buildings (building_name, capacity)
--         employees (role, name, building, years_employed)
-- ============================================================

-- Task 1: List of all buildings that HAVE employees
SELECT DISTINCT b.building_name
FROM buildings b
LEFT JOIN employees e ON b.building_name = e.building
WHERE e.building IS NOT NULL;

-- Task 2: List of all buildings and their capacity (con o sin empleados)
SELECT building_name, capacity
FROM buildings;

-- Task 3: All buildings with distinct employee roles (including empty buildings)
SELECT DISTINCT b.building_name,
                e.role
FROM buildings b
LEFT JOIN employees e ON b.building_name = e.building;

-- ============================================================
-- NOTAS CLAVE
-- INNER JOIN = solo filas con match en ambas tablas
-- LEFT JOIN  = todas las filas de la izq + match de la der (NULL si no hay)
-- WHERE e.building IS NOT NULL filtra los buildings SIN empleados
--   despues de un LEFT JOIN — patron clasico para encontrar "huerfanos"
-- DISTINCT evita repetir el mismo building_name por cada empleado
-- ============================================================

-- ============================================================
-- DATALEMUR INTERVIEW QUESTION — Page With No Likes (Facebook)
-- Tablas: pages (page_id, page_name)
--         page_likes (user_id, page_id, liked_date)
-- Objetivo: Encontrar las páginas que no tienen ningún "like".
-- ============================================================

SELECT 
    p.page_id
FROM pages p
LEFT JOIN page_likes l ON p.page_id = l.page_id
WHERE l.page_id IS NULL
ORDER BY p.page_id ASC;
