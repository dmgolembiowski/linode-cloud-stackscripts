# linode/tf2-one-click.sh by linode
# id: 401704
# description: TF2 One-Click
# defined fields: name-motd-label-message-of-the-day-default-powered-by-linode-name-servername-label-server-name-default-linode-tf2-server-name-svpassword-label-server-password-default-name-gslt-label-game-server-login-token-example-steam-gameserver-token-needed-to-list-as-public-server-default-name-autoteambalance-label-team-balance-enabled-oneof-enableddisabled-default-enabled-name-maxrounds-label-maximum-rounds-oneof-135101520-default-5-name-timelimit-label-round-time-limit-oneof-1015354560-default-35-name-rconpassword-label-rcon-password
# images: ['linode/debian11']
# stats: Used By: 10 + AllTime: 262
#!/bin/bash
#
#<UDF name="motd" label="Message of the Day" default="Powered by Linode!" />
#<UDF name="servername" label="Server Name" default="Linode TF2 Server" />
#<UDF name="svpassword" Label="Server Password" default="" />
#<UDF name="gslt" label="Game Server Login Token" example="Steam gameserver token. Needed to list as public server" default="" />
#<UDF name="autoteambalance" label="Team Balance Enabled" oneOf="Enabled,Disabled" default="Enabled" />
#<UDF name="maxrounds" label="Maximum Rounds" oneOf="1,3,5,10,15,20" default="5" />
#<UDF name="timelimit" label="Round Time Limit" oneOf="10,15,35,45,60" default="35" />
#<UDF name="rconpassword" Label="RCON password" />

source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=401711>

GAMESERVER="tf2server"

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

### UDF to config

#Autoteambalance
if [[ "$AUTOTEAMBALANCE" = "Enabled" ]]; then
  AUTOTEAMBALANCE=1
elif [[ "$AUTOTEAMBALANCE" = "Disabled" ]]; then
  AUTOTEAMBALANCE=0
fi

if [[ "$SERVERNAME" = "" ]]; then
  SERVERNAME="Linode TF2 Server"
fi


# Server config
set_hostname
apt_setup_update


# Teamfortress2 specific dependencies
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
dpkg --add-architecture i386
apt update
apt -q -y install mailutils postfix curl wget file \
bzip2 gzip unzip bsdmainutils python util-linux \
ca-certificates binutils bc jq tmux lib32gcc-s1 libstdc++6 \
libstdc++6:i386 libcurl4-gnutls-dev:i386 libtcmalloc-minimal4:i386

# Install linuxGSM
linuxgsm_install

# Install Teamfortress2
game_install

# Setup crons and create systemd service file
service_config

cp /home/tf2server/lgsm/config-lgsm/tf2server/_default.cfg /home/tf2server/lgsm/config-lgsm/tf2server/common.cfg

# Custom game configs
> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
cat <<END >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
log on
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile
END

echo "hostname $SERVERNAME" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "mp_autoteambalance $AUTOTEAMBALANCE" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "mp_maxrounds $MAXROUNDS" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "mp_timelimit $TIMELIMIT" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "rcon_password \"$RCONPASSWORD\"" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "sv_password \"$SVPASSWORD\"" >> /home/tf2server/serverfiles/tf/cfg/tf2server.cfg
echo "\"$MOTD\"" > /home/tf2server/serverfiles/tf/cfg/motd_default.txt


# Start the service and setup firewall
ufw_install
ufw allow 27014:27050/tcp
ufw allow 3478:4380/udp
ufw allow 27000:27030/udp
ufw allow 26901
ufw enable
fail2ban_install
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service
stackscript_cleanup