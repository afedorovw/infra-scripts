#!/bin/bash

source .env

LATEST_VERSION=$(curl -s https://api.github.com/repos/prometheus-community/postgres_exporter/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://github.com/prometheus-community/postgres_exporter/releases/download/${LATEST_VERSION}/postgres_exporter-${LATEST_VERSION#v}.linux-amd64.tar.gz

tar xvf postgres_exporter-*.linux-amd64.tar.gz
sudo mv postgres_exporter-*.linux-amd64/postgres_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/postgres_exporter
rm -rf postgres_exporter-*

useradd --no-create-home --shell /bin/false postgre-exp
mkdir -p /etc/default/postgres_exporter

echo "DATA_SOURCE_NAME=\"postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_BASE?sslmode=disable\"" | sudo tee /etc/default/postgres_exporter/env
chown -R postgre-exp:postgre-exp /etc/default/postgres_exporter

cat <<EOF> /etc/systemd/system/postgres-exporter.service
[Unit]
Description=PostgreSQL Exporter
Wants=network-online.target
After=network-online.target postgresql.service

[Service]
User=postgre-exp
Group=postgre-exp
EnvironmentFile=/etc/default/postgres_exporter/env
ExecStart=/usr/local/bin/postgres_exporter \
  --web.listen-address=:9187 \
  --web.telemetry-path=/metrics \
  --log.level=info
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start postgres-exporter
systemctl enable postgres-exporter
systemctl status postgres-exporter
