# linode/csgo-one-click.sh by linode
# id: 401700
# description: CS:GO - Latest One-Click
# defined fields: name-gslt-label-game-server-login-token-example-steam-gameserver-token-needed-to-list-as-public-server-name-motd-label-message-of-the-day-default-powered-by-linode-name-servername-label-server-name-default-linode-csgo-server-name-rconpassword-label-rcon-password-name-svpassword-label-csgo-server-password-default-name-autoteambalance-label-team-balance-enabled-oneof-enableddisabled-default-enabled-name-roundtime-label-round-time-limit-oneof-510152060-default-5-name-maxrounds-label-maximum-rounds-oneof-15101520-default-10-name-buyanywhere-label-buy-anywhere-oneof-disabledenabledcounter-terrorists-only-terrorists-only-default-disabled-name-friendlyfire-label-friendly-fire-enabled-oneof-enableddisabled-default-disabled
# images: ['linode/debian11', 'linode/ubuntu22.04']
# stats: Used By: 19 + AllTime: 1723
#!/bin/bash
#

#<UDF name="gslt" label="Game Server Login Token" example="Steam gameserver token. Needed to list as public server." />
#<UDF name="motd" label="Message of the Day" default="Powered by Linode!" />
#<UDF name="servername" label="Server Name" default="Linode CS:GO Server" />
#<UDF name="rconpassword" Label="RCON password" />
#<UDF name="svpassword" Label="CSGO server password" default="" />
#<UDF name="autoteambalance" label="Team Balance Enabled" oneOf="Enabled,Disabled" default="Enabled" />
#<UDF name="roundtime" label="Round Time Limit" oneOf="5,10,15,20,60" default="5" />
#<UDF name="maxrounds" label="Maximum Rounds" oneOf="1,5,10,15,20"default="10" />
#<UDF name="buyanywhere" label="Buy Anywhere " oneOf="Disabled,Enabled,Counter-Terrorists Only, Terrorists Only" default="Disabled" />
#<UDF name="friendlyfire" label="Friendly Fire Enabled" oneOf="Enabled,Disabled" default="Disabled" />

source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=401711>

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

GAMESERVER="csgoserver"

### UDF to config

#Autoteambalance
if [[ "$AUTOTEAMBALANCE" = "Enabled" ]]; then
  AUTOTEAMBALANCE=1
elif [[ "$AUTOTEAMBALANCE" = "Disabled" ]]; then
  AUTOTEAMBALANCE=0
fi

#Buyanywhere
if [[ "$BUYANYWHERE" = "Enabled" ]]; then
  BUYANYWHERE=1
elif [[ "$BUYANYWHERE" = "Disabled" ]]; then
  BUYANYWHERE=0
elif [[ "$BUYANYWHERE" = "Terrorists Only" ]]; then
  BUYANYWHERE=2
elif [[ "$BUYANYWHERE" = "Counter-Terrorists Only" ]]; then
  BUYANYWHERE=3
fi

#friendlyfire

if [[ "$FRIENDLYFIRE" = "Enabled" ]]; then
  FRIENDLYFIRE=1
elif [[ "$FRIENDLYFIRE" = "Disabled" ]]; then
  FRIENDLYFIRE=0
fi

set_hostname
apt_setup_update


# CSGO specific dependencies
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
dpkg --add-architecture i386
apt update
sudo apt -q -y install mailutils postfix \
curl wget file bzip2 gzip unzip bsdmainutils \
python util-linux ca-certificates binutils bc \
jq tmux lib32gcc1 libstdc++6 libstdc++6:i386

# Install linuxGSM
linuxgsm_install

# Install CSGO
game_install

# Setup crons and create systemd service file
service_config

#Game Config Options

> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg

cat <<END >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
sv_contact ""
sv_lan 0
log on
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile 0
sv_hibernate_when_empty 1
sv_hibernate_ms 5
host_name_store 1
host_info_show 1
host_players_show 2
exec banned_user.cfg
exec banned_ip.cfg
writeid
writeip
END

echo "mp_autoteambalance $AUTOTEAMBALANCE" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
echo "hostname $SERVERNAME" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
echo "mp_roundtime $ROUNDTIME" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
echo "rcon_password \"$RCONPASSWORD\"" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
echo "sv_password \"$SVPASSWORD\"" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
sed -i s/mp_buy_anywhere.*/mp_buy_anywhere\ "$BUYANYWHERE"/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
sed -i s/mp_maxrounds.*/mp_maxrounds\ "$MAXROUNDS"/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
sed -i s/mp_friendlyfire.*/mp_friendlyfire\ "$FRIENDLYFIRE"/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
echo "$MOTD" > /home/csgoserver/serverfiles/csgo/motd.txt


if [[ "$FRIENDLYFIRE" = "1" ]]; then
sed -i s/ff_damage_reduction_bullets.*/ff_damage_reduction_bullets\ 0\.85/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
sed -i s/ff_damage_reduction_gernade.*/ff_damage_reduction_gernade\ 0\.33/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
sed -i s/ff_damage_reduction_gernade_self.*/ff_damage_reduction_gernade_self\ 0\.4/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
sed -i s/ff_damage_reduction_other.*/ff_damage_reduction_other\ 1/ /home/csgoserver/serverfiles/csgo/cfg/gamemode_casual.cfg
echo "sv_kick_ban_duration 0" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
echo "mp_disable_autokick 0" >> /home/csgoserver/serverfiles/csgo/cfg/csgoserver.cfg
fi

# Start the service and setup firewall
ufw_install
ufw allow 27015
ufw allow 27020/udp
ufw allow 27005/udp
ufw enable
fail2ban_install
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service
stackscript_cleanup