-- Крок 9: gold.fact_pull_request. Специфікація: ../../SPEC.md → «Крок 9».
-- Джерело: {{ ref('pull_requests') }}. Грануляція: PR.
-- pr_id = md5(concat_ws('|', repo_name, cast(pr_number as string)));
-- merged_date_id — NULL, якщо не змерджено; label_count через CASE (size(NULL) = -1).
-- Колонки: pr_id, repo_id, author_id, opened_date_id, merged_date_id, state, is_merged, is_draft,
--          additions, deletions, churn, changed_files, commits_count, comments, review_comments,
--          hours_open, label_count.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
select
    cast(md5(concat_ws('|', repo_name, pr_number)) as string) as pr_id,
    cast(md5(repo_name) as string) as repo_id,
    cast(md5(author_login) as string) as author_id,
    cast(date_format(opened_at, 'yyyyMMdd') as integer) as opened_date_id,
    cast(
        case when merged_at is not null then date_format(merged_at, 'yyyyMMdd') else null end 
        as integer
    ) as merged_date_id,
    cast(state as string) as state,
    cast(is_merged as boolean) as is_merged,
    cast(is_draft as boolean) as is_draft,
    cast(additions as integer) as additions,
    cast(deletions as integer) as deletions,
    cast(churn as integer) as churn,
    cast(changed_files as integer) as changed_files,
    cast(commits_count as integer) as commits_count,
    cast(comments as integer) as comments,
    cast(review_comments as integer) as review_comments,
    cast(hours_open as double) as hours_open,
    cast(size(label_names) as integer) as label_count
from {{ ref('pr_latest_state') }}
