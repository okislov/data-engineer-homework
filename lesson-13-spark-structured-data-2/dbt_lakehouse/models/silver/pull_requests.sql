-- Крок 3: silver.pull_requests. Специфікація: ../../SPEC.md → «Крок 3».
-- Джерело: {{ ref('events') }}, лише PullRequestEvent. from_json(payload, PR_SCHEMA), PR_SCHEMA = var('pr_schema').
-- Грануляція: один рядок на (repo_name, pr_number) — стан з ОСТАННЬОЇ за часом події (row_number desc).
-- Колонки: repo_name, pr_number, title, author_login, state, is_merged, is_draft, opened_at,
--          closed_at, merged_at, additions, deletions, changed_files, commits_count, comments,
--          review_comments, author_association, label_names, last_action, last_event_at, churn, hours_open

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with raw_pr_events as (
    select
        event_id,
        repo_name,
        created_at as event_at,
        payload
    from {{ ref('events') }}
    where event_type = 'PullRequestEvent'
),

parsed_pr_events as (
    select
        event_id,
        repo_name,
        event_at,
        from_json(
            payload,
            'action STRING, number INT, pull_request STRUCT<title: STRING, user: STRUCT<login: STRING>, state: STRING, merged: BOOLEAN, draft: BOOLEAN, created_at: STRING, closed_at: STRING, merged_at: STRING, additions: INT, deletions: INT, changed_files: INT, commits: INT, comments: INT, review_comments: INT, author_association: STRING, labels: ARRAY<STRUCT<name: STRING>>>>'
        ) as parsed_payload
    from raw_pr_events
),

flattened_events as (
    select
        event_id,
        repo_name,
        event_at as last_event_at,
        parsed_payload.action as last_action,
        parsed_payload.number as pr_number,
        parsed_payload.pull_request.title as title,
        parsed_payload.pull_request.user.login as author_login,
        parsed_payload.pull_request.state as state,
        coalesce(parsed_payload.pull_request.merged, false) as is_merged,
        coalesce(parsed_payload.pull_request.draft, false) as is_draft,
        to_timestamp(parsed_payload.pull_request.created_at) as opened_at,
        to_timestamp(parsed_payload.pull_request.closed_at) as closed_at,
        to_timestamp(parsed_payload.pull_request.merged_at) as merged_at,
        parsed_payload.pull_request.additions as additions,
        parsed_payload.pull_request.deletions as deletions,
        parsed_payload.pull_request.changed_files as changed_files,
        parsed_payload.pull_request.commits as commits_count,
        parsed_payload.pull_request.comments as comments,
        parsed_payload.pull_request.review_comments as review_comments,
        parsed_payload.pull_request.author_association as author_association,
        transform(parsed_payload.pull_request.labels, x -> x.name) as label_names
    from parsed_pr_events
),

ranked_states as (
    select
        *,
        (additions + deletions) as churn,
       cast(
            unix_timestamp(coalesce(closed_at, last_event_at)) - unix_timestamp(opened_at) 
            as double
        ) / 3600.0 as hours_open,
        row_number() over (
            partition by repo_name, pr_number
            order by last_event_at desc, event_id desc
        ) as rn
    from flattened_events
)

select
    cast(repo_name as string) as repo_name,
    cast(pr_number as integer) as pr_number,
    cast(title as string) as title,
    cast(author_login as string) as author_login,
    cast(state as string) as state,
    cast(is_merged as boolean) as is_merged,
    cast(is_draft as boolean) as is_draft,
    cast(opened_at as timestamp) as opened_at,
    cast(closed_at as timestamp) as closed_at,
    cast(merged_at as timestamp) as merged_at,
    cast(additions as integer) as additions,
    cast(deletions as integer) as deletions,
    cast(changed_files as integer) as changed_files,
    cast(commits_count as integer) as commits_count,
    cast(comments as integer) as comments,
    cast(review_comments as integer) as review_comments,
    cast(author_association as string) as author_association,
    label_names,
    cast(last_action as string) as last_action,
    cast(last_event_at as timestamp) as last_event_at,
    cast(churn as integer) as churn,
    cast(hours_open as double) as hours_open
from ranked_states
where rn = 1
