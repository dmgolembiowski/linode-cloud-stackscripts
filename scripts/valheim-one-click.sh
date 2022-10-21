# linode/valheim-one-click.sh by linode
# id: 781317
# description: Valheim One-Click
# defined fields: name-server_name-label-the-name-of-the-valheim-dedicated-server-name-server_password-label-the-password-for-the-valheim-dedicated-server-example-s3curepsw0rd-name-username-label-the-username-for-the-linodes-adminssh-user-please-ensure-that-the-username-entered-does-not-contain-any-uppercase-characters-example-lgsmuser-name-password-label-the-password-for-the-linodes-adminssh-user-example-s3curepsw0rd-name-pubkey-label-the-ssh-public-key-used-to-securely-access-the-linode-via-ssh-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 70 + AllTime: 1616
#!/usr/bin/env bash

### UDF Variables

## Valheim Server Settings - Required
#<UDF name="server_name" label="The name of the Valheim dedicated server">
#<UDF name="server_password" label="The password for the Valheim dedicated server" example="S3cuReP@s$w0rd">

## Linode/SSH Security Settings - Required
#<UDF name="username" label="The username for the Linode's admin/SSH user (Please ensure that the username entered does not contain any uppercase characters)" example="lgsmuser">
#<UDF name="password" label="The password for the Linode's admin/SSH user" example="S3cuReP@s$w0rd">

## Linode/SSH Settings - Optional
#<UDF name="pubkey" label="The SSH Public Key used to securely access the Linode via SSH" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

### Logging and other debugging helpers

# Enable logging for the StackScript
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and LinuxGSM Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401711>

# Source and run the New Linode Setup script for DNS/SSH configuration
[ ! $USERNAME ] && USERNAME='lgsmuser'
source <ssinclude StackScriptID=666912>


# Download and install dependencies
dpkg --add-architecture i386
system_update
system_install_package curl wget file tar expect bzip2 gzip unzip \
                       bsdmainutils python util-linux ca-certificates \
                       binutils bc jq tmux netcat lib32gcc1 lib32stdc++6 \
                       libc6-dev libsdl2-2.0-0:i386


# Open the needed firewall ports
ufw allow 2456:2458/udp
ufw allow 4380/udp
ufw allow 27000:27030/udp

# Install linuxGSM
GAMESERVER='vhserver'
v_linuxgsm_oneclick_install "$GAMESERVER" "$USERNAME"

# Set the Valheim dedicated server's name and password
cat /home/$USERNAME/lgsm/config-lgsm/vhserver/_default.cfg >> /home/$USERNAME/lgsm/config-lgsm/vhserver/vhserver.cfg
sed -i "s/servername=\"Valheim Server\"/servername=\"$SERVER_NAME\"/" /home/$USERNAME/lgsm/config-lgsm/vhserver/vhserver.cfg
sed -i "s/serverpassword=\"\"/serverpassword=\"$SERVER_PASSWORD\"/" /home/$USERNAME/lgsm/config-lgsm/vhserver/vhserver.cfg

# Start and enable the Valheim services
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service

# Clean up
stackscript_cleanup