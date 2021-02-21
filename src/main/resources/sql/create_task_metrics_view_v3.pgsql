DROP VIEW task_metrics;

CREATE VIEW task_metrics (
    task_id,
    task_name,
    task_display_name,
    last_execution_start_date_time,
    last_execution_end_date_time,
    was_success,
    current_status
)
AS SELECT t.id,
    t.name,
    t.display_name,
    el.start_date_time,
    el.end_date_time,
    CASE WHEN er.id ISNULL THEN TRUE
        ELSE FALSE
    END,
    CASE WHEN er.id IS NOT NULL THEN 'Last run ended in failure'
        WHEN el.end_date_time IS NOT NULL THEN 'Ready'
        WHEN esl.start_date_time IS NOT NULL
            AND esl.end_date_time IS NULL
            AND es.name IS NOT NULL
        THEN 'Step "' || es.name || '" has been running for ' ||
            CAST(EXTRACT(EPOCH FROM (NOW() - esl.start_date_time)) AS text) ||
            ' seconds (data pulled at ' || TO_CHAR(NOW(), 'HH12:MI:SS') || ')'
        ELSE 'Status cannot be determined' END
FROM task AS t
LEFT JOIN (
    SELECT task_id,
        MAX(id) as max_execution_log_id
    FROM execution_log
    GROUP BY task_id
) AS latest ON t.id = latest.task_id
LEFT JOIN execution_log el on latest.max_execution_log_id = el.id
LEFT JOIN (
    SELECT execution_log_id,
        MAX(id) AS max_execution_step_log_id
    FROM execution_step_log
    GROUP BY execution_log_id
) AS latest_step ON latest.max_execution_log_id = latest_step.execution_log_id
LEFT JOIN execution_step_log esl ON esl.id = latest_step.max_execution_step_log_id
LEFT JOIN execution_step es ON esl.execution_step_id = es.id
LEFT JOIN execution_error er ON esl.id = er.execution_step_log_id;