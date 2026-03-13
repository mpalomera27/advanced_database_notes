# Session – 2026-06-17

## Topics covered
•⁠  ⁠tables
•⁠  ⁠JOIN
•⁠  ⁠. 
•⁠  ⁠INNER JOIN
•⁠  ⁠LEFT JOIN
•⁠  ⁠SELF JOIN
•⁠  ⁠RIGHT JOIN


## What I understood
•⁠  ⁠Tables have primary keys that are the id of a row
•⁠  ⁠La INNER JOIN palabra clave selecciona registros que tienen valores coincidentes en ambas tablas.
•⁠  ⁠if add t1._ anything is grab just that collumn
•⁠  ⁠The LEFT JOIN keyword returns all records from the left table (table1), and the matching records from the right table (table2). The result is 0 records from the right side, if there is no match.
•⁠  ⁠Self join is a regular join, but the table is joined with itself.

## What is still confusing
- When to use `INNER JOIN` vs `LEFT JOIN`
- How `NULL` appears after a `LEFT JOIN`
- Difference between conditions in `ON` and `WHERE`
- When to use `DISTINCT` vs `GROUP BY`
- How aliases work in joins
- Why `RIGHT JOIN` is less common

## Questions
- When should I use `LEFT JOIN` instead of `INNER JOIN`?
- How do I find rows with no match after a `LEFT JOIN`?
- What is the difference between `ON` and `WHERE`?
- When do I use `DISTINCT` and when `GROUP BY`?
- Can I use aliases in the `ON` clause?
- Why do most people prefer `LEFT JOIN` over `RIGHT JOIN`?
- In a `SELF JOIN`, how do I tell the two copies apart?

### SECTION 6: 
##### Multi-table queries with JOINs

•⁠  ⁠Find the domestic and international sales for each movie
    ⁠ sql
    SELECT movies.Title, boxoffice.domestic_sales , boxoffice.international_sales FROM movies INNER JOIN boxoffice ON movies.Id = boxoffice.movie_id;
     ⁠
•⁠  ⁠Show the sales numbers for each movie that did better internationally rather than domestically
    ⁠ sql
    SELECT movies.Title, boxoffice.domestic_sales,boxoffice.international_sales FROM movies INNER JOIN boxoffice ON movies.Id = boxoffice.movie_id WHERE boxoffice.domestic_sales < boxoffice.international_sales ; 
     ⁠
•⁠  ⁠List all the movies by their ratings in descending order
    ⁠ sql
    SELECT movies.Title, boxoffice.rating FROM movies INNER JOIN boxoffice ON movies.Id = boxoffice.movie_id  ORDER BY boxoffice.rating DESC;
     ⁠
### SECTION 7: 
##### SQL Lesson 7: OUTER JOINs

•⁠  ⁠Find the domestic and international sales for each movie
    ⁠ sql
    SELECT DISTINCT(b.building_name) bn FROM employees e LEFT JOIN buildings b ON bn = e.building;
     ⁠
•⁠  ⁠Find the list of all buildings and their capacity
    ⁠ sql
    SELECT * FROM buildings;
     ⁠
•⁠  ⁠List all buildings and the distinct employee roles in each building (including empty buildings)
    ⁠ sql
    SELECT b.building_name bn, e.role r FROM buildings b  LEFT JOIN employees e ON bn = e.building GROUP BY bn,r;
     ⁠
### Interview Question : 
##### Page With No Likes

 ⁠ sql
    SELECT p.page_id  FROM pages p LEFT JOIN page_likes p_l ON p.page_id = p_l.page_id WHERE p_l.page_id IS NULL;    
 ⁠
