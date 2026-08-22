-- =====================================================================
-- TASK 2 — repo_top_events (12 балів). Специфікація: ../../MODELS.md → «repo_top_events».
-- TOP-5 репозиторіїв за кількістю подій у кожному event_type: ROW_NUMBER() + QUALIFY.
-- Контракт колонок нижче; заглушка повертає 0 рядків.
-- =====================================================================
SELECT
    NULL::VARCHAR AS event_type,
    NULL::VARCHAR AS repo_name,
    COUNT(*)::BIGINT AS event_count,
    ROW_NUMBER() OVER (PARTITION BY event_type ORDER BY COUNT(*) DESC, repo_name)::BIGINT AS type_rank
 FROM {{ ref('stg_events') }}
GROUP BY event_type, repo_name
QUALIFY type_rank <= 5
--WHERE false  -- TODO: агрегувати stg_events по (event_type, repo_name), ROW_NUMBER() OVER (...), QUALIFY type_rank <= 5