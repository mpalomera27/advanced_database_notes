# Diagrama de Esquema — Lección 08

**Sistema OLTP + Data Warehouse con esquema estrella**
ETL desde task_assignments hacia fact_task_daily

---

## Sistema OLTP (fuente de datos)

```
┌─────────────────────────┐
│          users          │
├─────────────────────────┤
│ id         PK IDENTITY  │
│ name       NOT NULL     │
│ email      NOT NULL     │
│ team       NOT NULL     │
│ role       NOT NULL     │
│ created_at TIMESTAMP    │
└─────────┬───────────────┘
          │ 1:N
          │
┌─────────▼───────────────────────────────┐
│                 tasks                   │
├─────────────────────────────────────────┤
│ id           PK IDENTITY                │
│ title        NOT NULL                   │
│ status       CHECK(5 valores válidos)   │
│ priority     CHECK(4 valores válidos)   │
│ assigned_to  FK→users.id               │
│ created_by   FK→users.id               │
│ created_at   TIMESTAMP                  │
│ updated_at   TIMESTAMP                  │
│ completed_at TIMESTAMP                  │
└─────────┬───────────────────────────────┘
          │ 1:N (via trigger)
          │
┌─────────▼───────────────────────────────┐
│           task_assignments              │
├─────────────────────────────────────────┤
│ assignment_id PK IDENTITY               │
│ task_id       FK→tasks.id  NOT NULL     │
│ assigned_to   FK→users.id  NOT NULL     │
│ assigned_by   FK→users.id              │
│ valid_from    TIMESTAMP    NOT NULL     │  ← inicio del período
│ valid_to      TIMESTAMP                 │  ← fin (NULL = vigente)
└─────────────────────────────────────────┘
```

---

## Data Warehouse (destino del ETL)

```
                     ┌──────────────────────────┐
                     │         dim_date         │
                     ├──────────────────────────┤
                     │ date_key  PK (YYYYMMDD)  │
                     │ full_date DATE           │
                     │ year      NUMBER(4)      │
                     │ quarter   NUMBER(1)      │
                     │ month     NUMBER(2)      │
                     │ month_name VARCHAR2(10)  │
                     │ day_name  VARCHAR2(10)   │
                     │ is_weekend NUMBER(1)     │
                     └─────────────┬────────────┘
                                   │
┌──────────────────┐   ┌───────────▼──────────────────────────┐   ┌──────────────────┐
│     dim_user     │   │           fact_task_daily             │   │    dim_status     │
├──────────────────┤   ├───────────────────────────────────────┤   ├──────────────────┤
│ user_key  PK     │   │ fact_key          PK IDENTITY         │   │ status_key  PK   │
│ user_id   (src)  ├──►│ date_key          FK→dim_date         │◄──┤ status_name      │
│ name             │   │ user_key          FK→dim_user         │   │ category         │
│ email            │   │ status_key        FK→dim_status       │   │ (active/done/    │
│ team             │   │ priority          VARCHAR2(10)        │   │  cancelled)      │
│ role             │   │ tasks_created     NUMBER              │   └──────────────────┘
└──────────────────┘   │ tasks_completed   NUMBER              │
                       │ avg_completion_hours NUMBER            │
                       │ UNIQUE(date_key,user_key,             │
                       │        status_key,priority)           │
                       └───────────────────────────────────────┘
```

---

## Flujo ETL entre OLTP y DW

```
OLTP                         ETL (Python/pandas)                    DW
─────────────────────────────────────────────────────────────────────────

tasks          ──┐
                 │  EXTRACT (pd.read_sql)
task_assignments ──►  df_tickets
                 │   df_assignments            TRANSFORM
users          ──┘                              │
                              ┌─────────────────┘
                              │
                              ▼
                     get_agent_at(ticket_id, T)
                     ┌───────────────────────────────┐
                     │ valid_from <= T               │
                     │ AND (valid_to IS NULL          │
                     │      OR valid_to > T)         │
                     └───────────────────────────────┘
                              │
                              ▼
                     Agregar por (date_key, agent_key,
                                  status, priority)
                     → tickets_created
                     → tickets_resolved
                              │
                              │  LOAD (executemany)
                              ▼
                     fact_task_daily  ──► dim_user
                                     ──► dim_date
                                     ──► dim_status
```

---

## La consulta de verificación (Step 7 del ejercicio)

```sql
SELECT
    f.date_key,
    a.agent_name,
    a.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM   fact_ticket_daily f
JOIN   dim_agent a ON a.agent_key = f.agent_key
ORDER  BY f.date_key, a.agent_name;
```

**Caso clave:** Un ticket reasignado de James → Omar debe aparecer así:
- Fila con `date_key=20260405`, `agent=James`, `tickets_created=1`, `tickets_resolved=0`
- Fila con `date_key=20260407`, `agent=Omar`,  `tickets_created=0`, `tickets_resolved=1`

Esto prueba que el ETL resolvió correctamente el agente en cada punto en el tiempo.

---

## Diferencia entre la clave surrogate y la clave fuente

| | Sistema fuente (OLTP) | Data Warehouse |
|---|---|---|
| Clave | `users.id` (IDENTITY) | `dim_user.user_key` (nueva IDENTITY) |
| Control | La app/BD fuente | El DW genera la suya |
| Riesgo | Si borras un user, FK falla | No hay FK al OLTP — DW es independiente |
| Lookup | Directo | ETL mantiene `user_id` para hacer el join |
