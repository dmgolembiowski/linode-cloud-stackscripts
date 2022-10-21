# linode/ark-one-click.sh by linode
# id: 401699
# description: Ark - Latest One-Click
# defined fields: name-rconpassword-label-rcon-password-name-sessionname-label-server-name-default-ark-server-name-motd-label-message-of-the-day-default-powered-by-linode-name-serverpassword-label-server-password-default-name-hardcore-label-hardcore-mode-enabled-oneof-truefalse-default-false-name-xpmultiplier-label-xp-multiplier-oneof-115251020-default-2-name-serverpve-label-server-pve-oneof-truefalse-default-false
# images: ['linode/debian11']
# stats: Used By: 16 + AllTime: 842
#!/bin/bash
#
#<UDF name="rconpassword" Label="RCON password" />
#<UDF name="sessionname" Label="Server Name" default="Ark Server" />
#<UDF name="motd" Label="Message of the Day" default="Powered by Linode!" />
#<UDF name="serverpassword" Label="Server Password" default="" />
#<UDF name="hardcore" Label="Hardcore Mode Enabled" oneOf="True,False" default="False" />
#<UDF name="xpmultiplier" Label="XP Multiplier" oneOf="1,1.5,2,5,10,20" default="2" />
#<UDF name="serverpve" Label="Server PvE" oneOf="True,False" default="False" />

source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=401711>

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

GAMESERVER="arkserver"

set_hostname
apt_setup_update


# ARK specific dependencies
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
dpkg --add-architecture i386
apt update
sudo apt -q -y install mailutils postfix \
curl wget file bzip2 gzip unzip bsdmainutils \
python util-linux ca-certificates binutils bc \
jq tmux lib32gcc-s1 libstdc++6 libstdc++6:i386  

# Install linuxGSM
linuxgsm_install

# Install ARK
game_install

# Setup crons and create systemd service file
service_config

#Game Config Options

sed -i s/XPMultiplier=.*/XPMultiplier="$XPMULTIPLIER"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/ServerPassword=.*/ServerPassword="$SERVERPASSWORD"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/ServerHardcore=.*/ServerHardcore="$SERVERPASSWORD"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/ServerPVE=.*/ServerPVE="$SERVERPVE"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/Message=.*/Message="$MOTD"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/SessionName=.*/SessionName="$SESSIONNAME"/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
sed -i s/ServerAdminPassword=.*/ServerAdminPassword="\"$RCONPASSWORD\""/ /home/arkserver/serverfiles/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini


# Start the service and setup firewall
ufw_install
ufw allow 27015/udp
ufw allow 7777:7778/udp
ufw allow 27020/tcp
ufw enable
fail2ban_install
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service
stackscript_cleanup