# linode/easypanel-one-click.sh by linode
# id: 1008125
# description: Easypanel One-Click
# defined fields: 
# images: ['linode/ubuntu22.04']
# stats: Used By: 37 + AllTime: 392
#!/bin/bash

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# setup easypanel
docker run --rm \
    -v /etc/easypanel:/etc/easypanel \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    easypanel/easypanel setup