# LIMIT and OFFSET

## My understanding
LIMIT controls how many rows are returned, OFFSET skips a certain amount of rows.

## Why it matters
Lets you work efficiently with big datasets and it's very important for pagination.

## Example
SELECT title FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5;