# linode/webuzo-one-click.sh by linode
# id: 688902
# description: Webuzo One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04']
# stats: Used By: 20 + AllTime: 554
#!/usr/bin/env bash

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

# Source the Bash StackScript Library & Helpers
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=666912>

# Logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

# Set hostname, configure apt and perform update/upgrade
apt_setup_update

# Install Prereq's & Services
apt install -y wget
wget -N http://files.webuzo.com/install.sh
chmod +x install.sh
./install.sh
sleep 2
systemctl start webuzo.service

# firewall
ufw allow 25
ufw allow 53
ufw allow 587
ufw allow 2002
ufw allow 2003
ufw allow 2004
ufw allow 2005

# Cleanup 
stackscript_cleanup
reboot