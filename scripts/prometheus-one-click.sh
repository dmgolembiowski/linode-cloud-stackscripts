# linode/prometheus-one-click.sh by linode
# id: 607034
# description: Prometheus One Click App
# defined fields: 
# images: ['linode/debian10']
# stats: Used By: 9 + AllTime: 290
#!/bin/bash

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install Prometheus
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do mkdir -p /etc/prometheus/${i}; done
apt-get -y install wget
mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -
tar xvf prometheus*.tar.gz
cd prometheus*/
mv prometheus promtool /usr/local/bin/
mv prometheus.yml  /etc/prometheus/prometheus.yml
mv consoles/ console_libraries/ /etc/prometheus/
cd ~/
rm -rf /tmp/prometheus

# Edit Prometheus config
sudo tee /etc/prometheus/prometheus.yml<<EOF
# my global config
  global:
    scrape_interval:     15s
    evaluation_interval: 15s
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label  to any timeseries scraped from this config.
  - job_name: 'prometheus'
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
EOF


cat <<END >/etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
END

for i in rules rules.d files_sd; do chown -R prometheus:prometheus /etc/prometheus/${i}; done
for i in rules rules.d files_sd; do chmod -R 775 /etc/prometheus/${i}; done
chown -R prometheus:prometheus /var/lib/prometheus/

# Add node_exporter & Enable services
curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest \
| grep browser_download_url \
| grep linux-amd64 \
| cut -d '"' -f 4 \
| wget -qi -

tar -xvf node_exporter*.tar.gz
cd  node_exporter*/
cp node_exporter /usr/local/bin
node_exporter --version

cat <<END >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
END

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
systemctl start node_exporter
systemctl enable node_exporter

# Cleanup
stackscript_cleanup