"""github_archive_daily — ВАШ DAG. Специфікація: ../SPEC.md → «DAG».

Готові ETL-цеглинки вже є — імпортуйте і викликайте їх у задачах (не переписуйте):

    from include.gh_etl import download, validate, load_to_duckdb, summarize
    from gh_sensor import GHArchiveSensor   # ваш custom sensor із plugins/

Що треба зібрати (деталі й бали — у SPEC.md):
  * DAG `github_archive_daily`, розклад «щодня о 06:00 UTC», catchup=False;
  * усі задачі працюють із logical date {{ ds }}, а не datetime.now() — це дає
    ідемпотентність і коректний backfill;
  * граф:
        check_availability -> download_archive -> validate_file
            -> load_to_duckdb -> notify_completion
  * download_archive кладе шлях у XCom; validate_file і load_to_duckdb беруть його з XCom;
  * шляхи (дано):
        DB_PATH     = "/opt/airflow/data/github_analytics.duckdb"
        LANDING_DIR = "/opt/airflow/data/landing"

Перевірка: `airflow dags test github_archive_daily 2024-01-14` має пройти всі задачі;
наскрізно — `./verify.sh` із кореня homework/.
"""

from __future__ import annotations
from datetime import datetime

from plugins.gh_sensor import GHArchiveSensor
from include.gh_etl import download, validate, load_to_duckdb, summarize

from airflow.decorators import dag, task

DB_PATH = "/opt/airflow/data/github_analytics.duckdb"
LANDING_DIR = "/opt/airflow/data/landing"

@dag(
    dag_id="github_archive_daily",
    schedule="0 6 * * *",
    start_date=datetime(2024, 1, 14),
    catchup=False,
    max_active_runs=1,
    tags=["homework04", "taskflow"],
)
def github_archive_daily():
    # sensor
    check_availability = GHArchiveSensor(
        task_id="check_availability",
        hour="14",
        timeout=600,
        poke_interval=60,
        mode="reschedule"
    )

    @task
    def download_archive_task(ds=None):
        file_path = download(ds=ds, landing_dir=LANDING_DIR)
        return file_path

    @task
    def validate_file_task(file_path: str):
        validate(path=file_path)
        return file_path

    @task
    def load_to_duckdb_task(file_path: str, ds=None):
        rows_loaded = load_to_duckdb(path=file_path, ds=ds, db_path=DB_PATH)
        return rows_loaded

    @task
    def notify_completion_task(ds=None):
        summary_dict = summarize(ds=ds, db_path=DB_PATH)
        print(f"Per day: {summary_dict}")
        return summary_dict           # to XCom

    download_archive = download_archive_task()
    validate_file = validate_file_task(download_archive)
    loaded_to_duckdb = load_to_duckdb_task(file_path=validate_file)
    notify_completion = notify_completion_task()

    check_availability >> download_archive >> validate_file >> loaded_to_duckdb >> notify_completion

github_archive_daily()
