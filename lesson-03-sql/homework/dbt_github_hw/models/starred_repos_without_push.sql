-- =====================================================================
-- TASK 5 — starred_repos_without_push (12 балів). Специфікація: ../../MODELS.md → «starred_repos_without_push».
-- Репозиторії зі зіркою (WatchEvent), але без жодного PushEvent: anti-join (NOT EXISTS).
-- Контракт колонок нижче; заглушка повертає 0 рядків.
-- =====================================================================
SELECT
    DISTINCT se.repo_name::VARCHAR AS repo_name
  FROM {{ ref('stg_events') }} se
WHERE se.event_type = 'WatchEvent'
AND NOT EXISTS (
    SELECT 1 FROM {{ ref('stg_events') }} stg
    WHERE se.repo_name = stg.repo_name
      AND se.event_type = 'PushEvent'
)
ORDER BY se.repo_name
--WHERE false  -- TODO: репо з WatchEvent мінус репо, що мають PushEvent, у stg_events
