\echo Використання індексів у поточній базі
SELECT relname AS table_name, indexrelname AS index_name,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE indexrelname LIKE 'lab05%'
ORDER BY idx_scan DESC, table_name, index_name;

\echo Запити з найбільшим середнім часом виконання
SELECT round(mean_exec_time::numeric, 3) AS avg_ms,
       round(total_exec_time::numeric, 3) AS total_ms,
       round(max_exec_time::numeric, 3) AS max_ms, calls,
       left(regexp_replace(query, '\s+', ' ', 'g'), 100) AS query
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
ORDER BY mean_exec_time DESC
LIMIT 10;
