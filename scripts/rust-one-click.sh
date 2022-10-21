# linode/rust-one-click.sh by linode
# id: 401703
# description: Rust - Latest One-Click
# defined fields: name-rusthostname-label-server-hostname-default-linode-rust-server-name-description-label-server-description-default-powered-by-linode-name-rconpassword-label-rcon-password-name-maxplayers-label-maximum-players-oneof-10255075100-default-50-name-level-label-world-oneof-procedural-mapbarrenhapisislandsavasisland_koth-default-procedural-map-name-worldsize-label-world-size-oneof-100030006000-default-3000-name-seed-label-seed-default-50000-name-globalchat-label-global-chat-enabled-oneof-truefalse-default-true-name-pve-label-pve-enabled-oneof-truefalse-default-false
# images: ['linode/ubuntu20.04']
# stats: Used By: 21 + AllTime: 1922
#!/bin/bash
#
#<UDF name="rusthostname" label="Server Hostname" default="Linode Rust Server" />
#<UDF name="description" label="Server Description" default="Powered by Linode!" />
#<UDF name="rconpassword" Label="RCON Password" />
#<UDF name="maxplayers" label="Maximum Players" oneOf="10,25,50,75,100" default="50" />
#<UDF name="level" label="World" oneOf="Procedural Map,Barren,HapisIsland,SavasIsland_koth" default="Procedural Map" />
#<UDF name="worldsize" label="World Size" oneOf="1000,3000,6000" default="3000" />
#<UDF name="seed" label="Seed" default="50000" />
#<UDF name="globalchat" label="Global Chat Enabled" oneOf="true,false" default="true" />
#<UDF name="pve" label="PvE Enabled" oneOf="true,false" default="false" />


# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
source <ssinclude StackScriptID=401711>


exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

GAMESERVER="rustserver"

set_hostname
apt_setup_update


if [[ "$RUSTHOSTNAME" = "" ]]; then
  RUSTHOSTNAME="Linode Rust Server"
fi

if [[ "$LEVEL" = "Procedural Map" ]]; then
  LEVEL=""
fi

debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
dpkg --add-architecture i386
apt update
sudo apt -q -y install mailutils postfix curl \
wget file bzip2 gzip unzip bsdmainutils python \
util-linux ca-certificates binutils bc jq tmux \
lib32gcc1 libstdc++6 libstdc++6:i386 lib32z1

# Install linuxGSM
linuxgsm_install

# Install Rust
game_install

# Setup crons and create systemd service file
service_config

#Game Config Options

cp /home/rustserver/lgsm/config-lgsm/rustserver/_default.cfg /home/rustserver/lgsm/config-lgsm/rustserver/common.cfg
chown -R rustserver:rustserver /home/rustserver/

echo "server.globalchat $GLOBALCHAT/" > /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.pve $PVE" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.description \"$DESCRIPTION\"" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.maxplayers $MAXPLAYERS" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.seed \"$SEED\"" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.level $LEVEL" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.hostname \"$RUSTHOSTNAME\"" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
echo "server.ip $IP" >> /home/rustserver/serverfiles/server/rustserver/cfg/server.cfg
sed -i "s/rconpassword=\"CHANGE_ME\"/rconpassword=\"$RCONPASSWORD\"/"  /home/rustserver/lgsm/config-lgsm/rustserver/common.cfg
sed -i "s/worldsize=\"3000\"/worldsize=\"$WORLDSIZE\"/"  /home/rustserver/lgsm/config-lgsm/rustserver/common.cfg
sed -i "s/maxplayers=\"50\"/maxplayers=\"$MAXPLAYERS\"/" /home/rustserver/lgsm/config-lgsm/rustserver/common.cfg


# Start the service and setup firewall
ufw allow 28015
ufw allow 28016

systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service
stackscript_cleanup