-- ============================================================
-- SESSION 5: Union, Minus, Intersect
-- Tablas: my_brick_collection, your_brick_collection
-- ============================================================


-- TRY IT 1 ------------------------------------------------

-- Todos los colores que existen entre las dos colecciones
-- sin repetir el mismo color dos veces
SELECT colour FROM my_brick_collection
UNION
SELECT colour FROM your_brick_collection
ORDER BY colour;

-- Todas las formas de ambas colecciones
-- aqui SI pueden aparecer repetidas, eso es UNION ALL
SELECT shape FROM my_brick_collection
UNION ALL
SELECT shape FROM your_brick_collection
ORDER BY shape;


-- TRY IT 2 ------------------------------------------------

-- Formas que YO tengo pero TU no tienes
-- si ambos tenemos "cube", cube no aparece
SELECT shape FROM my_brick_collection
MINUS
SELECT shape FROM your_brick_collection;

-- Colores que los DOS tenemos en comun
-- si solo uno de los dos tiene ese color, no aparece
SELECT colour FROM my_brick_collection
INTERSECT
SELECT colour FROM your_brick_collection
ORDER BY colour;