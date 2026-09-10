-- Крок 8: gold.fact_commit. Специфікація: ../../SPEC.md → «Крок 8».
-- Джерело: {{ ref('commits') }}. Грануляція не змінюється (1 рядок = 1 commit_sha).
-- FK-колонки: repo_id = md5(repo_name), pusher_id = md5(pushed_by),
--             date_id = cast(date_format(pushed_at,'yyyyMMdd') as int) — той самий вираз, що й у вимірах.
-- Колонки: commit_sha, repo_id, pusher_id, date_id, branch, is_merge_commit, is_distinct, message_length.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
select
    cast(commit_sha as string) as commit_sha,
    cast(md5(repo_name) as string) as repo_id,
    cast(md5(pushed_by) as string) as pusher_id,
    cast(date_format(pushed_at, 'yyyyMMdd') as integer) as date_id,
    cast(branch as string) as branch,
    cast(is_merge_commit as boolean) as is_merge_commit,
    cast(is_distinct as boolean) as is_distinct,
    cast(message_length as integer) as message_length
from {{ ref('commits') }}
{% if is_incremental() %}
where pushed_at > (select max(to_timestamp(cast(date_id as string), 'yyyyMMdd')) from {{ this }})
{% endif %}
