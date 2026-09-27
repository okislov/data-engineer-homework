-- Крок 2: silver.commits. Специфікація: ../../SPEC.md → «Крок 2».
-- Джерело: {{ ref('events') }}, лише PushEvent.
-- from_json(payload, PUSH_SCHEMA) → explode масиву commits → commit grain. PUSH_SCHEMA = var('push_schema').
-- Дедуп: один рядок на commit_sha, найраніший pushed_at.
-- Колонки: commit_sha, repo_name, pushed_by, branch, author_name, author_email, message,
--          is_distinct, pushed_at, is_merge_commit, message_subject, message_length
-- Пастка: `distinct` — reserved word, у DDL-схемі та доступі до поля потрібні backticks.

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with source_events as (
    select * 
    from {{ ref('events') }}
    where event_type = 'PushEvent'
),

parsed_events as (
    select
        event_id,
        created_at as pushed_at,
        actor_login as pushed_by,
        repo_name,
        replace(ref, 'refs/heads/', '') as branch,
        from_json(payload, '{{ var("push_schema") }}') as parsed_payload
    from source_events
),

exploded_commits as (
    select
        e.pushed_at,
        e.pushed_by,
        e.repo_name,
        e.branch,
        e.event_id,
        c.sha as commit_sha,
        c.author.name as author_name,
        c.author.email as author_email,
        c.message as message,
        c.`distinct` as is_distinct,
        case 
            when c.message like 'Merge %' then true 
            else false 
        end as is_merge_commit,
        split_part(c.message, '\n', 1) as message_subject,
        length(c.message) as message_length
    from parsed_events e,
    explode(e.parsed_payload.commits) as c
),

deduplicated_commits as (
    select
        commit_sha,
        repo_name,
        pushed_by,
        branch,
        author_name,
        author_email,
        message,
        is_distinct,
        pushed_at,
        is_merge_commit,
        message_subject,
        message_length,
        row_number() over (
            partition by commit_sha 
            order by pushed_at asc, event_id asc
        ) as rn
    from exploded_commits
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
