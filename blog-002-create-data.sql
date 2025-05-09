drop table if exists web_log;

create table web_log (
    id           uuid primary key default generate_ulid(),
    user_ip      inet,
    user_agent   text,
    path         text,
    http_method  text,
    status_code  int,
    response_ms  int,
    created_at   timestamptz default now()
);

-- generates 100,000,000 rows
insert into web_log (user_ip, user_agent, path, http_method, status_code, response_ms, created_at)
select
    ('192.168.' || (random()*255)::int || '.' || (random()*255)::int)::inet,
    ('Mozilla/5.0 ' || md5(random()::text)),
    '/page/' || (1 + floor(random() * 100))::int,
    (array['GET','POST','PUT','DELETE'])[floor(random()*4+1)],
    (array[200, 201, 204, 301, 302, 400, 401, 403, 404, 500])[floor(random()*10+1)],
    (random()*1000)::int,
    now() - (random() * interval '90 days')
from generate_series(1, 1000000000);

-- adding order by as per suggestion from external sources
create table web_log_brin
    as select * from web_log order by created_at;

create table web_log_btree
    as select * from web_log order by created_at;

create table web_log_noix
    as select * from web_log order by created_at;

create index brin_web_log_multi
    on web_log_brin using brin (id, status_code, created_at, http_method)
    with (pages_per_range = 8);

create index concurrently if not exists btree_web_log_multi
    on web_log_btree (created_at, status_code, http_method, id);

select brin_summarize_new_values('brin_web_log_multi');
vacuum full analyze web_log_brin;
vacuum full analyze web_log_btree;
vacuum full analyze web_log_noix;
