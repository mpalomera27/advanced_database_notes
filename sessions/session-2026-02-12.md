# Session – 2026-03-13

## Topics covered
- SELECT básico: elegir columnas específicas o todas con `*`
- WHERE con operadores numéricos: `=`, `!=`, `BETWEEN`, `NOT BETWEEN`, `IN`, `NOT IN`
- WHERE con texto: `LIKE`, `NOT LIKE`, wildcards `%` y `_`
- Eliminar duplicados con `DISTINCT`
- Ordenar resultados con `ORDER BY` (ASC / DESC)
- Limitar resultados con `LIMIT` y paginar con `OFFSET`

## What I understood
- `SELECT columnas FROM tabla` es la estructura base de todo query SQL
- `WHERE` filtra filas antes de devolver resultados — reduce datos innecesarios y hace el query más rápido
- `BETWEEN 2000 AND 2010` es inclusivo en ambos extremos (equivale a `>= 2000 AND <= 2010`)
- `IN (1,2,3)` reemplaza múltiples `OR` — más limpio y legible
- `LIKE 'Toy Story%'` — el `%` es comodín para "cualquier cosa después"
- `LIKE 'WALL-%'` matchea WALL-E, WALL-A, cualquier cosa después del guión
- `DISTINCT` elimina filas duplicadas en el resultado
- `ORDER BY column DESC` ordena de mayor a menor; `ASC` de menor a mayor (default)
- `LIMIT 5 OFFSET 5` = sáltate los primeros 5, trae los siguientes 5 — así funciona la paginación
- Latitud positiva = norte del ecuador / Longitud negativa = oeste del meridiano — más negativo = más al oeste

## What is still confusing
- Diferencia entre `=` y `LIKE` para strings exactos (cuándo usar uno u otro)
- `_` como wildcard de un solo carácter — no lo usé en los ejercicios
- Cómo funciona `OFFSET` si hay menos filas que el número indicado

## Questions
- ¿`LIMIT` y `OFFSET` son estándar en todos los motores SQL o solo en algunos?
- ¿`BETWEEN` funciona también con strings y fechas además de números?
- ¿Hay diferencia de rendimiento entre `IN (1,2,3,4,5)` y `id <= 5`?

## Related concepts
- [SELECT](../concepts/select.md)
- [WHERE Clauses](../concepts/where-clauses.md)
- [ORDER BY](../concepts/order-by.md)
- [LIMIT and OFFSET](../concepts/limit-offset.md)
- [DISTINCT](../concepts/distinct.md)

## Resources used
- https://sqlbolt.com/lesson/select_queries_introduction
- https://sqlbolt.com/lesson/select_queries_with_constraints
- https://sqlbolt.com/lesson/select_queries_with_constraints_pt_2
- https://sqlbolt.com/lesson/filtering_sorting_query_results
- https://sqlbolt.com/lesson/select_queries_review
- See `resources/`