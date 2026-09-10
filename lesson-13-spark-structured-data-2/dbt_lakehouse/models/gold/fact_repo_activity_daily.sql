-- Крок 10: gold.fact_repo_activity_daily. Специфікація: ../../SPEC.md → «Крок 10».
-- Грануляція: (repo_id, date_id). Багатоджерельний rollup з {{ ref('commits') }},
-- {{ ref('pull_requests') }}, {{ ref('issues') }} та {{ ref('events') }} (WatchEvent/ForkEvent).
-- Патерн: денний агрегат на джерело (метрика + нулі для решти) → union all → group by.
-- Відсутні метрики → 0, не NULL. Порядок і типи колонок у всіх CTE мають збігатися.
-- Колонки: activity_id (md5(concat_ws('|', repo_id, date_id))), repo_id, date_id, commits,
--          distinct_committers, prs_opened, prs_merged, issues_opened, issues_closed, stars, forks.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with pre_aggregated_stages as (
    select
        md5(repo_name) as repo_id,
        cast(date_format(pushed_at, 'yyyyMMdd') as integer) as date_id,
        count(*) as commits,
        count(distinct author_email) as distinct_committers,
        0 as prs_opened,
        0 as prs_merged,
        0 as issues_opened,
        0 as issues_closed,
        0 as stars,
        0 as forks
    from {{ ref('commits') }}
    where pushed_at is not null
    group by 1, 2

    union all

    select
        md5(repo_name) as repo_id,
        cast(date_format(opened_at, 'yyyyMMdd') as integer) as date_id,
        0 as commits,
        0 as distinct_committers,
        count(*) as prs_opened,
        0 as prs_merged,
        0 as issues_opened,
        0 as issues_closed,
        0 as stars,
        0 as forks
    from {{ ref('pr_latest_state') }}
    where opened_at is not null
    group by 1, 2

    union all

    select
        md5(repo_name) as repo_id,
        cast(date_format(merged_at, 'yyyyMMdd') as integer) as date_id,
        0 as commits,
        0 as distinct_committers,
        0 as prs_opened,
        count(*) as prs_merged,
        0 as issues_opened,
        0 as issues_closed,
        0 as stars,
        0 as forks
    from {{ ref('pr_latest_state') }}
    where merged_at is not null
    group by 1, 2

    union all

    select
        md5(repo_name) as repo_id,
        cast(date_format(opened_at, 'yyyyMMdd') as integer) as date_id,
        0 as commits,
        0 as distinct_committers,
        0 as prs_opened,
        0 as prs_merged,
        count(*) as issues_opened,
        0 as issues_closed,
        0 as stars,
        0 as forks
    from {{ ref('issues_latest_state') }}
    where opened_at is not null
    group by 1, 2

    union all

    select
        md5(repo_name) as repo_id,
        cast(date_format(closed_at, 'yyyyMMdd') as integer) as date_id,
        0 as commits,
        0 as distinct_committers,
        0 as prs_opened,
        0 as prs_merged,
        0 as issues_opened,
        count(*) as issues_closed,
        0 as stars,
        0 as forks
    from {{ ref('issues_latest_state') }}
    where closed_at is not null
    group by 1, 2

    union all

    select
        md5(repo_name) as repo_id,
        cast(date_format(created_at, 'yyyyMMdd') as integer) as date_id,
        0 as commits,
        0 as distinct_committers,
        0 as prs_opened,
        0 as prs_merged,
        0 as issues_opened,
        0 as issues_closed,
        count(case when event_type = 'WatchEvent' then 1 end) as stars,
        count(case when event_type = 'ForkEvent' then 1 end) as forks
    from {{ ref('events') }}
    where event_type in ('WatchEvent', 'ForkEvent')
      and created_at is not null
    group by 1, 2
),

final_rollup as (
    select
        repo_id,
        date_id,
        sum(commits) as commits,
        sum(distinct_committers) as distinct_committers,
        sum(prs_opened) as prs_opened,
        sum(prs_merged) as prs_merged,
        sum(issues_opened) as issues_opened,
        sum(issues_closed) as issues_closed,
        sum(stars) as stars,
        sum(forks) as forks
    from pre_aggregated_stages
    group by 1, 2
)
select
    cast(md5(concat_ws('|', repo_id, cast(date_id as string))) as string) as activity_id,
    cast(repo_id as string) as repo_id,
    cast(date_id as integer) as date_id,
    cast(commits as integer) as commits,
    cast(distinct_committers as integer) as distinct_committers,
    cast(prs_opened as integer) as prs_opened,
    cast(prs_merged as integer) as prs_merged,
    cast(issues_opened as integer) as issues_opened,
    cast(issues_closed as integer) as issues_closed,
    cast(stars as integer) as stars,
    cast(forks as integer) as forks
from final_rollup
