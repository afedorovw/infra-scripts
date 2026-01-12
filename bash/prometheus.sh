#!/bin/bash

source .env

PROMETHEUS_VERSION="3.8.1"
PROMETHEUS_FOLDER_CONFIG="/etc/prometheus"
PROMETHEUS_FOLDER_TSDATA="/etc/prometheus/data"

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar xvfz prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

mv prometheus /usr/bin/
rm -rf /tmp/prometheus*

mkdir -p $PROMETHEUS_FOLDER_CONFIG
mkdir -p $PROMETHEUS_FOLDER_TSDATA

cat <<EOF> ${PROMETHEUS_FOLDER_CONFIG}/prometheus.yml
global:
  scrape_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - $HOST_WSL:9093

rule_files:
  - rules.yml

scrape_configs:
  - job_name: 'wsl-host'
    static_configs:
      - targets: ['$HOST_WSL:9100','$HOST_WSL:9090']
        labels:
          group: 'server'
          location: 'vm-1'
      - targets: ['$HOST_WSL:9323']
        labels:
          app: 'docker'
          group: 'containers'
          location: 'vm-1'
      - targets: ['$HOST_WSL:9417']
        labels:
          app: 'docker_exporter'
          group: 'containers'
          location: 'vm-1'

  - job_name: 'app-host'
    static_configs:
      - targets: ['$HOST_APP:9100']
        labels:
          app: 'mikrok8s'
          group: 'kubernetes'
          location: 'vm-2'

  - job_name: 'postgre-host'
    static_configs:
      - targets: ['$HOST_DB:9100']
        labels:
          group: 'server'
          location: 'vm-3'
      - targets: ['$HOST_DB:9187']
        labels:
          app: 'postgre'
          group: 'database'
          location: 'vm-3'
EOF

useradd -rs /bin/false prometheus
chown prometheus:prometheus /usr/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG
chown prometheus:prometheus $PROMETHEUS_FOLDER_CONFIG/prometheus.yml
chown prometheus:prometheus $PROMETHEUS_FOLDER_TSDATA


cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/bin/prometheus \
  --config.file       ${PROMETHEUS_FOLDER_CONFIG}/prometheus.yml \
  --storage.tsdb.path ${PROMETHEUS_FOLDER_TSDATA}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl status prometheus --no-pager
prometheus --version
