#!/bin/bash

ALERT_VERSION="0.30.0"

cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERT_VERSION}/alertmanager-${ALERT_VERSION}.linux-amd64.tar.gz
tar xzf alertmanager-${ALERT_VERSION}.linux-amd64.tar.gz
cd "alertmanager-${ALERT_VERSION}.linux-amd64"

mkdir -p /etc/alertmanager /var/lib/prometheus/alertmanager
mv amtool alertmanager /usr/local/bin/
mv alertmanager.yml /etc/alertmanager
rm -rf /tmp/alertmanager*

id alertmanager &>/dev/null || useradd -r -s /sbin/nologin -M alertmanager
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/prometheus/alertmanager

cat <<EOF> /etc/systemd/system/alertmanager.service
[Unit]
Description=Alertmanager Service
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
         --config.file=/etc/alertmanager/alertmanager.yml \
         --storage.path=/var/lib/prometheus/alertmanager \
         --cluster.advertise-address=127.0.0.1:9093

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager
