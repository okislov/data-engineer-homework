-- Тест: sum(fact_repo_activity_daily.commits) = count(*) з fact_commit.
-- Специфікація: ../../SPEC.md → «Тести». Тест падає, якщо запит поверне рядки.
-- TODO: замініть заглушку (зараз тест проходить вхолосту).
with rollup_commits as (
    select sum(commits) as total_rollup_commits
    from {{ ref('fact_repo_activity_daily') }} 
),

fact_commits_count as (
    select count(*) as total_fact_commits
    from {{ ref('fact_commit') }}
)
select 
    r.total_rollup_commits,
    f.total_fact_commits
from rollup_commits r
cross join fact_commits_count f
where r.total_rollup_commits != f.total_fact_commits
