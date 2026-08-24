-- =====================================================================
-- TASK 3 — daily_activity (12 балів). Специфікація: ../../MODELS.md → «daily_activity».
-- Кількість подій по днях + накопичувальний підсумок: SUM(...) OVER (ORDER BY ...).
-- Контракт колонок нижче; заглушка повертає 0 рядків.
-- =====================================================================
SELECT
    event_date::DATE                                       AS event_date,
    COUNT(event_type)::BIGINT                              AS events,
    SUM(COUNT(event_type)) OVER (
        ORDER BY event_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::BIGINT                                          AS running_events
 FROM {{ ref('stg_events') }}
GROUP BY event_date
