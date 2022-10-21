# linode/hashicorp-nomad-one-click.sh by linode
# id: 1037037
# description: HashiCorp Nomad One Click App
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian11', 'linode/ubuntu22.04']
# stats: Used By: 0 + AllTime: 18
#!/usr/bin/env bash

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

## set some variables
export NOMAD_DIR=/usr/bin
export NOMAD_PATH=${NOMAD_DIR}/nomad
export NOMAD_CONFIG_DIR=/etc/nomad.d
export NOMAD_DATA_DIR=/opt/nomad/data
export NOMAD_TLS_DIR=/opt/nomad/tls
export NOMAD_ENV_VARS=${NOMAD_CONFIG_DIR}/nomad.conf
export IP=$(hostname -I | awk '{print$1}')


## install gpg
apt-get install -y gpg

## Install Nomad
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y && sudo apt install -y nomad

#echo "Start Nomad in -server mode"
sudo tee ${NOMAD_ENV_VARS} > /dev/null <<ENVVARS
FLAGS=-bind 0.0.0.0 -server
ENVVARS

## Create systemd unit file
cat << EOF > ${NOMAD_ENV_VARS}
[Unit]
Description=Nomad Agent
Wants=network-online.target
After=network-online.target

[Service]
Restart=on-failure
EnvironmentFile=/etc/nomad.d/nomad.conf
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d $FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

## enable and start nomad
systemctl enable nomad
systemctl start nomad

## Install Docker
curl -fsSL get.docker.com | sudo sh

## Configure nginx container
cat << EOF > /root/nginx.conf
events {}

http {
  server {
    location / {
      proxy_pass http://nomad-ws;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

      # Nomad blocking queries will remain open for a default of 5 minutes.
      # Increase the proxy timeout to accommodate this timeout with an
      # additional grace period.
      proxy_read_timeout 310s;

      # Nomad log streaming uses streaming HTTP requests. In order to
      # synchronously stream logs from Nomad to NGINX to the browser
      # proxy buffering needs to be turned off.
      proxy_buffering off;

      # The Upgrade and Connection headers are used to establish
      # a WebSockets connection.
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";

      # The default Origin header will be the proxy address, which
      # will be rejected by Nomad. It must be rewritten to be the
      # host address instead.
      proxy_set_header Origin "\${scheme}://\${proxy_host}";
    }
  }

  # Since WebSockets are stateful connections but Nomad has multiple
  # server nodes, an upstream with ip_hash declared is required to ensure
  # that connections are always proxied to the same server node when possible.
  upstream nomad-ws {
    ip_hash;
    server host.docker.internal:4646;
  }
}
EOF

## start docker container
docker run -d --publish=8080:80 --add-host=host.docker.internal:host-gateway \
    --mount type=bind,source=$PWD/nginx.conf,target=/etc/nginx/nginx.conf \
    nginx:latest

## firewall
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 4646
ufw allow 8080

cat << EOF > /etc/motd
#################################
 The Nomad GUI is now available at HTTP://${IP}:8080

 This is a minimal installation with limited configurations.
 Please review configurations before using this application in production.

 Information on Nomad configurations at https://www.nomadproject.io/docs/configuration
#################################
EOF

stackscript_cleanup