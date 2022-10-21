# linode/grafana-one-click.sh by linode
# id: 607256
# description: Grafana One Click App
# defined fields: name-grafanapassword-label-grafana-password-example-password-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian11']
# stats: Used By: 49 + AllTime: 548
#!/usr/bin/env bash

### Grafana OCA

## Grafana Settings
#<UDF name="grafanapassword" Label="Grafana Password" example="Password" />

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

### Logging and other debugging helpers

# Enable logging for the StackScript
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Source the Bash StackScript Library
source <ssinclude StackScriptID=1>

# Source and run the New Linode Setup script for SSH configuration
source <ssinclude StackScriptID=666912>

# Configure APT and update repos
system_install_package software-properties-common apt-transport-https gnupg2
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
system_update

# Install Grafana & enable it as a service 
system_install_package grafana
systemctl enable --now grafana-server
systemctl status grafana-server.service

# Set Grafana password
sleep 3
grafana-cli --homepath "/usr/share/grafana" admin reset-admin-password $GRAFANAPASSWORD

# Allow TCP port 3000 through UFW
ufw allow 3000/tcp

# Cleanup
stackscript_cleanup