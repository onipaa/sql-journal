-- Parameters
\timing on

-- Ensure all tables are analyzed
analyze web_log_noix;
analyze web_log_btree;
analyze web_log_brin;

-- Define common query structure
\set interval_7days '7 days'
\set interval_180days '180 days'

-- Benchmark Query 1: Last 7 Days, Specific Status Codes
\echo 'Benchmark Query 1 - Last 7 Days, Specific Status Codes'

\echo 'No Index:'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log_noix
where created_at >= now() - interval :'interval_7days'
  and status_code in (500, 404)
  and http_method = 'GET'
order by created_at desc limit 100;

\echo 'B-tree Index:'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log_btree
where created_at >= now() - interval :'interval_7days'
  and status_code in (500, 404)
  and http_method = 'GET'
order by created_at desc limit 100;

\echo 'BRIN Index (pages_per_range = 32):'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log_brin
where created_at >= now() - interval :'interval_7days'
  and status_code in (500, 404)
  and http_method = 'GET'
order by created_at desc limit 100;

-- Benchmark Query 2: Specific Status Code with Method
\echo 'Benchmark Query 2 - Specific Status Code with Method'

\echo 'No Index:'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_noix
where status_code = 404 and http_method = 'GET';

\echo 'B-tree Index:'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_btree
where status_code = 404 and http_method = 'GET';

\echo 'BRIN Index (pages_per_range = 32):'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_brin
where status_code = 404 and http_method = 'GET';

-- Benchmark Query 3: Full Range Scan with Sorting
\echo 'Benchmark Query 3 - Full Range Scan with Sorting'

\echo 'No Index:'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_noix
order by created_at desc limit 10000;

\echo 'B-tree Index:'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_btree
order by created_at desc limit 10000;

\echo 'BRIN Index (pages_per_range = 32):'
explain (analyze, buffers)
select id, user_ip, path, created_at
from web_log_brin
order by created_at desc limit 10000;

-- Benchmark Query 4: Large Range Scan (Last 180 Days)
\echo 'Benchmark Query 4 - Large Range Scan (Last 180 Days)'

\echo 'No Index:'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log_noix
where created_at >= now() - interval :'interval_180days';

\echo 'B-tree Index:'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log_btree
where created_at >= now() - interval :'interval_180days';

\echo 'BRIN Index (pages_per_range = 32):'
explain (analyze, buffers)
select id, user_ip, path, http_method, status_code, created_at
from web_log
where created_at >= now() - interval :'interval_180days';

-- End of Benchmark Script
\echo 'Benchmarking Complete.'
