# Sesión 07 — KPI Dashboards

**Fecha:** 2026-05-21
**Tema:** Definición de KPIs, consultas analíticas y dashboards con SQL

---

## Resumen de la sesión

Esta clase fue sobre cómo pasar de "contar filas" a "medir el negocio". Un KPI (Key Performance Indicator) no es solo una query — es una promesa: si defines mal qué cuenta como "completado" o qué significa "a tiempo", estás reportando un número que nadie puede confiar.

El esquema base de las lecciones anteriores (teams, users, tasks) se enriqueció con cuatro columnas nuevas para soportar análisis temporal: `priority`, `due_date`, `completed_at` y `tags`. Con eso ya se pueden calcular cosas como velocidad por equipo, tasa de entrega a tiempo y tiempo promedio de resolución.

La parte más importante de la clase no fue el SQL sino el **contrato del KPI**: antes de escribir una query, hay que definir exactamente qué cuenta y qué no cuenta, cuáles son los casos extremos, y qué haría que el número fuera engañoso.

---

## Conceptos clave cubiertos

- Qué es un KPI y por qué necesita un "contrato" (definición formal)
- Cómo enriquecer un esquema existente con `ALTER TABLE ... ADD (...)`
- Cómo modificar o reemplazar un constraint con `DROP CONSTRAINT` + `ADD CONSTRAINT`
- Funciones de ventana (`OVER()`) para comparar filas contra el total o el promedio
- `PERCENTILE_CONT(0.5)` para calcular la mediana (más robusta que el promedio)
- `GROUPING()` con `ROLLUP` para agregar filas de subtotal en un reporte
- `CROSS JOIN` para combinar métricas independientes en una sola fila
- Estrategia de CTEs en cadena: base → métricas → query final
- Errores comunes de KPIs mal definidos (promediar IDs, mezclar estados, ignorar NULLs)

---

## Conceptos relacionados

- [KPI Dashboards](../concepts/kpi-dashboards.md) — contratos de KPI, funciones analíticas, anti-patrones
- [Diagrama del esquema Lección 07](../diagrams/lesson-07-kpi-schema.md) — tabla tasks enriquecida

---

## Lo que entendí bien

- Por qué hay que usar `NULLIF` en el denominador de un porcentaje: si no hay tareas no canceladas, la división explotaría con ORA-01476.
- La diferencia entre `TRUNC(SYSDATE)` y `SYSDATE` en comparaciones de fecha: `TRUNC` elimina la hora, así una tarea vencida "hoy" no aparece como atrasada hasta que pase la medianoche.
- Por qué el original `AVG(ts.id)` del Exercise 7 es un error conceptual, no solo técnico: el ID es un identificador, no una magnitud.
- Cómo `PERCENTILE_CONT` es mejor que `AVG` cuando hay outliers: un ticket que tardó 3 semanas no jala la mediana tanto como jala el promedio.

## Lo que todavía me confunde

- Cuándo usar `RANK()` vs `ROW_NUMBER()` en el `FETCH FIRST 1 ROW ONLY` dentro de un CTE. Si dos equipos tienen el mismo conteo, `RANK()` devuelve ambos y `FETCH FIRST 1` elige uno arbitrariamente — ¿cuál es la forma correcta de manejar empates?
- El comportamiento de `GROUPING()` cuando hay más de una columna en el `ROLLUP`: no me queda claro qué valor devuelve si hay jerarquías anidadas.

## Preguntas

- ¿Hay alguna diferencia de rendimiento entre calcular `resolution_hours` en el CTE base vs calcularlo directamente en el `SELECT` final?
- ¿Se puede materializar un CTE en Oracle 23ai para reutilizarlo sin recalcularlo? (¿equivalente a `WITH ... MATERIALIZED`?)
- ¿Cuándo tiene sentido crear una vista (`CREATE VIEW`) en lugar de un CTE repetido en varias queries?
