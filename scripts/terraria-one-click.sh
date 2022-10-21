# linode/terraria-one-click.sh by linode
# id: 401705
# description: Terraria One-Click
# defined fields: name-steamuser-label-steam-username-example-username-name-steampassword-label-steam-password-must-have-steam-guard-turned-off-for-deployment-example-yoursteampassword-name-worldname-label-world-name-default-world1-name-password-label-server-password-default-name-motd-label-message-of-the-day-default-powered-by-linode-name-difficulty-label-difficulty-level-oneof-normalexpert-default-normal-name-maxplayers-label-maximum-players-oneof-1102050100200255-default-20-name-port-label-port-default-7777-name-seed-label-seed-default-awesomeseed
# images: ['linode/ubuntu20.04']
# stats: Used By: 11 + AllTime: 543
#!/bin/bash
#
#<UDF name="steamuser" Label="Steam Username"  example="username" />
#<UDF name="steampassword" Label="Steam Password, must have Steam Guard turned off for deployment" example="YourSteamPassword" />

#Game config options

#<UDF name="worldname" label="World Name" default="world1"/>
#<UDF name="password" label="Server Password" default=""/>
#<UDF name="motd" label="Message of the Day" default="Powered by Linode!"/>
#<UDF name="difficulty" label="Difficulty Level" oneOf="Normal,Expert" default="Normal"/>
#<UDF name="maxplayers" label="Maximum Players" oneOf="1,10,20,50,100,200,255,"default="20"/>
#<UDF name="port" label="Port" default="7777"/>
#<UDF name="seed" label="Seed" default="AwesomeSeed"/>


#Non-MVP config options
#name="autocreate" label="autocreate" default="1"/>
#name="worldpath" label="worldpath" default="~/.local/share/Terraria/Worlds/"/>
#name="banlist" label="banlist" default="banlist.txt"/>
#name="priority" label="priority" default="1"/>
#name="upnp" label="upnp" default="1"/>
#name="npcstream" label="npcstream" default="60"/>
#name="secure" label="secure" default="1"/>
#name="language" label="language" default="en-US"/>


source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=401711>

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -xo pipefail

GAMESERVER="terrariaserver"

### UDF to config

if [[ "$DIFFICULTY" = "Normal" ]]; then
  DIFFICULTY="0"
elif [[ "$DIFFICULTY" = "Expert" ]]; then
  DIFFICULTY="1"
fi

set_hostname
apt_setup_update


# Terraria specific dependencies
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

echo Requires Steam username and password to install
su - $GAMESERVER -c "mkdir -p /home/$GAMESERVER/lgsm/config-lgsm/$GAMESERVER"
su - $GAMESERVER -c "touch /home/$GAMESERVER/lgsm/config-lgsm/$GAMESERVER/common.cfg"
su - $GAMESERVER -c "echo steamuser=\"$STEAMUSER\" >> /home/$GAMESERVER/lgsm/config-lgsm/$GAMESERVER/common.cfg"
su - $GAMESERVER -c "echo steampass=\''$STEAMPASSWORD'\' >> /home/$GAMESERVER/lgsm/config-lgsm/$GAMESERVER/common.cfg"

# Install Terraria
game_install

sed -i s/#seed=AwesomeSeed/seed="$SEED"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/worldname=world1/worldname="$WORLDNAME"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/difficulty=0/difficulty="$DIFFICULTY"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/maxplayers=20/maxplayers="$MAXPLAYERS"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/port=7777/port="$PORT"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/password=/password="$PASSWORD"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
sed -i s/motd=.*/motd="$MOTD"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt

#Non-MVP config options
# sed -i s/autocreate=1/autocreate="$AUTOCREATE"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/worldpath=\~\/\.local\/share\/Terraria\/Worlds\//worldpath="$WORLDPATH"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/banlist=banlist.txt/banlist="$BANLIST"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/\#priority=1/priority="$PRIORITY"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/#npcstream=60/npcstream="$NPCSTREAM"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/#upnp=1/upnp="$UPNP"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/secure=1/secure="$SECURE"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt
#sed -i s/language=en\-US/language="$LANGUAGE"/ home/"$GAMESERVER"/serverfiles/"$GAMESERVER".txt

# Setup crons and create systemd service file
service_config

# Start the service and setup firewall
ufw_install
ufw allow "$PORT"/tcp
ufw allow "$PORT"/udp
ufw enable
fail2ban_install
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service
stackscript_cleanup