"""GHArchiveSensor — ВАШ custom sensor. Специфікація: ../../SPEC.md → «Sensor».

Сенсор чекає, поки годинний файл GitHub Archive за logical date стане доступним,
і лише тоді пропускає DAG далі.

Підказки:
  * успадкуйте `airflow.sensors.base.BaseSensorOperator`;
  * у __init__ прийміть параметр `hour` (година доби, яку перевіряємо);
  * реалізуйте `poke(self, context) -> bool`: візьміть дату з context["ds"],
    зберіть URL https://data.gharchive.org/<ds>-<hour>.json.gz і зробіть HTTP HEAD —
    поверніть True на 200, інакше False (або при винятку);
  * у DAG додайте сенсор першою задачею з timeout=600, poke_interval=60,
    mode="reschedule".
"""

from __future__ import annotations
from datetime import datetime, timedelta
import urllib.request
from airflow.models.dag import DAG
from airflow.sensors.base import BaseSensorOperator
from airflow.utils.context import Context
from airflow.decorators import task


class GHArchiveSensor(BaseSensorOperator):
    def __init__(self, hour: int = 14, **kwargs) -> None:
        super().__init__(**kwargs)
        self.hour = hour

    def poke(self, context) -> bool:
        ds = context["ds"]
        
        url = f"https://data.gharchive.org/{ds}-{self.hour}.json.gz"
        self.log.info(f"If GitHub Archive: {url}")

        try:
            # HEAD-request, check only status
            req = urllib.request.Request(url, method="HEAD")
            req.add_header("User-Agent", "airflow-sensor/1.0")
            with urllib.request.urlopen(req, timeout=160) as response:
                if response.status == 200:
                    response.read(1)
                    self.log.info(f"200")
                    return True
        except urllib.error.HTTPError as e:
            self.log.warning(f"Not ready: {e.code}")
        except Exception as e:
            self.log.error(f"Error: {e}")
            
        return False