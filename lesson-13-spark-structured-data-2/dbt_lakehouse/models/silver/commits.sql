-- Крок 2: silver.commits. Специфікація: ../../SPEC.md → «Крок 2».
-- Джерело: {{ ref('events') }}, лише PushEvent.
-- from_json(payload, PUSH_SCHEMA) → explode масиву commits → commit grain. PUSH_SCHEMA = var('push_schema').
-- Дедуп: один рядок на commit_sha, найраніший pushed_at.
-- Колонки: commit_sha, repo_name, pushed_by, branch, author_name, author_email, message,
--          is_distinct, pushed_at, is_merge_commit, message_subject, message_length
-- Пастка: `distinct` — reserved word, у DDL-схемі та доступі до поля потрібні backticks.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with raw_pushes as (
    select
        event_id,
        repo_name,
        actor_login as pushed_by,
        created_at as pushed_at,
        payload
    from {{ ref('events') }}
    where event_type = 'PushEvent'

    {% if is_incremental() %}
    and created_at > (select max(pushed_at) from {{ this }})
    {% endif %}
),

parsed_pushes as (
    select
        event_id,
        repo_name,
        pushed_by,
        pushed_at,
        from_json(
            payload,
            'ref STRING, commits ARRAY<STRUCT<sha: STRING, author: STRUCT<name: STRING, email: STRING>, message: STRING, distinct: BOOLEAN>>'
        ) as parsed_payload
    from raw_pushes
),

exploded_commits as (
    select
        event_id,
        repo_name,
        pushed_by,
        pushed_at,
        regexp_replace(parsed_payload.ref, '^refs/heads/', '') as branch,
        explode(parsed_payload.commits) as commit_data
    from parsed_pushes
),

flattened_commits as (
    select
        commit_data.sha as commit_sha,
        repo_name,
        pushed_by,
        branch,
        commit_data.author.name as author_name,
        commit_data.author.email as author_email,
        commit_data.message as message,
        commit_data.distinct as is_distinct,
        pushed_at,
        event_id,
        case when commit_data.message like 'Merge %' then true else false end as is_merge_commit,
        split(commit_data.message, '\n')[0] as message_subject,
        length(commit_data.message) as message_length
    from exploded_commits
),

deduplicated_commits as (
    select
        *,
        row_number() over (
            partition by commit_sha
            order by pushed_at asc, event_id asc
        ) as rn
    from flattened_commits
)
select
    cast(commit_sha as string) as commit_sha,
    cast(repo_name as string) as repo_name,
    cast(pushed_by as string) as pushed_by,
    cast(branch as string) as branch,
    cast(author_name as string) as author_name,
    cast(author_email as string) as author_email,
    cast(message as string) as message,
    cast(is_distinct as boolean) as is_distinct,
    cast(pushed_at as timestamp) as pushed_at,
    cast(is_merge_commit as boolean) as is_merge_commit,
    cast(message_subject as string) as message_subject,
    cast(message_length as integer) as message_length
from deduplicated_commits
where rn = 1
