# Завдання 4-6: Kafka consumer.
# Запуск із цієї директорії (homework/):  uv run python consumer.py
import json
import os

from confluent_kafka import Consumer
from icecream import ic

# Дано, не редагувати.
BOOTSTRAP_SERVERS = "localhost:9092"
TOPIC = "github-events"
OUTPUT_PATH = "data/output/stats.json"

GROUP_ID = "github-stats-consumer"
IDLE_LIMIT_SECONDS = 5.0  # зупинитись, коли топік мовчить стільки секунд


def update_counts(by_type: dict, by_repo: dict, event: dict) -> None:
    """Завдання 4 (15 балів).

    Додайте одну подію до бігучих агрегатів (мутуйте обидва словники на місці):
      by_type[event_type] += 1
      by_repo[repo_name]  += 1
    Ключі, яких ще немає, починаються з 0.
    """
    event_type = event.get("event_type")
    repo_name = event.get("repo_name")

    if event_type:
        by_type[event_type] = by_type.get(event_type, 0) + 1

    if repo_name:
        by_repo[repo_name] = by_repo.get(repo_name, 0) + 1


def top_repos(by_repo: dict, n: int = 5) -> list:
    """Завдання 5 (10 балів).

    Поверніть n найактивніших репозиторіїв як список пар [name, count],
    від найбільшого до найменшого. Однакові лічильники впорядкуйте за іменем
    репозиторію (щоб результат був детермінованим).
    """
    sorted_repos = sorted(by_repo.items(), key=lambda x: (-x[1], x[0]))
    return [[name, count] for name, count in sorted_repos[:n]]


def run_consumer() -> dict:
    """Завдання 6 (20 балів).

    1. Створіть Consumer (bootstrap.servers=BOOTSTRAP_SERVERS, group.id=GROUP_ID,
       auto.offset.reset="earliest") і підпишіться на TOPIC.
    2. У циклі poll(1.0): пропускайте None та msg.error(); інакше
       json.loads(msg.value()) і update_counts(...). Рахуйте total.
    3. Зупиніться, коли топік мовчить IDLE_LIMIT_SECONDS поспіль. consumer.close().
    4. Зберіть stats = {"total", "by_type", "top_repos": top_repos(by_repo, 5)}
       і запишіть його JSON у OUTPUT_PATH (створіть каталог через os.makedirs).
       Поверніть stats.
    """
    config = {
        "bootstrap.servers": BOOTSTRAP_SERVERS,
        "group.id": GROUP_ID,
        "auto.offset.reset": "earliest"
    }
    consumer = Consumer(config)
    consumer.subscribe([TOPIC])

    total = 0
    by_type = {}
    by_repo = {}

    last_msg_time = time.time()

    try:
        while True:
            msg = consumer.poll(1.0)

            if msg is None:
                if time.time() - last_msg_time >= IDLE_LIMIT_SECONDS:
                    break
                continue

            if msg.error():
                continue

            last_msg_time = time.time()
            total += 1

            event_data = json.loads(msg.value().decode("utf-8"))
            update_counts(event_data, by_type, by_repo)

    finally:
        consumer.close()

    stats = {
        "total": total,
        "by_type": by_type,
        "top_repos": top_repos(by_repo, 5)
    }

    output_dir = os.path.dirname(OUTPUT_PATH)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(stats, f, indent=4, ensure_ascii=False)

    return stats


if __name__ == "__main__":
    ic(run_consumer())
