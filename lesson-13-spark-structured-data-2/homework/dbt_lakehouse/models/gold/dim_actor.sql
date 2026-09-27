-- Крок 6: gold.dim_actor. Специфікація: ../../SPEC.md → «Крок 6».
-- Джерело: {{ ref('events') }}, actor_login is not null. Грануляція: один рядок на актора.
-- Колонки: actor_id (md5(actor_login)), actor_login, is_bot (закінчується на [bot]),
--          first_seen_at, last_seen_at, event_count, distinct_repos.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with actor_metrics as (
    select
        actor_login,
        -- Агрегаційні метрики
        min(created_at) as first_seen_at,
        max(created_at) as last_seen_at,
        count(*) as event_count,
        count(distinct repo_name) as distinct_repos,
        max(case when actor_login like '%[bot]' then true else false end) as is_bot
    from {{ ref('events') }}
    where actor_login is not null
    group by 1
)
select
    cast(md5(actor_login) as string) as actor_id,
    cast(actor_login as string) as actor_login,
    cast(coalesce(is_bot, false) as boolean) as is_bot,
    cast(first_seen_at as timestamp) as first_seen_at,
    cast(last_seen_at as timestamp) as last_seen_at,
    cast(event_count as integer) as event_count,
    cast(distinct_repos as integer) as distinct_repos
from actor_metrics
