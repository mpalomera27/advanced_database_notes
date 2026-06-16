-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- File: 04_exercise_assignment_history.sql
-- Purpose: Exercise — Support ticketing system with ETL
--
-- Steps 1-5 and 7 resueltos.
-- Step 6 (ETL en Python/pandas) está en 03_etl_pipeline.ipynb
-- ============================================================


-- ============================================================
-- STEP 1 — Source Tables (OLTP)
-- ============================================================
--
-- Sistema: tickets de soporte. Los tickets pueden reasignarse
-- entre agentes. Necesitamos saber quién fue el agente al momento
-- de crear el ticket (crédito de creación) y quién lo resolvió
-- (crédito de resolución) — que pueden ser personas distintas.

-- Limpieza previa
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE agents';             EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent';          EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Tabla de agentes (fuente de datos del sistema OLTP)
CREATE TABLE agents (
    id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR2(100) NOT NULL,
    email      VARCHAR2(200) NOT NULL,
    team       VARCHAR2(50)  NOT NULL
);

-- Estado actual del ticket
CREATE TABLE tickets (
    ticket_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200)  NOT NULL,
    status       VARCHAR2(20)   DEFAULT 'open'   NOT NULL,
    priority     VARCHAR2(10)   DEFAULT 'medium' NOT NULL,
    assigned_to  NUMBER         REFERENCES agents(id),
    created_at   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at   TIMESTAMP      DEFAULT SYSTIMESTAMP,
    resolved_at  TIMESTAMP,
    CONSTRAINT chk_ticket_status   CHECK (status IN ('open','in_progress','resolved','cancelled')),
    CONSTRAINT chk_ticket_priority CHECK (priority IN ('low','medium','high','critical'))
);

-- Historial de asignaciones: quién tenía el ticket en cada momento
CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER    NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER    NOT NULL REFERENCES agents(id),
    assigned_by   NUMBER    REFERENCES agents(id),
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP -- NULL = asignación vigente
);

-- Índice para búsqueda punto en el tiempo (ETL lo usa frecuentemente)
CREATE INDEX idx_tkt_assign_lookup
ON ticket_assignments (ticket_id, valid_from, valid_to);


-- ============================================================
-- STEP 3 — Trigger
-- (creado ANTES de insertar tickets para que los INSERT
--  disparen el log automáticamente)
-- ============================================================
--
-- El trigger reproduce el mismo patrón que la clase:
-- INSERT → registra asignación inicial
-- UPDATE de assigned_to → cierra la anterior y abre la nueva

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Primer asignado: registrar desde la fecha de creación
        INSERT INTO ticket_assignments
            (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES
            (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at);

    ELSIF UPDATING THEN
        -- Cerrar la asignación anterior
        UPDATE ticket_assignments
           SET valid_to = :NEW.updated_at
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        -- Abrir la nueva asignación
        INSERT INTO ticket_assignments
            (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES
            (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.updated_at);
    END IF;
END;
/


-- ============================================================
-- STEP 2 — Sample Data
-- ============================================================
--
-- Nota: los agentes se insertan primero (no tienen trigger).
-- Los tickets se insertan DESPUÉS del trigger para que el log
-- se llene automáticamente.

-- 4 agentes de soporte en dos niveles (Tier 1 = front-line, Tier 2 = expertos)
INSERT INTO agents (name, email, team) VALUES ('Sofia Ramirez', 'sofia@support.com', 'Tier 1');
INSERT INTO agents (name, email, team) VALUES ('James Wu',      'james@support.com', 'Tier 1');
INSERT INTO agents (name, email, team) VALUES ('Priya Patel',   'priya@support.com', 'Tier 2');
INSERT INTO agents (name, email, team) VALUES ('Omar Hassan',   'omar@support.com',  'Tier 2');
COMMIT;

-- 5 tickets con historiales variados
-- Ticket 1: resuelto directamente por el primer asignado
INSERT INTO tickets (title, status, priority, assigned_to, created_at, updated_at, resolved_at)
VALUES ('Login page crashes on mobile',
        'resolved', 'critical', 3,
        TIMESTAMP '2026-04-01 09:00:00',
        TIMESTAMP '2026-04-01 14:30:00',
        TIMESTAMP '2026-04-01 14:30:00');

-- Ticket 2: asignado a Sofia, resuelto por ella (sin reasignación)
INSERT INTO tickets (title, status, priority, assigned_to, created_at, updated_at, resolved_at)
VALUES ('Password reset email not sent',
        'resolved', 'high', 1,
        TIMESTAMP '2026-04-02 10:00:00',
        TIMESTAMP '2026-04-03 11:00:00',
        TIMESTAMP '2026-04-03 11:00:00');

-- Ticket 3: en progreso, aún abierto
INSERT INTO tickets (title, status, priority, assigned_to, created_at, updated_at, resolved_at)
VALUES ('CSV export produces empty file',
        'in_progress', 'medium', 2,
        TIMESTAMP '2026-04-03 11:00:00',
        TIMESTAMP '2026-04-03 11:00:00',
        NULL);

-- Ticket 4: abierto, sin resolver todavía
INSERT INTO tickets (title, status, priority, assigned_to, created_at, updated_at, resolved_at)
VALUES ('Dashboard loads slowly for large accounts',
        'open', 'high', 3,
        TIMESTAMP '2026-04-04 09:00:00',
        TIMESTAMP '2026-04-04 09:00:00',
        NULL);

-- Ticket 5: SERÁ REASIGNADO en la prueba del trigger
-- Creado con James (id=2), luego transferido a Omar (id=4)
INSERT INTO tickets (title, status, priority, assigned_to, created_at, updated_at, resolved_at)
VALUES ('Button text truncated in Spanish locale',
        'resolved', 'low', 2,
        TIMESTAMP '2026-04-05 10:00:00',
        TIMESTAMP '2026-04-05 10:00:00',
        NULL);

COMMIT;

-- Prueba del trigger: reasignar ticket 5 de James → Omar
-- El trigger debe cerrar la asignación de James y abrir la de Omar
UPDATE tickets
SET    assigned_to = 4,
       updated_at  = TIMESTAMP '2026-04-06 09:00:00',
       resolved_at = TIMESTAMP '2026-04-07 16:00:00',
       status      = 'resolved'
WHERE  ticket_id   = 5;

COMMIT;

-- Verificar historial del ticket 5 (debe mostrar 2 filas)
SELECT
    ta.assignment_id,
    t.title,
    a.name                                              AS agent_name,
    ta.valid_from,
    ta.valid_to,
    CASE WHEN ta.valid_to IS NULL THEN 'actual' ELSE 'histórica' END AS estado
FROM   ticket_assignments ta
JOIN   tickets t ON t.ticket_id = ta.ticket_id
JOIN   agents  a ON a.id        = ta.assigned_to
WHERE  ta.ticket_id = 5
ORDER  BY ta.valid_from;


-- ============================================================
-- STEP 4 — Data Warehouse Tables (Star Schema)
-- ============================================================
--
-- dim_agent: dimensión desnormalizada del agente.
--   - agent_key es la clave surrogate (generada por DW, sin relación con agents.id)
--   - agent_id es el ID del sistema fuente (para hacer el lookup en ETL)
--
-- fact_ticket_daily: tabla de hechos con granularidad diaria.
--   - Una fila por (fecha, agente, estado, prioridad)
--   - tickets_created: crédito va al agente asignado al momento de created_at
--   - tickets_resolved: crédito va al agente asignado al momento de resolved_at

CREATE TABLE dim_agent (
    agent_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id   NUMBER        NOT NULL,  -- fuente: agents.id
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50)  NOT NULL,
    CONSTRAINT uq_dim_agent_source UNIQUE (agent_id)
);

CREATE TABLE fact_ticket_daily (
    fact_key          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key          NUMBER       NOT NULL,  -- YYYYMMDD
    agent_key         NUMBER       NOT NULL REFERENCES dim_agent(agent_key),
    status            VARCHAR2(20) NOT NULL,
    priority          VARCHAR2(10) NOT NULL,
    tickets_created   NUMBER       DEFAULT 0,
    tickets_resolved  NUMBER       DEFAULT 0,
    CONSTRAINT uq_fact_ticket UNIQUE (date_key, agent_key, status, priority)
);


-- ============================================================
-- STEP 5 — Populate dim_agent
-- ============================================================
--
-- En producción esto lo hace el ETL (Python).
-- Aquí lo hacemos manualmente para tener datos listos para Step 7.

INSERT INTO dim_agent (agent_id, agent_name, team)
SELECT id, name, team FROM agents;

COMMIT;

-- Verificar que los surrogate keys se generaron
SELECT agent_key, agent_id, agent_name, team
FROM   dim_agent
ORDER  BY agent_key;


-- ============================================================
-- STEP 7 — Verify
-- ============================================================
--
-- Después de correr el ETL (Step 6 en el notebook), este query
-- une fact_ticket_daily con dim_agent para mostrar el resultado.
--
-- Caso clave a verificar: el ticket 5 fue creado por James (agent_id=2)
-- y resuelto por Omar (agent_id=4). La fila de tickets_created debe
-- aparecer bajo James, la de tickets_resolved bajo Omar.

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
ORDER  BY f.date_key, a.agent_name, f.priority;

-- Resumen rápido por agente
SELECT
    a.agent_name,
    a.team,
    SUM(f.tickets_created)   AS total_created,
    SUM(f.tickets_resolved)  AS total_resolved
FROM   fact_ticket_daily f
JOIN   dim_agent a ON a.agent_key = f.agent_key
GROUP  BY a.agent_name, a.team
ORDER  BY total_resolved DESC;
