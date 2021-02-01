CREATE OR REPLACE VIEW task_metrics (
    task_id,
    task_name,
    last_execution_start_date_time,
    last_execution_end_date_time,
    was_success
)
AS SELECT t.id,
    t.name,
    el.start_date_time,
    el.end_date_time,
    CASE WHEN el.end_date_time ISNULL THEN FALSE
        ELSE TRUE
    END
FROM task as t
LEFT JOIN (
    SELECT task_id,
        MAX(id) as max_execution_log_id
    FROM execution_log
    GROUP BY task_id
) as latest on t.id = latest.task_id
LEFT JOIN execution_log el on latest.max_execution_log_id = el.id;