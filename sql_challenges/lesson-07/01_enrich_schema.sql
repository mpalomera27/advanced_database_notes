-- ============================================================
-- Lesson 07: KPI Dashboards
-- File: 01_enrich_schema.sql
-- Purpose: Enrich the tasks table with analytics columns
--
-- Run this in your FreeSQL worksheet after Lesson 06 schema.
-- ============================================================

-- Add columns needed for KPI analysis
ALTER TABLE tasks ADD (
    priority      VARCHAR2(10)  DEFAULT 'medium',
    due_date      DATE,
    completed_at  TIMESTAMP,
    tags          VARCHAR2(200)
);

-- Add check constraint for valid priorities
ALTER TABLE tasks ADD CONSTRAINT chk_task_priority
    CHECK (priority IN ('low', 'medium', 'high', 'critical'));

-- Add check constraint for valid statuses (expanded)
ALTER TABLE tasks DROP CONSTRAINT chk_task_status;
ALTER TABLE tasks ADD CONSTRAINT chk_task_status
    CHECK (status IN ('open', 'in_progress', 'blocked', 'completed', 'cancelled'));

COMMIT;

-- Verify
SELECT column_name, data_type, nullable
FROM   user_tab_columns
WHERE  table_name = 'TASKS'
ORDER  BY column_id;
