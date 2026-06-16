# Sesión 08 — ETL + Data Warehouse

**Fecha:** 2026-05-28
**Tema:** Extracción, transformación y carga (ETL) hacia un Data Warehouse con esquema estrella

---

## Resumen de la sesión

Esta clase fue sobre cómo mover datos desde un sistema OLTP (la base de datos transaccional donde se registran los eventos del día a día) hacia un Data Warehouse (una base diseñada específicamente para análisis y reportes).

El sistema fuente que usamos fue el mismo task manager de lecciones anteriores, pero ampliado con una tabla de historial de asignaciones (`task_assignments`) para rastrear quién tenía cada tarea en cada momento. Eso introduce el problema central de esta lección: **los datos históricos cambian de significado dependiendo del punto en el tiempo que mires**.

El Data Warehouse se organizó como un **esquema estrella**: una tabla de hechos (`fact_task_daily`) rodeada de dimensiones (`dim_user`, `dim_date`, `dim_status`). La tabla de hechos tiene una sola fila por combinación de fecha + usuario + estado + prioridad, lo que permite sumar cualquier métrica en cualquier corte.

El ETL en Python/pandas tiene tres fases:
1. **Extract**: leer las tablas del OLTP con `pd.read_sql`
2. **Transform**: resolver quién era el asignado en cada punto en el tiempo usando una función de búsqueda temporal
3. **Load**: insertar los resultados agregados en la tabla de hechos con `executemany`

---

## Conceptos clave cubiertos

- Diferencia entre OLTP y OLAP/Data Warehouse (diseño, propósito, rendimiento)
- Esquema estrella: tabla de hechos + dimensiones
- Clave surrogate: por qué el DW genera sus propias PKs independientes del sistema fuente
- `dim_date` pre-poblada: por qué se calculan atributos de fecha por adelantado
- Trigger `AFTER INSERT OR UPDATE`: cómo automatizar el log de cambios en Oracle
- Patrón de historial temporal: `valid_from` / `valid_to` para rastrear quién tenía qué y cuándo
- Búsqueda punto en el tiempo: condición `valid_from <= T AND (valid_to IS NULL OR valid_to > T)`
- `executemany` en Python: cómo hacer inserciones masivas eficientes
- Granularidad de un fact: una fila por combinación de (fecha, usuario, estado, prioridad)

---

## Conceptos relacionados

- [ETL y Data Warehouse](../concepts/etl-data-warehouse.md) — OLTP vs OLAP, esquema estrella, ETL, historial temporal
- [Diagrama del esquema Lección 08](../diagrams/lesson-08-star-schema.md) — OLTP + DW star schema completo

---

## Lo que entendí bien

- Por qué el `dim_date` se pre-llena en lugar de calcularlo en cada query: si tienes 100 reportes que necesitan saber si una fecha es fin de semana, es más barato computarlo una vez y guardarlo que calcularlo 100 veces con `TO_CHAR(fecha, 'DY')`.
- Por qué el trigger usa `AFTER` y no `BEFORE`: en `AFTER` ya tienes los valores definitivos (generados por la BD, como el `id` de un `IDENTITY`). En `BEFORE`, el `:NEW.id` de una columna IDENTITY todavía no existe.
- Por qué el DW no usa foreign keys hacia el sistema fuente: si borras un usuario del OLTP, no quieres que eso rompa el historial del DW. La dimensión es una copia desnormalizada, no una referencia viva.
- La diferencia conceptual entre `tasks_created` y `tasks_completed` en el fact: el crédito de creación va al agente en `created_at`, el de resolución va al agente en `completed_at`. Para tareas reasignadas, son personas distintas.

## Lo que todavía me confunde

- ¿Cómo se actualizaría el DW si un usuario cambia de equipo? (Slowly Changing Dimensions Tipo 2 — se mencionó de pasada pero no lo desarrollamos)
- Si la tabla de hechos tiene una constraint `UNIQUE (date_key, user_key, status_key, priority)`, ¿qué pasa si el ETL se corre dos veces? ¿Debería hacer `MERGE` en lugar de `INSERT`?
- ¿Cuándo tiene sentido llenar `dim_date` con años completos por adelantado vs. solo las fechas que aparecen en los datos?

## Preguntas

- ¿Es posible hacer el ETL directamente en SQL con `INSERT INTO ... SELECT` en lugar de Python? ¿Cuándo conviene uno sobre el otro?
- ¿Oracle tiene alguna sintaxis equivalente al `MERGE` de SQL Server para manejar inserciones idempotentes en el DW?
- ¿Qué herramienta de orquestación se usaría en producción para programar el ETL diario? (¿Airflow? ¿dbt?)
