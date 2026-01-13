#### Каталог bash

Содержатся скрипты для разворачивания мониторинга:
- Node Exporter
- PostgreSQL Exporter
- Prometheus
- Alertmanager

Скрипт Prometheus содержит создание конфигурации с указанием хостов и использует файл `.env` для их перечисления.

Alrertmanager может быть также развернут в контейнере

```sh
podman run -d \
  --name alertmanager \
  -p 9093:9093 \
  -v /srv/alertmanager:/etc/alertmanager \
  prom/alertmanager:v0.28.1
```

Создание контейнера Grafana

```sh
podman volume create grafana-storage

podman run -d \
--name grafana \
-p 3000:3000 \
--network=host \
-v grafana-storage:/var/lib/grafana \
docker.io/grafana/grafana:12.3.0
```

---

### Каталог docker

Содержит docker-compose файлы для разворачивания сервисов Gitea и GitLab (+ runner)

Требуется указание переменных в файле `.env` 

Запуск

```
docker-compose -f name.yaml up -d 
```
