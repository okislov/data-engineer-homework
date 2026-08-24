# Завдання 1 — Dockerfile для ingestor. Специфікація: SPEC.md → «Завдання 1».
#
# Один образ, одна стадія. Що має бути (деталі й бали — у SPEC.md):
#
#   * базовий образ python:3.12-slim з фіксованим тегом (не latest);
#   * PYTHONUNBUFFERED=1 — інакше логів завантаження не видно;
#   * non-root користувач (напр. appuser, uid 1000), USER — перед ENTRYPOINT;
#   * каталог /cache має належати цьому користувачу — туди монтується volume;
#   * залежності з app/requirements.txt ставляться ОКРЕМИМ шаром ПЕРЕД копіюванням
#     коду, з --no-cache-dir (правка коду не має перебудовувати pip install);
#   * ENTRYPOINT в exec-form запускає app/gh_ingest.py.
#
# Перевірте збірку:  docker build -t gh-ingest:latest .
# Скрипт app/gh_ingest.py — ДАНО, не редагуйте його.

# TODO: реалізуйте Dockerfile тут.

# Базовий образ із фіксованим тегом
FROM python:3.12-slim

# Вимкнення буферизації логів та створення .pyc файлів
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Створюємо non-root користувача
RUN useradd --create-home --uid 1000 appuser

# Точка монтування кешу під root і віддаємо права користувачу
RUN mkdir -p /cache && chown -R appuser:appuser /cache

WORKDIR /app

# Залежності окремим шаром
COPY app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо код
COPY app/gh_ingest.py ./

# HEALTHCHECK
# Якщо скрипт не піднімає HTTP-сервер, можна перевіряти наявність процесу:
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD pgrep -f gh_ingest.py || exit 1

# Перемикаємося на non-root користувача перед запуском
USER appuser

# 5. ENTRYPOINT в exec-form
ENTRYPOINT ["python", "gh_ingest.py"]
