# linode/rabbitmq-one-click.sh by linode
# id: 688890
# description: RabbitMQ One-Click
# defined fields: name-rabbitmquser-label-rabbitmq-user-name-rabbitmqpassword-label-rabbitmq-password-example-s3cure_p4ssw0rd
# images: ['linode/debian10']
# stats: Used By: 38 + AllTime: 220
#!/bin/bash
#<UDF name="rabbitmquser" Label="RabbitMQ User" />
#<UDF name="rabbitmqpassword" Label="RabbitMQ Password" example="s3cure_p4ssw0rd" />

# Logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Set hostname, configure apt and perform update/upgrade
apt_setup_update

## Install prerequisites
apt-get install curl gnupg -y

## Get RabbitMQ 
$ curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -
sudo apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA"
## Install apt HTTPS transport
apt-get install apt-transport-https

## Add Bintray repositories that provision latest RabbitMQ and Erlang 23.x releases
tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
## Installs the latest Erlang 23.x release
deb https://dl.bintray.com/rabbitmq-erlang/debian buster erlang
## Installs latest RabbitMQ release
deb https://dl.bintray.com/rabbitmq/debian buster main
EOF

apt-get update -y
apt-get install rabbitmq-server -y --fix-missing

service rabbitmq-server start
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management

# Add rabbitmq admin users
rabbitmqctl add_user $RABBITMQUSER $RABBITMQPASSWORD
rabbitmqctl set_user_tags $RABBITMQUSER administrator
rabbitmqctl set_permissions -p / $RABBITMQUSER ".*" ".*" ".*"

# UFW https://www.rabbitmq.com/networking.html#ports
for i in 4369 5672 25672 15672 61613 61614 1883 8883 15674 15675 15692 35672 35673 35674 35675 35676 35677 35678 35679 35680 35681 35682; do ufw allow $i ;done

# Cleanup 
stackscript_cleanup