# linode/aapanel-one-click.sh by linode
# id: 869129
# description: aaPanel One-Click
# defined fields: 
# images: ['linode/centos7']
# stats: Used By: 236 + AllTime: 2392
#!/bin/bash

# Enable logging for the StackScript
set -xo pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Yum Update
yum update -y

# Install aapanel
yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && echo y|bash install.sh aapanel

# Log aaPanel login information
bt default > /root/.aapanel_info

# Stackscript Cleanup
rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"