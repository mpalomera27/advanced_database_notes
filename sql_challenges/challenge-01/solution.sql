-- Lesson 1
SELECT Title FROM movies; -- Task 1
SELECT Director FROM movies; -- Task 2
SELECT Title, Director FROM movies; -- Task 3
SELECT Title, Year FROM movies; -- Task 4
SELECT * FROM movies; -- Task 5

-- Lesson 2
SELECT * FROM Movies WHERE Id = 6; -- Task 1
SELECT * FROM Movies WHERE Year BETWEEN 2000 AND 2010; -- Task 2
SELECT * FROM Movies WHERE Year NOT BETWEEN 2000 AND 2010; -- Task 3
SELECT * FROM Movies WHERE Year < 2004; -- Task 4

-- Lesson 3
SELECT * FROM movies WHERE Title LIKE "%Toy Story%"; -- Task 1
SELECT * FROM movies WHERE Director LIKE "John Lasseter"; -- Task 2
SELECT * FROM movies WHERE Director NOT LIKE "John Lasseter"; -- Task 3
SELECT * FROM movies WHERE Title LIKE "WALL-_"; -- Task 4

-- Lesson 4
SELECT DISTINCT director FROM movies ORDER BY director ASC; -- Task 1
SELECT title, year FROM movies ORDER BY year DESC LIMIT 4; -- Task 2
SELECT title FROM movies ORDER BY title ASC LIMIT 5; -- Task 3
SELECT title FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5; -- Task 4

-- Lesson 5 (Review 1)
SELECT city, population FROM north_american_cities WHERE country = 'Canada'; -- Task 1
SELECT city, latitude FROM north_american_cities WHERE country = 'United States' ORDER BY latitude DESC; -- Task 2
SELECT city, longitude FROM north_american_cities WHERE longitude < -87.629798 ORDER BY longitude ASC; -- Task 3
SELECT city, population FROM north_american_cities WHERE country = 'Mexico' ORDER BY population DESC LIMIT 2; -- Task 4
SELECT city, population FROM north_american_cities WHERE country = 'United States' ORDER BY population DESC LIMIT 2 OFFSET 2; -- Task 5