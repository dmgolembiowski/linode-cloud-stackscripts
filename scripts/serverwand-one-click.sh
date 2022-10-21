# linode/serverwand-one-click.sh by linode
# id: 774829
# description: ServerWand One-Click
# defined fields: 
# images: ['linode/ubuntu20.04', 'linode/ubuntu22.04']
# stats: Used By: 8 + AllTime: 622
#!/bin/bash

# Logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# serverwand ssh key
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
curl https://serverwand.com/api/servers/connect > ~/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys