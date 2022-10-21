# linode/prometheus-grafana-one-click.sh by linode
# id: 985364
# description: Prometheus and Grafana
# defined fields: name-soa_email_address-label-this-email-is-for-the-letsencrypt-ssl-certificate-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 25 + AllTime: 163
#!/usr/bin/env bash
## Updated: 06-07-2022
## Author: n0vabyte, Elvis Segura, esegura@linode.com

#<UDF name="soa_email_address" label="This email is for the LetsEncrypt SSL certificate" >
## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">

## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

creds="/root/credentials.txt"
prometheus_htpasswd_file="/etc/nginx/.prometheus_htpasswd"

function  add_firewalls {
        ufw allow http
        ufw allow https
}

function configure_nginx {
        apt-get install nginx apache2-utils -y
        cat << EOF > /etc/nginx/sites-available/$FQDN.conf
server {
    listen 80;
    server_name $FQDN;
    location / {
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   Host      \$http_host;
        proxy_pass http://localhost:3000;
    }
    location /prometheus/ {
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   Host      \$http_host;
        proxy_pass http://localhost:9090;
        auth_basic "Restricted Area";
        auth_basic_user_file $prometheus_htpasswd_file;
    }
# allow let's encrypt
   location ^~ /.well-known {
     allow all;
     auth_basic off;
     alias /var/www/html/.well-known;
   }
}
EOF

        ln -s /etc/nginx/sites-{available,enabled}/$FQDN.conf
        unlink /etc/nginx/sites-enabled/default
        systemctl reload nginx
        systemctl enable nginx
}

function install_node_exporter {
        groupadd --system prometheus
        useradd -s /sbin/nologin --system -g prometheus prometheus
        curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
        tar -xvf node_exporter*.tar.gz
        chmod +x node_exporter-*/node_exporter
        chown prometheus:prometheus node_exporter
        mv node_exporter-*/node_exporter /usr/local/bin
        rm -fr node_exporter-*
        cat <<EOF  > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
ExecStart=/usr/local/bin/node_exporter
[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload
    systemctl start node_exporter
    systemctl enable node_exporter
}

function configure_prometheus {
        latest_version=$(curl -s https://raw.githubusercontent.com/prometheus/prometheus/main/VERSION)
        prom_conf="/etc/prometheus/prometheus.yml"
        file_sd_targets="/etc/prometheus/file_sd_targets"
        prometheus_conf_dir="/etc/prometheus"
        prometheus_data_dir="/var/lib/prometheus"
        mkdir $prometheus_conf_dir $prometheus_conf_dir/file_sd_targets \
            $prometheus_conf_dir/rules $prometheus_data_dir

        wget https://github.com/prometheus/prometheus/releases/download/v$latest_version/prometheus-$latest_version.linux-amd64.tar.gz
        tar xvf prometheus-$latest_version.linux-amd64.tar.gz
        mv prometheus-$latest_version.linux-amd64/* $prometheus_conf_dir
        chown -R prometheus:prometheus $prometheus_conf_dir $prometheus_data_dir
        mv $prometheus_conf_dir/{prometheus,promtool} /usr/local/bin
        ## cleanup
        rm prometheus-$latest_version.linux-amd64.tar.gz
        rmdir prometheus-$latest_version.linux-amd64

        ## backup config before updating
        cp $prom_conf{,.bak}
        sed -i -e '/- job_name: "prometheus"/ s/^/#/' $prom_conf
        sed -i -e '/- targets:/ s/^/#/' $prom_conf
        sed -i -e '/static_configs/ s/^/#/g' $prom_conf
        ## add our config
        cat << EOF >> $prom_conf
#########################################
## Local Prometheus Instance - This Box #
#########################################
  - job_name: local_prometheus
    scrape_interval: 3s
    file_sd_configs:
    - files:
      - file_sd_targets/local_prometheus.yml
    honor_labels: true
    relabel_configs:
    - regex: (.*)
      replacement: \${1}:9100
      source_labels:
      - __address__
      target_label: __address__
    - regex: (.+)
      replacement: \${1}
      source_labels:
      - __instance
      target_label: instance
EOF
        ## add to file_sd_targets
        cat << EOF >> $file_sd_targets/local_prometheus.yml
- labels:
    __instance: prometheus
    cluster: local
  targets:
  - 127.0.0.1
EOF
        cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
--config.file /etc/prometheus/prometheus.yml \
--storage.tsdb.path $prometheus_data_dir/ \
--web.console.templates=$prometheus_conf_dir/consoles \
--web.console.libraries=$prometheus_conf_dir/console_libraries \
--web.listen-address=127.0.0.1:9090 \
--web.external-url=https://$FQDN/prometheus \
--storage.tsdb.retention=60d
Restart=always
ExecReload=/usr/bin/kill -HUP $MAINPID
TimeoutStopSec=20s
OOMScoreAdjust=-900
SendSIGKILL=no
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl start prometheus
        systemctl enable prometheus

        ## protect with htpasswd
        prometheus_htpasswd=$(openssl rand -base64 32)
        htpasswd -cb $prometheus_htpasswd_file prometheus $prometheus_htpasswd
        ## log credentials locally
        cat << EOF >> $creds
#################
#   Prometheus  #
#################
Location: https://$FQDN/prometheus
Username: prometheus
Password: $prometheus_htpasswd
EOF
        ## sanity check
        function fallback {
                echo "[FATAL] Creating custom configuration failed. Restoring old configuration"
                cp $prom_conf{.bak,}
                systemctl restart prometheus
                sleep 2
                systemctl is-active prometheus
                if [ $? -ne 0 ]; then
                        echo "[CRITICAL] Encoutered unexpected error while configuring Prometheus. Please reach out to Support."
                        exit 2
                fi
        }
        systemctl is-active prometheus
        if [ $? -ne 0 ]; then
                echo "[ERROR] Prometheus is not running. Falling back to default config.."
                fallback
        fi

}

function configure_grafana {
        apt-get install -y apt-transport-https \
            software-properties-common \
            wget \
            gnupg2

        wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
        echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
        apt-get -y update
        apt-get -y install grafana
        systemctl start grafana-server
        systemctl enable grafana-server

        ## reset Grafana admin password
        grafana_password=$(openssl rand -base64 32)
        grafana-cli --homepath "/usr/share/grafana" admin reset-admin-password $grafana_password
        sed -i -e 's/;http_addr =/http_addr = 127.0.0.1/g' /etc/grafana/grafana.ini
        systemctl restart grafana-server

        ## log credentials locally
        cat << EOF >> $creds
##############
#  Grafana   #
##############
Location: https://$FQDN/
Username: admin
Password: $grafana_password
EOF
}

function ssl_grafana {
        apt install -y certbot python3-certbot-nginx
        certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function main {
        add_firewalls
        configure_nginx
        install_node_exporter
        configure_prometheus
        configure_grafana
        ssl_grafana
}

## execute script
main
stackscript_cleanup