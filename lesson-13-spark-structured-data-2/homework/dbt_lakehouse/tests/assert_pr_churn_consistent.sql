-- Тест: churn у fact_pull_request завжди = additions + deletions.
-- Специфікація: ../../SPEC.md → «Тести». Тест падає, якщо запит поверне рядки.
-- TODO: замініть заглушку (зараз тест проходить вхолосту).
select
    pr_id,
    churn,
    additions,
    deletions,
    (additions + deletions) as expected_churn
from {{ ref('fact_pull_request') }}
where churn != (additions + deletions)
   or churn is null
   or additions is null
   or deletions is null
