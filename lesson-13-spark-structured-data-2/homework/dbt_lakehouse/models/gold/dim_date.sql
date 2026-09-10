-- Крок 7: gold.dim_date. Специфікація: ../../SPEC.md → «Крок 7».
-- Згенерований безперервний календар (БЕЗ seed): explode(sequence(min, max, interval 1 day)).
-- Межі min/max — підзапитом по фактичних датах з {{ ref('commits') }}, {{ ref('pull_requests') }},
-- {{ ref('issues') }} (pushed_at / opened_at / merged_at / closed_at). Не хардкодьте.
-- Колонки: date_id (int yyyyMMdd), date_day (date), day_of_week, is_weekend, iso_week, year.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with all_fact_dates as (
    select cast(pushed_at as date) as fact_date from {{ ref('commits') }}
    where pushed_at is not null
    union all
    select cast(opened_at as date) as fact_date from {{ ref('pr_latest_state') }}
    where opened_at is not null
    union all
    select cast(merged_at as date) as fact_date from {{ ref('pr_latest_state') }}
    where merged_at is not null
    union all
    select cast(opened_at as date) as fact_date from {{ ref('issues_latest_state') }}
    where opened_at is not null
    union all
    select cast(closed_at as date) as fact_date from {{ ref('issues_latest_state') }}
    where closed_at is not null
),
calendar_bounds as (
    select
        coalesce(min(fact_date), current_date()) as min_date,
        coalesce(max(fact_date), current_date()) as max_date
    from all_fact_dates
),
generated_dates as (
    select explode(sequence(min_date, max_date, interval 1 day)) as date_day
    from calendar_bounds
)
select
    cast(date_format(date_day, 'yyyyMMdd') as integer) as date_id,
    cast(date_day as date) as date_day,
    cast(date_format(date_day, 'u') as integer) as day_of_week,
    cast(
        case when date_format(date_day, 'u') in ('6', '7') then true else false end 
        as boolean
    ) as is_weekend,
    cast(date_format(date_day, 'v') as integer) as iso_week,
    cast(year(date_day) as integer) as year
from generated_dates
