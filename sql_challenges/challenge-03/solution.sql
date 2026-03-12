SELECT MAX(years_employed) FROM employees;

SELECT AVG(years_employed) , role
FROM employees
GROUP BY role
;

SELECT building , SUM(years_employed) 
FROM employees
GROUP BY building
;

SELECT Count(role)
FROM employees
where role = 'Artist'
;

SELECT role ,Count(role)
FROM employees
GROUP By role
;

SELECT role , Sum(Years_employed)
FROM employees
Where role = 'Engineer'
;

select COUNT(distinct shape) number_of_shapes,
        STDDEV(unique weight) distinct_weight_stddev
from   bricks;

select shape, SUM(weight) shape_weight
from   bricks
group by shape;

select shape, sum ( weight ) sw
from   bricks
group  by shape
having sw < 4;