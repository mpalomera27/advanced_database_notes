# KPI Dashboards

## Mi entendimiento

Un KPI (Key Performance Indicator) es una métrica que le dice a alguien del negocio si las cosas van bien o mal. La diferencia entre una query cualquiera y un KPI es el **contrato**: un KPI tiene una definición exacta y pública de qué cuenta, qué no cuenta, y en qué unidades se mide. Sin ese contrato, el número puede ser técnicamente correcto y conceptualmente inútil.

Tom Kyte (el gurú de Oracle) tiene una regla que resume todo: *"Si no puedes explicarle la métrica a alguien no técnico en una sola oración, tu query está mal."*

---

## El contrato del KPI

Antes de escribir cualquier query de KPI hay que responder cinco preguntas:

1. **¿Cuál es la pregunta de negocio?** — Qué quiere saber management.
2. **¿Cuál es la definición exacta?** — Qué filtra, qué excluye, qué joins hace.
3. **¿Cuáles son los casos extremos?** — NULLs, estados cancelados, filas huérfanas.
4. **¿Cuál es la unidad?** — Porcentaje, horas, cantidad de tareas, dinero.
5. **¿Qué haría este número engañoso?** — El sesgo oculto que el lector no ve.

Sin estos cinco puntos, el número que produces es solo eso: un número.

---

## Funciones analíticas clave

### Funciones de ventana (`OVER`)

Permiten calcular agregaciones (SUM, AVG, COUNT, RANK) sin colapsar las filas. El resultado aparece en cada fila junto con los datos originales.

```sql
-- Compara cada equipo contra el promedio global
SELECT
    team_name,
    velocity,
    AVG(velocity) OVER ()                   AS avg_velocity,
    CASE
        WHEN velocity < AVG(velocity) OVER ()
        THEN 'BELOW AVERAGE'
        ELSE 'OK'
    END                                     AS flag
FROM team_velocities;
```

La cláusula `OVER ()` vacía significa "ventana sobre todo el resultado set". Se puede acotar con `PARTITION BY` para comparar dentro de grupos.

### Mediana con `PERCENTILE_CONT`

`AVG` es sensible a valores extremos. Un ticket que tardó 30 días jala el promedio hacia arriba, aunque todos los demás tardaron 2 horas. La mediana no tiene ese problema.

```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours)
```

El `0.5` significa el percentil 50 (la mediana). Se puede usar `0.95` para el P95, que es como se miden los SLAs en ingeniería.

### `ROLLUP` para filas de subtotal

`GROUP BY ROLLUP(col)` agrega automáticamente una fila extra con el total general. La función `GROUPING(col)` devuelve `1` en esa fila de total, lo que permite darle una etiqueta.

```sql
SELECT
    CASE WHEN GROUPING(priority) = 1 THEN '--- TOTAL ---'
         ELSE priority
    END                     AS priority,
    COUNT(*)                AS task_count
FROM tasks
GROUP BY ROLLUP(priority);
```

---

## Estrategia de CTEs en cadena

El patrón más usado en dashboards reales es: un CTE base que enriquece los datos con columnas derivadas, y luego CTEs especializados que sacan cada métrica de ese base.

```sql
WITH base AS (
    -- Enriquece cada fila con columnas calculadas
    SELECT
        ...,
        CASE WHEN status IN ('open','in_progress') THEN 1 END AS is_active,
        CASE WHEN due_date < TRUNC(SYSDATE) ... END           AS is_overdue
    FROM tasks LEFT JOIN ...
),
metric_1 AS (SELECT COUNT(*) AS total FROM base),
metric_2 AS (SELECT COUNT(is_active) AS active FROM base),
metric_3 AS (SELECT ... FROM base WHERE ...)
SELECT *
FROM   metric_1
CROSS  JOIN metric_2
CROSS  JOIN metric_3;
```

La ventaja: el `FROM tasks LEFT JOIN ...` se escribe una sola vez. Si cambias el filtro base, afecta todos los CTEs a la vez.

---

## Errores comunes (anti-patrones)

### Mezclar estados en un COUNT

```sql
-- MAL: cuenta completadas y abiertas juntas
COUNT(tasks.id) AS workload
```

Un equipo con 50 tareas terminadas hace 6 meses y 0 activas aparece como "el más ocupado". Siempre filtra por estado.

### Promediar identificadores técnicos

```sql
-- MAL: avg(id) no significa nada
AVG(ts.id) AS avg_task_id
```

El `id` es un número de secuencia, no una magnitud de negocio. Este error produce un número que parece válido pero es completamente sin sentido.

### Ignorar los NULLs en denominadores

```sql
-- MAL: explota con ORA-01476 si no hay tareas no canceladas
completed / total_excluding_cancelled
```

Siempre usar `NULLIF(denominador, 0)` para que el resultado sea `NULL` en vez de error cuando el denominador es cero.

### Comparar fechas con hora incluida

```sql
-- MAL: una tarea vencida HOY aparece como atrasada desde las 00:01
WHERE due_date < SYSDATE

-- BIEN: solo compara fechas, no horas
WHERE due_date < TRUNC(SYSDATE)
```

`TRUNC(SYSDATE)` da hoy a la medianoche. `SYSDATE` da el momento exacto en que corre la query.

---

## Definiciones de referencia

| KPI | Definición corta | Unidad |
|-----|-----------------|--------|
| Velocidad de equipo | tareas_completadas / días_activos | tareas/día |
| Tasa de entrega a tiempo | completadas_antes_de_due / total_completadas | % |
| Tiempo de resolución | completed_at - created_at (promedio por prioridad) | horas |
| Tareas vencidas | due_date < hoy AND status NOT IN (completed, cancelled) | cantidad |
| Completion rate | completadas / (total - canceladas) | % |
