# linode/azuracast-one-click.sh by linode
# id: 662118
# description: AzuraCast One-Click
# defined fields: 
# images: ['linode/debian10', 'linode/ubuntu20.04']
# stats: Used By: 185 + AllTime: 1831
#!/bin/bash

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, apt configuration and update/upgrade
set_hostname
apt_setup_update

# Install GIT
apt-get update && apt-get install -q -y git
# Cloning AzuraCast and install
mkdir -p /var/azuracast
cd /var/azuracast
curl -fsSL https://raw.githubusercontent.com/AzuraCast/AzuraCast/main/docker.sh > docker.sh
chmod a+x docker.sh
yes 'Y' | ./docker.sh setup-release
yes '' | ./docker.sh install

# Cleanup
stackscript_cleanup