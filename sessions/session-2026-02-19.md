# Session – 2026-02-19

## Topics covered
- INNER JOIN: combinar dos tablas usando una clave compartida
- OUTER JOINs: LEFT JOIN, RIGHT JOIN, FULL JOIN
- Concepto de clave primaria (primary key) y clave foránea (foreign key)
- Normalización de base de datos — por qué los datos se separan en tablas
- Manejar valores NULL que aparecen en resultados de OUTER JOINs

## What I understood
- INNER JOIN solo devuelve filas donde hay coincidencia en AMBAS tablas
- Si una película no tiene datos en boxoffice, un INNER JOIN la excluye del resultado
- LEFT JOIN devuelve TODAS las filas de la tabla izquierda aunque no haya match en la derecha — las columnas sin match quedan como NULL
- RIGHT JOIN es lo mismo pero al revés — todas las filas de la tabla derecha
- FULL JOIN combina ambos — devuelve todo de ambas tablas, con NULL donde no hay match
- La sintaxis ON define qué columnas conectan las dos tablas (la "llave")
- DISTINCT dentro de un JOIN evita filas repetidas cuando hay relaciones uno-a-muchos
- Tablas con datos asimétricos (ej. buildings sin employees) necesitan OUTER JOIN

## What is still confusing
- Cuándo usar RIGHT JOIN vs simplemente voltear el orden de las tablas y usar LEFT JOIN
- Diferencia entre FULL JOIN y UNION de dos LEFT JOINs
- Cómo manejar los NULLs que aparecen en columnas de la tabla derecha después de un LEFT JOIN

## Questions
- ¿Se pueden hacer JOINs de más de dos tablas a la vez?
- ¿El orden de las tablas en el FROM afecta el rendimiento además del resultado?
- ¿INNER JOIN y JOIN son exactamente lo mismo o hay alguna diferencia?

## Related concepts
- [JOINs](../concepts/joins.md)
- [Primary Keys](../concepts/primary-keys.md)
- [NULL Values](../concepts/null-values.md)
- [Normalization](../concepts/normalization.md)

## Resources used
- https://sqlbolt.com/lesson/select_queries_with_joins
- https://sqlbolt.com/lesson/select_queries_with_outer_joins
- See `resources/`
