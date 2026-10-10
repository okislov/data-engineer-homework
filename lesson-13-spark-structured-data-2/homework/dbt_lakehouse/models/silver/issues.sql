-- Крок 4: silver.issues. Специфікація: ../../SPEC.md → «Крок 4».
-- Джерело: {{ ref('events') }}, типи IssuesEvent ТА IssueCommentEvent (обидва несуть issue{}).
-- from_json(payload, ISSUE_SCHEMA), ISSUE_SCHEMA = var('issue_schema').
-- Грануляція: один рядок на (repo_name, issue_number) — стан з останньої за часом події.
-- Колонки: repo_name, issue_number, title, author_login, state, opened_at, closed_at,
--          comments, label_names, comment_events_seen, last_event_at, hours_to_close

-- TODO: замініть заглушку на запит згідно зі SPEC.md
with raw_issue_events as (
    select
        event_id,
        repo_name,
        event_type,
        created_at as event_at,
        payload
    from {{ ref('events') }}
    where event_type in ('IssuesEvent', 'IssueCommentEvent')
),

parsed_issue_events as (
    select
        event_id,
        repo_name,
        event_type,
        event_at,
        from_json(
            payload,
            'issue STRUCT<number: INT, title: STRING, user: STRUCT<login: STRING>, state: STRING, created_at: STRING, closed_at: STRING, comments: INT, labels: ARRAY<STRUCT<name: STRING>>>'
        ) as parsed_payload
    from raw_issue_events
),

flattened_events as (
    select
        event_id,
        repo_name,
        event_type,
        event_at,
        parsed_payload.issue.number as issue_number,
        parsed_payload.issue.title as title,
        parsed_payload.issue.user.login as author_login,
        parsed_payload.issue.state as state,
        to_timestamp(parsed_payload.issue.created_at) as opened_at,
        to_timestamp(parsed_payload.issue.closed_at) as closed_at,
        parsed_payload.issue.comments as comments,
        transform(parsed_payload.issue.labels, x -> x.name) as label_names
    from parsed_pr_events
),

aggregated_metrics as (
    select
        repo_name,
        issue_number,
        count(case when event_type = 'IssueCommentEvent' then 1 end) as comment_events_seen
    from flattened_events
    group by repo_name, issue_number
),

ranked_states as (
    select
        f.*,
        case 
            when f.closed_at is not null 
            then cast(unix_timestamp(f.closed_at) - unix_timestamp(f.opened_at) as double) / 3600.0
            else null 
        end as hours_to_close,
        row_number() over (
            partition by f.repo_name, f.issue_number
            order by f.event_at desc, f.event_id desc
        ) as rn
    from flattened_events f
)

select
    cast(r.repo_name as string) as repo_name,
    cast(r.issue_number as integer) as issue_number,
    cast(r.title as string) as title,
    cast(r.author_login as string) as author_login,
    cast(r.state as string) as state,
    cast(r.opened_at as timestamp) as opened_at,
    cast(r.closed_at as timestamp) as closed_at,
    cast(r.comments as integer) as comments,
    r.label_names,
    cast(coalesce(a.comment_events_seen, 0) as integer) as comment_events_seen,
    cast(r.event_at as timestamp) as last_event_at,
    cast(r.hours_to_close as double) as hours_to_close
from ranked_states AS r
left join aggregated_metrics AS a 
    on r.repo_name = a.repo_name 
    and r.issue_number = a.issue_number
where r.rn = 1
