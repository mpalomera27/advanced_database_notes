-- ============================================================
-- SQLBOLT LESSONS 1 AL 5 — TODAS LAS RESPUESTAS
-- Tabla principal: movies (Id, Title, Director, Year, Length_minutes)
-- ============================================================


-- ============================================================
-- LESSON 1: SELECT queries 101
-- Concepto: SELECT basico — elegir columnas de una tabla
-- ============================================================

-- Task 1: Find the title of each film
SELECT title FROM movies;

-- Task 2: Find the director of each film
SELECT director FROM movies;

-- Task 3: Find the title and director of each film
SELECT title, director FROM movies;

-- Task 4: Find the title and year of each film
SELECT title, year FROM movies;

-- Task 5: Find ALL the information about each film
SELECT * FROM movies;


-- ============================================================
-- LESSON 2: Queries with constraints Pt. 1
-- Concepto: WHERE con operadores numericos (=, !=, BETWEEN, IN)
-- ============================================================

-- Task 1: Find the movie with a row id of 6
SELECT * FROM movies
WHERE id = 6;

-- Task 2: Find the movies released between 2000 and 2010
SELECT * FROM movies
WHERE year BETWEEN 2000 AND 2010;

-- Task 3: Find the movies NOT released between 2000 and 2010
SELECT * FROM movies
WHERE year NOT BETWEEN 2000 AND 2010;

-- Task 4: Find the first 5 Pixar movies and their release year
SELECT title, year FROM movies
WHERE id IN (1, 2, 3, 4, 5);


-- ============================================================
-- LESSON 3: Queries with constraints Pt. 2
-- Concepto: WHERE con texto (LIKE, %, NOT LIKE, IN con strings)
-- ============================================================

-- Task 1: Find all the Toy Story movies
SELECT * FROM movies
WHERE title LIKE 'Toy Story%';

-- Task 2: Find all the movies directed by John Lasseter
SELECT * FROM movies
WHERE director = 'John Lasseter';

-- Task 3: Find all the movies (and director) NOT directed by John Lasseter
SELECT title, director FROM movies
WHERE director != 'John Lasseter';

-- Task 4: Find all the WALL-* movies
SELECT * FROM movies
WHERE title LIKE 'WALL-%';


-- ============================================================
-- LESSON 4: Filtering and sorting query results
-- Concepto: DISTINCT, ORDER BY, LIMIT, OFFSET
-- ============================================================

-- Task 1: List all directors alphabetically, sin duplicados
SELECT DISTINCT director FROM movies
ORDER BY director ASC;

-- Task 2: Last four Pixar movies (mas reciente primero)
SELECT title, year FROM movies
ORDER BY year DESC
LIMIT 4;

-- Task 3: First five Pixar movies sorted alphabetically
SELECT title FROM movies
ORDER BY title ASC
LIMIT 5;

-- Task 4: NEXT five Pixar movies sorted alphabetically (posiciones 6-10)
SELECT title FROM movies
ORDER BY title ASC
LIMIT 5 OFFSET 5;


-- ============================================================
-- LESSON 5 (Review): Simple SELECT Queries
-- Tabla: north_american_cities (City, Country, Population, Latitude, Longitude)
-- Concepto: Combinar todo lo anterior con una tabla nueva
-- ============================================================

-- Task 1: List all Canadian cities and their populations
SELECT city, population FROM north_american_cities
WHERE country = 'Canada';

-- Task 2: US cities ordered by latitude north to south (mayor latitud = mas al norte)
SELECT city, latitude FROM north_american_cities
WHERE country = 'United States'
ORDER BY latitude DESC;

-- Task 3: Cities west of Chicago ordered from west to east
-- Chicago tiene longitude -87.6298 — mas negativo = mas al oeste
SELECT city, longitude FROM north_american_cities
WHERE longitude < -87.6298
ORDER BY longitude ASC;

-- Task 4: Two largest cities in Mexico by population
SELECT city, population FROM north_american_cities
WHERE country = 'Mexico'
ORDER BY population DESC
LIMIT 2;

-- Task 5: Third and fourth largest US cities by population
SELECT city, population FROM north_american_cities
WHERE country = 'United States'
ORDER BY population DESC
LIMIT 2 OFFSET 2;