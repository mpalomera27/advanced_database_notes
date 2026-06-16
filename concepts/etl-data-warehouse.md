# ETL y Data Warehouse

## Mi entendimiento

Un sistema OLTP (Online Transaction Processing) está diseñado para registrar eventos rápidamente: crear un ticket, actualizar un estado, asignar un usuario. Las tablas están normalizadas para evitar duplicados y los índices están optimizados para writes.

Un Data Warehouse (DW) es lo opuesto: está diseñado para leer y analizar. Las tablas están desnormalizadas (más redundancia) para que los queries de reporte sean rápidos. Se alimenta del OLTP mediante un proceso llamado ETL.

---

## OLTP vs Data Warehouse

| Característica | OLTP | Data Warehouse |
|---|---|---|
| Propósito | Registrar operaciones | Analizar historia |
| Diseño | Normalizado (3NF) | Desnormalizado (estrella) |
| Operación dominante | INSERT / UPDATE | SELECT con agregaciones |
| Granularidad | Evento individual | Agregado por período |
| Historial | Actual (o poco) | Años de historia |
| Usuarios | Aplicaciones, triggers | Analistas, dashboards |

---

## El proceso ETL

**Extract (Extraer):** Leer los datos del sistema fuente tal como están.
En Python: `pd.read_sql("SELECT ...", conexion)`.

**Transform (Transformar):** Limpiar, resolver ambigüedades, combinar tablas,
calcular métricas derivadas. Esta es la fase más compleja:
- Resolver el agente punto en el tiempo (historial de asignaciones)
- Convertir fechas a claves enteras (YYYYMMDD)
- Agrupar por (fecha, usuario, estado, prioridad)

**Load (Cargar):** Insertar los datos transformados en las tablas del DW.
En Python: `cursor.executemany(sql, lista_de_filas)` — más eficiente que un INSERT por fila.

---

## Esquema estrella (Star Schema)

El esquema estrella tiene dos tipos de tablas:

### Tabla de hechos (fact table)
- Contiene las métricas numéricas (counts, sums, averages)
- Tiene claves foráneas hacia todas las dimensiones
- Una fila = un nivel de **granularidad** definido (ej: un día + un usuario + un estado + una prioridad)
- Crece rápido (muchas filas, millones en producción)

### Tablas de dimensión (dim tables)
- Contienen los atributos descriptivos (nombres, categorías, jerarquías)
- Son relativamente pequeñas y estables
- Ejemplos: `dim_user`, `dim_date`, `dim_status`, `dim_agent`

```
                    ┌──────────┐
                    │ dim_date │
                    └────┬─────┘
                         │
┌──────────┐    ┌────────▼──────────┐    ┌────────────┐
│ dim_user ├───►│  fact_task_daily  │◄───┤ dim_status │
└──────────┘    └───────────────────┘    └────────────┘
```

---

## Claves surrogate (Surrogate Keys)

El DW genera sus propias claves primarias (`user_key`, `agent_key`, `date_key`) independientes de las claves del sistema fuente (`user_id`, `agent_id`).

Por qué:
- Si el sistema fuente reutiliza IDs o los cambia, el DW no se rompe
- Si borras un usuario del OLTP, el historial en el DW permanece intacto
- Permite rastrear múltiples versiones del mismo objeto (SCD Tipo 2)

---

## Historial temporal: valid_from / valid_to

Cuando algo cambia con el tiempo (a quién está asignado un ticket, cuál es el precio de un producto, en qué equipo trabaja un usuario), necesitas saber el valor en un **punto específico del tiempo**.

El patrón `valid_from / valid_to` resuelve esto:

```sql
-- ¿Quién tenía el ticket en el momento T?
SELECT assigned_to
FROM   ticket_assignments
WHERE  ticket_id  = :ticket_id
  AND  valid_from <= :T
  AND  (valid_to IS NULL OR valid_to > :T);
```

- `valid_from` = momento en que empezó a ser válida esa asignación
- `valid_to` = momento en que dejó de ser válida (`NULL` = sigue vigente)

Este patrón se llama **Slowly Changing Dimension Type 2 (SCD-2)** en la literatura de Data Warehousing.

---

## dim_date: por qué se pre-llena

Calcular si una fecha es fin de semana, qué trimestre es, o cómo se llama el mes, requiere funciones de SQL (`TO_CHAR`, `EXTRACT`, etc.) que se ejecutan para **cada fila** de cada query.

Con `dim_date` pre-poblada, esa operación se hace **una sola vez** al crear la tabla:

```sql
-- En lugar de esto en cada query:
TO_CHAR(fecha, 'Day') AS day_name,
CASE WHEN TO_NUMBER(TO_CHAR(fecha,'D')) IN (1,7) THEN 1 ELSE 0 END AS is_weekend

-- Solo haces esto:
d.day_name,
d.is_weekend
FROM fact JOIN dim_date d ON d.date_key = fact.date_key
```

---

## Granularidad del fact

La granularidad define qué representa **una fila** en la tabla de hechos. Es la decisión más importante en el diseño de un DW.

Ejemplo en esta lección:
- **Grano**: un día + un usuario + un estado de tarea + una prioridad
- **Lo que mide**: cuántas tareas se crearon y cuántas se completaron en esa combinación

Si defines el grano muy grueso (ej: solo por mes y equipo), pierdes detalle.
Si lo defines muy fino (ej: por segundo y tarea individual), la tabla crece demasiado y las queries son lentas.

---

## Trigger AFTER INSERT OR UPDATE

Un trigger es código PL/SQL que Oracle ejecuta automáticamente cuando ocurre un evento en una tabla. En esta lección lo usamos para llenar el historial de asignaciones sin que la aplicación tenga que hacer nada.

```sql
CREATE OR REPLACE TRIGGER trg_task_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tasks
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Nueva tarea: registrar asignación inicial
        INSERT INTO task_assignments (...) VALUES (:NEW.id, :NEW.assigned_to, ...);
    ELSIF UPDATING THEN
        -- Reasignación: cerrar la anterior y abrir la nueva
        UPDATE task_assignments SET valid_to = :NEW.updated_at WHERE ...;
        INSERT INTO task_assignments (...) VALUES (:NEW.id, :NEW.assigned_to, ...);
    END IF;
END;
```

Importante: se usa `AFTER` (no `BEFORE`) porque los valores generados por la BD
(como el `id` de una columna `IDENTITY`) solo están disponibles después del INSERT.
