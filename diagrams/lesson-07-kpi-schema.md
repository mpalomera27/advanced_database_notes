# Diagrama de Esquema — Lección 07

**KPI Dashboard sobre sistema de gestión de tareas**
Versión enriquecida de la tabla `tasks` (columnas agregadas en `01_enrich_schema.sql`)

---

## Cambios al esquema respecto a Lección 06

La tabla `tasks` recibe cuatro columnas nuevas para soportar análisis temporal y de prioridad:

| Columna | Tipo | Propósito |
|---------|------|-----------|
| `priority` | VARCHAR2(10) DEFAULT 'medium' | Clasificación de urgencia |
| `due_date` | DATE | Fecha límite de entrega |
| `completed_at` | TIMESTAMP | Momento exacto de finalización |
| `tags` | VARCHAR2(200) | Etiquetas de categorización libre |

También se reemplaza el constraint de `status` para aceptar el nuevo valor `cancelled`.

---

## Esquema completo

```
┌─────────────────────┐
│        teams        │
├─────────────────────┤
│ id   PK            │
│ name NOT NULL      │
└────────┬────────────┘
         │ 1
         │
         │ N
┌────────▼────────────┐
│        users        │
├─────────────────────┤
│ id        PK       │
│ username  NOT NULL  │
│ full_name NOT NULL  │
│ email     NOT NULL  │
│ team_id   FK→teams  │
└────────┬────────────┘
         │ 1
         │
         │ N
┌────────▼────────────────────────────────────────────────┐
│                         tasks                           │
├─────────────────────────────────────────────────────────┤
│ id           PK                                         │
│ title        NOT NULL                                   │
│ description                                             │
│ status       CHECK('open','in_progress','blocked',      │
│                    'completed','cancelled')             │
│ priority     CHECK('low','medium','high','critical')    │  ← NUEVO
│              DEFAULT 'medium'                           │
│ assigned_to  FK→users                                   │
│ created_at   TIMESTAMP DEFAULT SYSTIMESTAMP             │
│ due_date     DATE                                       │  ← NUEVO
│ completed_at TIMESTAMP                                  │  ← NUEVO
│ tags         VARCHAR2(200)                              │  ← NUEVO
└─────────────────────────────────────────────────────────┘
```

---

## Flujo de estados de una tarea

```
            ┌─────────┐
  Crear ──► │  open   │
            └────┬────┘
                 │
         ┌───────▼───────┐
         │  in_progress  │
         └───────┬───────┘
                 │
        ┌────────┤
        │        │
   ┌────▼───┐  ┌─▼──────────┐
   │ blocked│  │ completed  │ ← se registra completed_at
   └────┬───┘  └────────────┘
        │
   ┌────▼──────┐
   │ cancelled │ ← no se registra completed_at
   └───────────┘
```

---

## Relaciones entre tablas para KPIs

Para calcular cualquier KPI que involucre equipos, la cadena de JOINs es siempre:

```
teams → users → tasks
```

Usar `LEFT JOIN` desde `teams` garantiza que equipos sin tareas aparezcan con conteo 0, en lugar de desaparecer del resultado (lo que haría un `INNER JOIN`).

```sql
FROM   teams t
LEFT   JOIN users u  ON u.team_id  = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
```

---

## Columnas derivadas clave (usadas en el dashboard)

| Columna derivada | Fórmula |
|-----------------|---------|
| `is_active` | `CASE WHEN status IN ('open','in_progress','blocked') THEN 1 END` |
| `is_overdue` | `CASE WHEN due_date < TRUNC(SYSDATE) AND status NOT IN ('completed','cancelled') THEN 1 END` |
| `resolution_hours` | `EXTRACT(DAY FROM (completed_at - created_at)) * 24 + EXTRACT(HOUR ...)` |
| `days_overdue` | `TRUNC(SYSDATE) - due_date` (solo si is_overdue) |
| `priority_weight` | `CASE priority WHEN 'critical' THEN 4 WHEN 'high' THEN 3 ...` |
