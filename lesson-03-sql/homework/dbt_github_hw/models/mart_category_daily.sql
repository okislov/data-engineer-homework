-- =====================================================================
-- TASK 6 — mart_category_daily (20 балів). Специфікація: ../../MODELS.md → «mart_category_daily».
-- Широка вітрина: multi-join stg_events + event_categories + calendar, агрегація по (день × категорія).
-- Контракт колонок нижче; заглушка повертає 0 рядків.
-- =====================================================================
SELECT
    se.event_date::DATE    AS event_date,
    cl.is_weekend::BOOLEAN AS is_weekend,
    ev.category::VARCHAR AS category,
    COUNT(se.event_type)::BIGINT  AS events,
    COUNT(DISTINCT se.repo_name)::BIGINT  AS distinct_repos,
    COUNT(DISTINCT se.actor_login)::BIGINT  AS distinct_actors
FROM {{ ref('stg_events') }} AS se
LEFT JOIN {{ ref('event_categories') }} AS ev
    ON se.event_type = ev.category
LEFT JOIN {{ ref('calendar') }} AS cl
    ON se.event_date = cl.day
GROUP BY se.event_date, cl.is_weekend, ev.category
--WHERE false  -- TODO: 3-way join + GROUP BY (event_date, is_weekend, category)
