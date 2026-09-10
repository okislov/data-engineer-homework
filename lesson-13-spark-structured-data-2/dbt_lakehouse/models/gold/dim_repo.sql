-- Крок 5: gold.dim_repo. Специфікація: ../../SPEC.md → «Крок 5».
-- Джерело: {{ ref('events') }}. Грануляція: один рядок на репозиторій.
-- Колонки: repo_id (md5(repo_name)), repo_name, repo_owner, first_seen_at, last_seen_at,
--          event_count, is_forked (є хоч одна подія ForkEvent по цьому репо).

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with repo_metrics as (
    select
        repo_name,
        split(repo_name, '/')[0] as repo_owner,
        min(created_at) as first_seen_at,
        max(created_at) as last_seen_at,
        count(*) as event_count,
        max(case when event_type = 'ForkEvent' then true else false end) as is_forked
    from {{ ref('events') }}
    group by 1
)
select
    cast(md5(repo_name) as string) as repo_id,
    cast(repo_name as string) as repo_name,
    cast(repo_owner as string) as repo_owner,
    cast(first_seen_at as timestamp) as first_seen_at,
    cast(last_seen_at as timestamp) as last_seen_at,
    cast(event_count as integer) as event_count,
    cast(coalesce(is_forked, false) as boolean) as is_forked
from repo_metrics
