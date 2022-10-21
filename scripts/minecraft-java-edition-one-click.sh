# linode/minecraft-java-edition-one-click.sh by linode
# id: 401709
# description: Minecraft OCA
# defined fields: name-levelname-label-world-name-default-world-name-motd-label-message-of-the-day-default-powered-by-linode-name-allowflight-label-flight-enabled-oneof-truefalse-default-false-name-allownether-label-nether-world-enabled-oneof-truefalse-default-true-name-announceplayerachievements-label-player-achievements-enabled-oneof-truefalse-default-true-name-maxplayers-label-maximum-players-default-25-name-playeridletimeout-label-player-idle-timeout-limit-oneof-disabled15304560-default-disabled-name-difficulty-label-difficulty-level-oneof-peacefuleasynormalhard-default-easy-name-hardcore-label-hardcore-mode-enabled-oneof-truefalse-default-false-name-pvp-label-pvp-enabled-oneof-truefalse-default-true-name-forcegamemode-label-force-game-mode-enabled-oneof-truefalse-default-false-name-leveltype-label-world-type-oneof-defaultamplifiedflatlegacy-default-default-name-levelseed-label-world-seed-default-name-spawnanimals-label-spawn-animals-enabled-oneof-truefalse-default-true-name-spawnmonsters-label-spawn-monsters-enabled-oneof-truefalse-default-true-name-spawnnpcs-label-spawn-npcs-enabled-oneof-truefalse-default-true-name-gamemode-label-game-mode-oneof-survivalcreativeadventurespectator-default-survival-name-generatestructures-label-structure-generation-enabled-oneof-truefalse-default-true-name-maxbuildheight-label-maximum-build-height-oneof-50100200256-default-256-name-maxworldsize-label-maximum-world-size-oneof-10010001000010000010000001000000029999984-default-29999984-name-viewdistance-label-view-distance-oneof-2510152532-default-10-name-enablecommandblock-label-command-block-enabled-oneof-truefalse-default-false-name-enablequery-label-querying-enabled-oneof-truefalse-default-true-name-enablercon-label-enable-rcon-oneof-truefalse-default-false-name-rconpassword-label-rcon-password-default-name-rconport-label-rcon-port-default-25575-name-maxticktime-label-maximum-tick-time-default-60000-name-networkcompressionthreshold-label-network-compression-threshold-default-256-name-oppermissionlevel-label-op-permission-level-oneof-1234-default-4-name-port-label-port-number-default-25565-name-snooperenabled-label-snooper-enabled-oneof-truefalse-default-true-name-usenativetransport-label-use-native-transport-enabled-oneof-truefalse-default-true-name-username-label-the-username-for-the-linodes-non-root-adminssh-usermust-be-lowercase-example-lgsmuser-name-password-label-the-password-for-the-linodes-non-root-adminssh-user-example-s3curepsw0rd-name-pubkey-label-the-ssh-public-key-used-to-securely-access-the-linode-via-ssh-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/ubuntu20.04']
# stats: Used By: 484 + AllTime: 14105
#!/usr/bin/env bash
# Game config options:
# https://minecraft.gamepedia.com/Server.properties
#<UDF name="levelname" label="World Name" default="world" />
#<UDF name="motd" label="Message of the Day" default="Powered by Linode!" />
#<UDF name="allowflight" label="Flight Enabled" oneOf="true,false" default="false" />
#<UDF name="allownether" label="Nether World Enabled" oneOf="true,false" default="true" />
#<UDF name="announceplayerachievements" label="Player Achievements Enabled" oneOf="true,false" default="true" />
#<UDF name="maxplayers" label="Maximum Players" default="25" />
#<UDF name="playeridletimeout" label="Player Idle Timeout Limit" oneOf="Disabled,15,30,45,60" default="Disabled" />
#<UDF name="difficulty" label="Difficulty Level" oneOF="Peaceful,Easy,Normal,Hard" default="Easy" />
#<UDF name="hardcore" label="Hardcore Mode Enabled" oneOf="true,false" default="false" />
#<UDF name="pvp" label="PvP Enabled" oneOf="true,false" default="true" />
#<UDF name="forcegamemode" label="Force Game Mode Enabled" oneOf="true,false" default="false" />
#<UDF name="leveltype" label="World Type" oneOf="DEFAULT,AMPLIFIED,FLAT,LEGACY"default="DEFAULT" />
#<UDF name="levelseed" label="World Seed" default="" />
#<UDF name="spawnanimals" label="Spawn Animals Enabled" oneOf="true,false" default="true" />
#<UDF name="spawnmonsters" label="Spawn Monsters Enabled" oneOf="true,false" default="true" />
#<UDF name="spawnnpcs" label="Spawn NPCs Enabled" oneOf="true,false" default="true" />
#<UDF name="gamemode" label="Game Mode" oneOf="Survival,Creative,Adventure,Spectator" default="Survival" />
#<UDF name="generatestructures" label="Structure Generation Enabled" oneOf="true,false" default="true" />
#<UDF name="maxbuildheight" label="Maximum Build Height" oneOf="50,100,200,256" default="256" />
#<UDF name="maxworldsize" label="Maximum World Size" oneOf="100,1000,10000,100000,1000000,10000000,29999984" default="29999984" />
#<UDF name="viewdistance" label="View Distance" oneOf="2,5,10,15,25,32" default="10" />
#<UDF name="enablecommandblock" label="Command Block Enabled" oneOf="true,false" default="false" />
#<UDF name="enablequery" label="Querying Enabled" oneOf="true,false" default="true" />
#<UDF name="enablercon" label="Enable RCON" oneOf="true,false" default="false" />
#<UDF name="rconpassword" label="RCON Password" default="" />
#<UDF name="rconport" label="RCON Port" default="25575" />
#<UDF name="maxticktime" label="Maximum Tick Time" default="60000" />
#<UDF name="networkcompressionthreshold" label="Network Compression Threshold" default="256" />
#<UDF name="oppermissionlevel" label="Op-permission Level" oneOf="1,2,3,4" default="4" />
#<UDF name="port" label="Port Number" default="25565" />
#<UDF name="snooperenabled" label="Snooper Enabled" oneOf="true,false" default="true" />
#<UDF name="usenativetransport" label="Use Native Transport Enabled" oneOf="true,false" default="true" />
## Linode/SSH Security Settings - Required
#<UDF name="username" label="The username for the Linode's non-root admin/SSH user(must be lowercase)" example="lgsmuser">
#<UDF name="password" label="The password for the Linode's non-root admin/SSH user" example="S3cuReP@s$w0rd">
## Linode/SSH Settings - Optional
#<UDF name="pubkey" label="The SSH Public Key used to securely access the Linode via SSH" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

# Enable logging for the StackScript
set -xo pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and LinuxGSM Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401711>

# Source and run the New Linode Setup script for DNS/SSH configuration
[ ! $USERNAME ] && USERNAME='lgsmuser'
source <ssinclude StackScriptID=666912>

# Difficulty
[[ "$DIFFICULTY" = "Peaceful" ]] && DIFFICULTY=0
[[ "$DIFFICULTY" = "Easy" ]] && DIFFICULTY=1
[[ "$DIFFICULTY" = "Normal" ]] && DIFFICULTY=2
[[ "$DIFFICULTY" = "Hard" ]] && DIFFICULTY=3

# Gamemode
[[ "$GAMEMODE" = "Survival" ]] && GAMEMODE=0
[[ "$GAMEMODE" = "Creative" ]] && GAMEMODE=1
[[ "$GAMEMODE" = "Adventure" ]] && GAMEMODE=2
[[ "$GAMEMODE" = "Spectator" ]] && GAMEMODE=3

# Player Idle Timeout
[[ "$PLAYERIDLETIMEOUT" = "Disabled" ]] && PLAYERIDLETIMEOUT=0

# Minecraft-specific dependencies
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
debconf-set-selections <<< "postfix postfix/mailname string `hostname`"
dpkg --add-architecture i386
system_install_package mailutils postfix curl netcat wget file bzip2 \
                       gzip unzip bsdmainutils python util-linux ca-certificates \
                       binutils bc jq tmux openjdk-17-jre dirmngr software-properties-common

# Install LinuxGSM and Minecraft and enable the 'mcserver' service
readonly GAMESERVER='mcserver'
v_linuxgsm_oneclick_install "$GAMESERVER" "$USERNAME"

# Minecraft configurations
sed -i s/server-ip=/server-ip="$IP"/ /home/"$USERNAME"/serverfiles/server.properties

# Customer config
sed -i s/allow-flight=false/allow-flight="$ALLOWFLIGHT"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/allow-nether=true/allow-nether="$ALLOWNETHER"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/announce-player-achievements=true/announce-player-achievements="$ANNOUNCEPLAYERACHIEVEMENTS"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/difficulty=1/difficulty="$DIFFICULTY"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/enable-command-block=false/enable-command-block="$ENABLECOMMANDBLOCK"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/enable-query=true/enable-query="$ENABLEQUERY"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/force-gamemode=false/force-gamemode="$FORCEGAMEMODE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/gamemode=0/gamemode="$GAMEMODE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/generate-structures=true/generate-structures="$GENERATESTRUCTURES"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/hardcore=false/hardcore="$HARDCORE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/level-name=world/level-name="$LEVELNAME"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/level-seed=/level-seed="$LEVELSEED"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/level-type=DEFAULT/level-type="$LEVELTYPE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/max-build-height=256/max-build-height="$MAXBUILDHEIGHT"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/max-players=20/max-players="$MAXPLAYERS"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/max-tick-time=60000/max-tick-time="$MAXTICKTIME"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/max-world-size=29999984/max-world-size="$MAXWORLDSIZE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/motd=.*/motd="$MOTD"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/network-compression-threshold=256/network-compression-threshold="$NETWORKCOMPRESSIONTHRESHOLD"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/op-permission-level=4/op-permission-level="$OPPERMISSIONLEVEL"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/player-idle-timeout=0/player-idle-timeout="$PLAYERIDLETIMEOUT"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/pvp=true/pvp="$PVP"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/resource-pack-sha1=/resource-pack-sha1="$RESOURCEPACKSHA1"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/server-port=25565/server-port="$PORT"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/snooper-enabled=true/snooper-enabled="$SNOOPERENABLED"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/spawn-animals=true/spawn-animals="$SPAWNANIMALS"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/spawn-monsters=true/spawn-monsters="$SPAWNMONSTERS"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/spawn-npcs=true/spawn-npcs="$SPAWNNPCS"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/use-native-transport=true/use-native-transport="$USENATIVETRANSPORT"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/view-distance=10/view-distance="$VIEWDISTANCE"/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/rcon.password=*/rcon.password="\"$RCONPASSWORD\""/ /home/"$USERNAME"/serverfiles/server.properties
sed -i s/enable-rcon=false/enable-rcon=true/ /home/"$USERNAME"/serverfiles/server.properties

# Start the service and setup firewall
ufw allow "$PORT"
ufw allow "25575"

# Start and enable the Minecraft service
systemctl start "$GAMESERVER".service
systemctl enable "$GAMESERVER".service

# Cleanup
stackscript_cleanup