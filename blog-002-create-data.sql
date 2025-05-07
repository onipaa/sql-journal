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
from generate_series(1, 100000000);

create table web_log_btree
    as select * from web_log;

create table web_log_noix
    as select * from web_log;

