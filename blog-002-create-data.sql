create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

drop table if exists web_log;
create table web_log (
    id uuid primary key default uuid_generate_v1(),
    user_ip      inet,
    user_agent   text,
    path         text,
    http_method  text,
    status_code  int,
    response_ms  int,
    created_at   timestamptz default now()
);

-- generates 1,000,000,000 rows
-- widen range to 1 year
-- complete 20 loops of 50,000,000 for 1,000,000,000 rows
SET enable_parallel_append = on;
SET enable_parallel_hash = on;
SET enable_parallel_seqscan = on;
SET enable_parallel_vacuum = on;
SET parallel_leader_participation = on;
SET max_parallel_workers_per_gather = 8;

do $$
begin
    for i in 1 .. 20 loop
        with data as (
            select  ('192.' || (random()*255)::int || '.' || (random()*255)::int || '.' || (random()*255)::int)::inet as user_ip,
                    ('Mozilla/5.0 ' || md5(random()::text)) as user_agent,
                    '/page/' || (1 + floor(random() * 100))::int as path,
                    (array['GET','POST','PUT','DELETE'])[floor(random()*4+1)] as http_method,
                    (array[200, 201, 204, 301, 302, 400, 401, 403, 404, 500])[floor(random()*10+1)] as status_code,
                    (random()*1000)::int as response_ms,
                    now() - (random() * interval '365 days') as created_at
              from  generate_series(1, 50000000)
        )
        insert into web_log (user_ip, user_agent, path, http_method, status_code, response_ms, created_at)
        select * from data;
    end loop;
end;
$$;

-- adding order by as per suggestion from external sources
create table web_log_brin as select * from web_log order by created_at, status_code, http_method;
create table web_log_btree as select * from web_log order by created_at, status_code, http_method;
create table web_log_noix as select * from web_log order by created_at, status_code, http_method;

create index concurrently if not exists index brin_web_log_multi
    on web_log_brin using brin (id, status_code, created_at, http_method)
    with (pages_per_range = 8);

create index concurrently if not exists btree_web_log_multi
    on web_log_btree (created_at, status_code, http_method, id);

select brin_summarize_new_values('brin_web_log_multi');

vacuum analyze web_log_brin;
vacuum full analyze web_log_btree;
vacuum full analyze web_log_noix;

select  schemaname
     ,  relname
     ,  pg_size_pretty(pg_total_relation_size(relid)) total_size_ix_and_table_and_toast
     ,  pg_size_pretty(pg_relation_size(relid)) table_size
     ,  pg_size_pretty(pg_indexes_size(relid)) index_size
     ,  pg_size_pretty(pg_table_size(relid))  toast_size
  from  pg_statio_user_tables
 where  relname like '%web_log%';
