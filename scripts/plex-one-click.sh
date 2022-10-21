# linode/plex-one-click.sh by linode
# id: 662119
# description: Plex One-Click
# defined fields: name-username-label-limited-user-name-not-root-name-password-label-limited-user-password-name-sshkey-label-limited-user-ssh-key-default-example-usually-found-in-sshid_rsapub
# images: ['linode/debian10']
# stats: Used By: 64 + AllTime: 2084
#!/bin/bash
# INPUT VARIABLES:
# <UDF name="USERNAME" Label="Limited User Name (not 'root')" />
# <UDF name="PASSWORD" Label="Limited User Password" />
# <UDF name="SSHKEY" Label="Limited User SSH Key" default="" example="Usually found in: ./ssh/id_rsa.pub"/>

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Limited user setup if username is not "root"
if [ "$USERNAME" != "root" ]; then
  
# ensure sudo is installed and configure secure user
  apt -y install sudo
  adduser -uid 1000 $USERNAME --disabled-password --gecos ""
  echo "$USERNAME:$PASSWORD" | chpasswd
  usermod -aG sudo $USERNAME
  
# Harden SSH Access
  sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  
# set home directory
  HOME=/home/$USERNAME
  
# configure ssh key for secure user if provided
  if [ "$SSHKEY" != "" ]; then
    SSHDIR=$HOME/.ssh
    mkdir $SSHDIR && echo "$SSHKEY" >> $SSHDIR/authorized_keys
    chmod -R 700 $SSHDIR && chmod 600 $SSHDIR/authorized_keys
    chown -R $USERNAME:$USERNAME $SSHDIR
  fi
  
# Enable SSH hardening
  systemctl restart sshd
  
# Create docker group, add limited user, and enable
  groupadd docker
  usermod -aG docker $USERNAME
fi

# Install and configure UFW for Plex
ufw_install
ufw allow 32400,3005,8324,32469/tcp
ufw allow 1900,32410,32412,32413,32414/udp

# Install the dependencies & add Docker to the APT repository
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update & install Docker-CE
apt_setup_update
apt install -y docker-ce

# Install plex as limited user
docker pull plexinc/pms-docker
docker run \
  -d \
  --name plex \
  --restart always \
  -p 32400:32400/tcp \
  -p 3005:3005/tcp \
  -p 8324:8324/tcp \
  -p 32469:32469/tcp \
  -p 1900:1900/udp \
  -p 32410:32410/udp \
  -p 32412:32412/udp \
  -p 32413:32413/udp \
  -p 32414:32414/udp \
  -e ADVERTISE_IP="http://$IP:32400/" \
  -h "Linode Plex Server" \
  -v $HOME/plex/config:/config \
  -v $HOME/plex/media:/media \
  -v $HOME/plex/transcode:/transcode \
  plexinc/pms-docker

# Recursively update ownership of Plex directories after delay
sleep 1
chown -R $USERNAME:$USERNAME $HOME/plex

# Cleanup
stackscript_cleanup