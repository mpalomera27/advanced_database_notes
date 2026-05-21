-- ============================================================
-- Lesson 07: KPI Dashboards — Class Exercises
-- File: 06_exercises.sql
-- Purpose: Practice defining KPIs, writing queries, and handling edge cases
-- ============================================================


-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================

-- CONTRATO DEL KPI
-- ----------------
-- Pregunta de negocio:
--   ¿Cuántas tareas completa cada equipo por día activo?
--
-- Definición exacta:
--   Velocity = tareas_completadas / dias_activos_del_equipo
--   "Días activos" = días desde la tarea más antigua del equipo hasta HOY
--   Solo cuentan tareas con status = 'completed' y completed_at IS NOT NULL
--   Las tareas canceladas NO cuentan (nunca se entregaron)
--
-- Casos extremos:
--   - Equipo con 0 completadas → velocity = 0 (no NULL, usar NVL)
--   - Equipo recién creado con 1 día activo → denominador mínimo = 1
--     (usamos GREATEST(..., 1) para evitar división por cero)
--   - Tareas sin assignee no afectan este KPI (JOIN lo filtra)
--
-- Unidad: Tareas completadas por día
--
-- ¿Qué puede hacer este KPI engañoso?
--   - Un equipo grande (5 personas) vs uno pequeño (2 personas):
--     el grande casi siempre gana en términos absolutos.
--   - Por eso agregamos una columna normalizada por miembro:
--     tasks_per_member_per_day da una comparación más justa.

WITH team_stats AS (
    SELECT
        t.id                                                    AS team_id,
        t.name                                                  AS team_name,
        COUNT(DISTINCT u.id)                                    AS member_count,
        COUNT(CASE WHEN ts.status = 'completed'
                    AND ts.completed_at IS NOT NULL
               THEN 1 END)                                      AS completed_tasks,
        -- Evitamos que el denominador sea 0 en equipos nuevos
        GREATEST(
            TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)),
            1
        )                                                       AS days_active
    FROM   teams t
    LEFT   JOIN users u  ON u.team_id = t.id
    LEFT   JOIN tasks ts ON ts.assigned_to = u.id
    GROUP  BY t.id, t.name
),
velocities AS (
    SELECT
        team_name,
        member_count,
        completed_tasks,
        ROUND(completed_tasks / days_active, 2)                 AS tasks_per_day,
        ROUND(
            completed_tasks / NULLIF(member_count * days_active, 0),
            2
        )                                                       AS tasks_per_member_per_day
    FROM   team_stats
)
SELECT
    team_name,
    member_count,
    completed_tasks,
    tasks_per_day,
    tasks_per_member_per_day,
    ROUND(AVG(tasks_per_day) OVER (), 2)                        AS avg_velocity,
    CASE
        WHEN tasks_per_day < AVG(tasks_per_day) OVER ()
        THEN 'BELOW AVERAGE'
        ELSE 'OK'
    END                                                         AS velocity_flag
FROM   velocities
ORDER  BY tasks_per_day DESC;


-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================

-- CONTRATO DEL KPI
-- ----------------
-- Pregunta de negocio:
--   ¿Qué porcentaje de tareas se completan a tiempo?
--
-- Definición exacta:
--   On-time = TRUNC(completed_at) <= due_date
--   Base = solo tareas con status='completed' Y due_date IS NOT NULL
--          Y completed_at IS NOT NULL
--   Tareas sin due_date: EXCLUIDAS (no hay contrato de entrega)
--
-- ¿Qué significa "a tiempo"?
--   Una tarea completada a las 23:59 del día de vencimiento → ON TIME
--   Una tarea completada a las 00:01 del día siguiente     → LATE
--   Razón: TRUNC(completed_at) da la fecha sin hora.
--   Si esa fecha > due_date, está tarde. Si es igual o menor, está a tiempo.
--
-- Unidad: Porcentaje (0 a 100)
--
-- ¿Qué puede hacer este KPI engañoso?
--   Si muchas tareas no tienen due_date, el denominador se reduce
--   y la tasa parece mejor de lo que es. Siempre reportar cuántas
--   tareas se excluyeron por falta de due_date.

SELECT
    priority,
    COUNT(*)                                                    AS total_completed,
    COUNT(CASE WHEN TRUNC(completed_at) <= due_date
               THEN 1 END)                                      AS on_time_count,
    ROUND(
        100 * COUNT(CASE WHEN TRUNC(completed_at) <= due_date
                         THEN 1 END)
        / COUNT(*),
        1
    )                                                           AS on_time_rate_pct,
    -- Promedio de horas de retraso (solo para las tareas tardías)
    ROUND(
        AVG(
            CASE
                WHEN TRUNC(completed_at) > due_date
                THEN
                    EXTRACT(DAY    FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 +
                    EXTRACT(HOUR   FROM (completed_at - CAST(due_date AS TIMESTAMP))) +
                    EXTRACT(MINUTE FROM (completed_at - CAST(due_date AS TIMESTAMP))) / 60
            END
        ),
        1
    )                                                           AS avg_late_hours
FROM   tasks
WHERE  status       = 'completed'
  AND  completed_at IS NOT NULL
  AND  due_date     IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;


-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)
-- ============================================================

-- PROBLEMA CON EL ORIGINAL:
--   Mezcla todas las tareas (completadas, abiertas, canceladas).
--   Un equipo con 40 tareas completadas hace meses y 0 tareas activas
--   aparece como el "más ocupado" cuando en realidad está libre.
--
-- MEJORAS:
--   1. Separamos: total_tasks / active_tasks / completion_rate
--   2. Las canceladas NO entran en completion_rate (no son trabajo hecho,
--      son trabajo descartado — incluirlas inflaría el porcentaje)
--   3. health_score da un semáforo rápido del estado del equipo

SELECT
    t.name                                                      AS team_name,
    COUNT(ts.id)                                                AS total_tasks,
    COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked')
               THEN 1 END)                                      AS active_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed'     THEN 1 END)
            / NULLIF(
                COUNT(CASE WHEN ts.status != 'cancelled'  THEN 1 END),
                0
              ),
        1
    )                                                           AS completion_rate_pct,
    CASE
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked')
                        THEN 1 END) > 10  THEN 'Overloaded'
        WHEN COUNT(CASE WHEN ts.status IN ('open','in_progress','blocked')
                        THEN 1 END) >= 5  THEN 'Healthy'
        ELSE                                   'Underutilized'
    END                                                         AS health_score
FROM   teams t
LEFT   JOIN users u  ON u.team_id = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)
-- ============================================================

-- PROBLEMA CON EL ORIGINAL:
--   Promedia todas las prioridades juntas. Un bug crítico resuelto en 2 horas
--   y una tarea de documentación resuelta en 80 horas se mezclan → número
--   sin significado real. Además, no define ningún objetivo (SLA).
--
-- MEJORAS:
--   1. Calculamos por prioridad (cada prioridad tiene su contrato de tiempo)
--   2. Mediana con PERCENTILE_CONT: más robusta que el promedio cuando hay
--      valores extremos (un ticket que tardó 3 semanas jala el promedio)
--   3. MIN y MAX para ver la variabilidad real
--   4. SLA target: objetivo definido por prioridad
--      critical=24h, high=72h, medium=168h (7 días), low=336h (14 días)
--   5. Reportamos count para que el lector sepa si el promedio es confiable
--      (un promedio de 1 sola tarea no dice nada)

SELECT
    priority,
    COUNT(*)                                                    AS completed_count,
    ROUND(AVG(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS avg_hours,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS median_hours,
    ROUND(MIN(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS fastest_hours,
    ROUND(MAX(
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
    ), 1)                                                       AS slowest_hours,
    CASE priority
        WHEN 'critical' THEN 24
        WHEN 'high'     THEN 72
        WHEN 'medium'   THEN 168
        WHEN 'low'      THEN 336
    END                                                         AS sla_target_hours,
    CASE
        WHEN ROUND(AVG(
                EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
                EXTRACT(HOUR   FROM (completed_at - created_at)) +
                EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
             ), 1)
             <=
             CASE priority
                 WHEN 'critical' THEN 24
                 WHEN 'high'     THEN 72
                 WHEN 'medium'   THEN 168
                 WHEN 'low'      THEN 336
             END
        THEN 'SLA MET'
        ELSE 'SLA MISSED'
    END                                                         AS sla_status
FROM   tasks
WHERE  status       = 'completed'
  AND  completed_at IS NOT NULL
GROUP  BY priority
ORDER  BY CASE priority
              WHEN 'critical' THEN 1
              WHEN 'high'     THEN 2
              WHEN 'medium'   THEN 3
              WHEN 'low'      THEN 4
          END;


-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)
-- ============================================================

-- PROBLEMA CON EL ORIGINAL:
--   Solo devuelve un número (COUNT). No dice quién debe qué, qué tan
--   atrasado está ni cuál es el impacto real. Una tarea crítica con
--   15 días de retraso y una tarea baja con 1 día de retraso tienen el
--   mismo peso en el COUNT original — eso es peligroso para el negocio.
--
-- MEJORAS:
--   1. Reporte detallado: título, responsable, equipo, prioridad, días
--   2. Columna "severity" que combina prioridad + días de retraso
--   3. Ordenado por gravedad → los más críticos primero
--   4. Query de resumen con ROLLUP al final

-- Parte 1: Detalle de tareas vencidas
WITH overdue_detail AS (
    SELECT
        ts.title,
        u.full_name                                             AS assignee,
        t.name                                                  AS team,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date                            AS days_overdue,
        CASE
            WHEN ts.priority = 'critical'
                 THEN 'CRITICAL'
            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2
                 THEN 'HIGH'
            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5
                 THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                     AS severity
    FROM   tasks ts
    JOIN   users u ON u.id = ts.assigned_to
    JOIN   teams t ON t.id = u.team_id
    WHERE  ts.due_date < TRUNC(SYSDATE)
      AND  ts.status NOT IN ('completed', 'cancelled')
      AND  ts.due_date IS NOT NULL
)
SELECT
    title,
    assignee,
    team,
    priority,
    due_date,
    days_overdue,
    severity
FROM   overdue_detail
ORDER  BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        ELSE                 4
    END,
    days_overdue DESC;

-- Parte 2: Resumen por severity usando ROLLUP
SELECT
    CASE
        WHEN GROUPING(severity) = 1 THEN '--- TOTAL OVERDUE ---'
        ELSE severity
    END                                                         AS severity,
    COUNT(*)                                                    AS overdue_count,
    ROUND(AVG(days_overdue), 1)                                 AS avg_days_overdue
FROM (
    SELECT
        TRUNC(SYSDATE) - ts.due_date                            AS days_overdue,
        CASE
            WHEN ts.priority = 'critical'
                 THEN 'CRITICAL'
            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2
                 THEN 'HIGH'
            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5
                 THEN 'MEDIUM'
            ELSE 'LOW'
        END                                                     AS severity
    FROM   tasks ts
    WHERE  ts.due_date < TRUNC(SYSDATE)
      AND  ts.status NOT IN ('completed', 'cancelled')
      AND  ts.due_date IS NOT NULL
)
GROUP  BY ROLLUP(severity)
ORDER  BY
    CASE
        WHEN GROUPING(severity) = 1 THEN 99
        WHEN severity = 'CRITICAL'  THEN 1
        WHEN severity = 'HIGH'      THEN 2
        WHEN severity = 'MEDIUM'    THEN 3
        ELSE                             4
    END;


-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================

-- PROBLEMA:
--   COUNT(ts.id) cuenta TODAS las tareas asignadas al usuario,
--   sin importar si las completó o si siguen abiertas hace meses.
--   Un usuario con 10 tareas abiertas que no ha avanzado en nada
--   y uno que completó 10 tareas tienen el mismo "score".
--   Además, no distingue entre una tarea simple (low) y una compleja (critical).
--   Resultado: el KPI premia la acumulación, no la productividad.
--
-- SOLUCIÓN:
--   Medimos "tareas completadas ponderadas por prioridad, por día activo".
--   Pesos: critical=4, high=3, medium=2, low=1
--   Esto premia resolver tareas difíciles más que fáciles.
--   Dividimos entre días activos para normalizar (un usuario nuevo vs veterano).

SELECT
    u.full_name,
    COUNT(CASE WHEN ts.status = 'completed' THEN 1 END)         AS completed_tasks,
    SUM(CASE
        WHEN ts.status = 'completed'
        THEN CASE ts.priority
                 WHEN 'critical' THEN 4
                 WHEN 'high'     THEN 3
                 WHEN 'medium'   THEN 2
                 WHEN 'low'      THEN 1
                 ELSE                 0
             END
        ELSE 0
    END)                                                         AS weighted_score,
    GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1)      AS days_active,
    ROUND(
        SUM(CASE
            WHEN ts.status = 'completed'
            THEN CASE ts.priority
                     WHEN 'critical' THEN 4
                     WHEN 'high'     THEN 3
                     WHEN 'medium'   THEN 2
                     WHEN 'low'      THEN 1
                     ELSE                 0
                 END
            ELSE 0
        END)
        /
        GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1),
        2
    )                                                            AS productivity_score
FROM   users u
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY u.id, u.full_name
ORDER  BY productivity_score DESC;


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================

-- PROBLEMA:
--   AVG(ts.id) promedia el ID numérico de la tarea.
--   El ID es solo un número de secuencia autoincremental —
--   no tiene ningún significado de negocio.
--   "El promedio del ID de tarea es 17.5" no quiere decir absolutamente nada.
--   Es un error clásico: confundir un identificador técnico con una métrica.
--
-- SOLUCIÓN:
--   "Eficiencia" = tareas_completadas / total_tareas (excluyendo canceladas)
--   Esto mide qué proporción del trabajo asignado realmente se entregó.

SELECT
    t.name                                                       AS team_name,
    COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END)         AS total_valid_tasks,
    COUNT(CASE WHEN ts.status = 'completed'  THEN 1 END)         AS completed_tasks,
    ROUND(
        100 * COUNT(CASE WHEN ts.status = 'completed'  THEN 1 END)
            / NULLIF(
                COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END),
                0
              ),
        1
    )                                                            AS efficiency_pct
FROM   teams t
LEFT   JOIN users u  ON u.team_id = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY efficiency_pct DESC NULLS LAST;


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================

-- PROBLEMA:
--   priority es VARCHAR2 — no puedes multiplicar texto por 10.
--   due_date es DATE — no puedes sumarle una cadena de texto.
--   El query original falla con un error de tipos en Oracle.
--   Aunque funcionara, "prioridad * 10 + fecha" no tiene unidad ni sentido:
--   ¿qué significa sumar un número y una fecha? ¿En qué escala?
--
-- SOLUCIÓN:
--   Convertimos priority a un número usando CASE (critical=4, high=3...).
--   Calculamos days_until_due = due_date - TRUNC(SYSDATE).
--   Si el valor es negativo, la tarea ya venció (más urgente aún).
--   urgency_index = peso_prioridad * 10 - days_until_due
--   A mayor índice → más urgente.
--   (Multiplicamos el peso por 10 para que la prioridad domine sobre el tiempo)

SELECT
    title,
    priority,
    due_date,
    due_date - TRUNC(SYSDATE)                                    AS days_until_due,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high'     THEN 3
        WHEN 'medium'   THEN 2
        WHEN 'low'      THEN 1
        ELSE                 0
    END                                                          AS priority_weight,
    (CASE priority
         WHEN 'critical' THEN 4
         WHEN 'high'     THEN 3
         WHEN 'medium'   THEN 2
         WHEN 'low'      THEN 1
         ELSE                 0
     END * 10)
    - (due_date - TRUNC(SYSDATE))                                AS urgency_index
FROM   tasks
WHERE  status NOT IN ('completed', 'cancelled')
  AND  due_date IS NOT NULL
ORDER  BY urgency_index DESC;


-- ============================================================
-- PART D: Summary Dashboard — Single Query, All Metrics
-- ============================================================

-- Estrategia: CTE "base" que enriquece cada tarea con columnas derivadas.
-- Luego CTEs especializados sacan cada métrica.
-- La query final hace CROSS JOIN para unir todo en una sola fila.
-- Este es el patrón que usan herramientas BI reales (Metabase, Looker, etc.).

WITH base AS (
    -- Cada tarea enriquecida con columnas calculadas
    SELECT
        ts.id,
        ts.status,
        ts.priority,
        ts.due_date,
        ts.created_at,
        ts.completed_at,
        u.team_id,
        t.name                                                   AS team_name,
        -- ¿Está activa?
        CASE WHEN ts.status IN ('open', 'in_progress', 'blocked')
             THEN 1 END                                          AS is_active,
        -- ¿Está vencida?
        CASE WHEN ts.due_date < TRUNC(SYSDATE)
              AND ts.status NOT IN ('completed', 'cancelled')
              AND ts.due_date IS NOT NULL
             THEN 1 END                                          AS is_overdue,
        -- Horas de resolución (solo completadas)
        CASE WHEN ts.status = 'completed' AND ts.completed_at IS NOT NULL
             THEN EXTRACT(DAY    FROM (ts.completed_at - ts.created_at)) * 24
                + EXTRACT(HOUR   FROM (ts.completed_at - ts.created_at))
                + EXTRACT(MINUTE FROM (ts.completed_at - ts.created_at)) / 60
        END                                                      AS resolution_hours,
        -- Días de retraso (solo vencidas)
        CASE WHEN ts.due_date < TRUNC(SYSDATE)
              AND ts.status NOT IN ('completed', 'cancelled')
              AND ts.due_date IS NOT NULL
             THEN TRUNC(SYSDATE) - ts.due_date
        END                                                      AS days_overdue
    FROM   tasks ts
    LEFT   JOIN users u ON u.id = ts.assigned_to
    LEFT   JOIN teams t ON t.id = u.team_id
),
totals AS (
    SELECT
        COUNT(*)                                                 AS total_tasks,
        COUNT(CASE WHEN status = 'completed' THEN 1 END)         AS completed_tasks,
        COUNT(is_active)                                         AS active_tasks,
        COUNT(is_overdue)                                        AS overdue_tasks,
        ROUND(
            100 * COUNT(CASE WHEN status = 'completed' THEN 1 END)
                / NULLIF(
                    COUNT(CASE WHEN status != 'cancelled' THEN 1 END),
                    0
                  ),
            1
        )                                                        AS completion_rate_pct,
        ROUND(AVG(resolution_hours), 1)                          AS avg_resolution_hours,
        ROUND(AVG(days_overdue), 1)                              AS avg_days_overdue
    FROM   base
),
top_priority AS (
    -- Prioridad más común entre tareas activas
    SELECT priority AS most_common_priority
    FROM (
        SELECT
            priority,
            RANK() OVER (ORDER BY COUNT(*) DESC)                 AS rnk
        FROM   base
        WHERE  is_active IS NOT NULL
        GROUP  BY priority
    )
    WHERE rnk = 1
    FETCH FIRST 1 ROW ONLY
),
top_team AS (
    -- Equipo con más tareas activas
    SELECT team_name AS busiest_team
    FROM (
        SELECT
            team_name,
            RANK() OVER (ORDER BY COUNT(*) DESC)                 AS rnk
        FROM   base
        WHERE  is_active IS NOT NULL
        GROUP  BY team_name
    )
    WHERE rnk = 1
    FETCH FIRST 1 ROW ONLY
)
SELECT
    t.total_tasks,
    t.completed_tasks,
    t.active_tasks,
    t.overdue_tasks,
    t.completion_rate_pct,
    t.avg_resolution_hours,
    t.avg_days_overdue,
    p.most_common_priority,
    tt.busiest_team
FROM   totals t
CROSS  JOIN top_priority p
CROSS  JOIN top_team     tt;
