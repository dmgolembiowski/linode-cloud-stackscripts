# linode/docker-base.sh by petehalverson
# id: 150512
# description: Docker host setup for Aspen Digital cloud
# defined fields: name-hostname-label-hostname-name-fqdn-label-domain-name-name-users_json_url-label-users-json-url-default-name-slack_webhook_url-label-slack-webhook-url-default
# images: ['linode/debian8', 'linode/debian9']
# stats: Used By: 7 + AllTime: 106
#! /bin/bash
#https://www.linode.com/stackscripts/view/142320
#docker-base by freelyformd
#
# Base server that sets a root SSH key and disables password auth. Used by me for Ansible-based deploys.
# <UDF name="HOSTNAME"          Label="Hostname" />
# <UDF name="FQDN"              Label="Domain Name">
# <UDF name="USERS_JSON_URL" Label="Users JSON URL" default="">
# <UDF name="SLACK_WEBHOOK_URL" Label="Slack Webhook URL" default="">

source <ssinclude StackScriptID="1">

IPADDR=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

# apt-get update -o Acquire::ForceIPv4=true
echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4
apt-get update && apt-get -y upgrade

# Install packages
apt-get install -q -y \
   acl \
   apt-transport-https \
   ca-certificates \
   curl \
   gnupg2 \
   htop \
   jq \
   software-properties-common \
   ufw

# Basic Stuff

ssh_disable_root

system_set_hostname "$HOSTNAME"

system_add_host_entry "$IPADDR" "$HOSTNAME"

system_add_host_entry "$IPADDR" "$FQDN"

service sshd restart

ln -sf /usr/share/zoneinfo/US/Mountain /etc/localtime


# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Add docker repository
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
  && apt-get update -q -y

# Install Docker
apt-get install docker-ce -q -y

# Configure Docker daemon
echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m"}}' | jq . > /etc/docker/daemon.json \
  && systemctl restart docker

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

##########################
# Setup project directory

mkdir -p /srv/www
chmod g+ws /srv/www
chown www-data:www-data /srv/www
setfacl -d -m u::rwx,g::rwx,o::rx /srv/www

#########################
# Additional users setup

# No password required for sudoers
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

function add_json_user {
  #
  # $1 - JSON DATA
  local JSON_DATA="$1"

  USERNAME=$(echo "$JSON_DATA" | jq --raw-output '.username')
  USERPUBKEY=$(echo "$JSON_DATA" | jq --raw-output '.pubkey')
  USERGROUPS=$(echo "$JSON_DATA" | jq --raw-output '.groups[]' | sed -e 'H;${x;s/\n/,/g;s/^,//;p;};d')

  if [ ! -n "$USERNAME" ] || [ ! -n "$USERPUBKEY" ] || [ ! -n "$USERGROUPS" ]; then
      echo "Missing username, pubkey or groups"
      return 1;
  fi

  adduser $USERNAME --disabled-password --gecos ""
  usermod -aG $USERGROUPS $USERNAME

  mkdir -p /home/$USERNAME/.ssh
  echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys
  echo -e "Host *\n  User git" > /home/$USERNAME/.ssh/config
  chown -R "$USERNAME":"$USERNAME" /home/$USERNAME/.ssh
  ln -s /srv/www /home/$USERNAME/www
  sed -i -e "s/^#alias ll='ls -l'/alias ll='ls -alh'/" /home/$USERNAME/.bashrc # enable ll list long alias <3
}

function add_json_users {
  #
  # $1 - JSON DATA
  local JSON_DATA="$1"
  USER_COUNT=$(echo "$JSON_DATA" | jq --raw-output '.users | length')
  for i in $(seq 0 $(($USER_COUNT - 1)) ); \
  do \
    add_json_user "$(echo "$JSON_DATA" | jq --raw-output .users[$i])"; \
  done
}

#####################
# Users JSON example :
#
# {
#     "users": [
#       {
#         "username" : "johndoe",
#         "pubkey": "ssh-rsa...",
#         "groups": ["sudo", "www-data"]
#       }
#     ]
# }

if [ "$USERS_JSON_URL" ]; then
  add_json_users "$(curl -fsSL $USERS_JSON_URL)"
fi

if [ "$SLACK_WEBHOOK_URL" ]; then
 curl -X POST -fsS --connect-timeout 15 --data-urlencode "payload={
    'text': '$HOSTNAME - Docker base online: ssh://$IPADDR',
 }" $SLACK_WEBHOOK_URL
fi

# Reboot is required to use ufw. https://www.digitalocean.com/community/questions/modprobe-error-could-not-insert-ip6_tables-unknown-symbol-in-module-or-unknown-param eter
###########################
# Configure and enable UFW
#
# ufw default deny incoming
# ufw default allow outgoing
# ufw allow ssh
# ufw enable