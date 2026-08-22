-- =====================================================================
-- TASK 4 — daily_activity_change (12 балів). Специфікація: ../../MODELS.md → «daily_activity_change».
-- Зміна кількості подій день-до-дня: LAG(...) OVER (ORDER BY ...).
-- Контракт колонок нижче; заглушка повертає 0 рядків.
-- =====================================================================
SELECT
    NULL::DATE   AS event_date,
    COUNT(event_type)::BIGINT AS events,
    LAG(COUNT(event_type)) OVER (ORDER BY event_date)::BIGINT AS prev_day_events,
    COUNT(event_type) - LAG(COUNT(event_type)) OVER (ORDER BY event_date)::BIGINT AS delta_events
 --   ,COUNT(event_type) - COALESCE(LAG(COUNT(event_type)) OVER (ORDER BY event_date), 0) AS delta_events
FROM {{ ref('stg_events') }}
GROUP BY event_date
--ORDER BY event_date
--WHERE false  -- TODO: агрегувати stg_events по event_date, потім LAG для попереднього дня
