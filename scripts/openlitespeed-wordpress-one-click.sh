# linode/openlitespeed-wordpress-one-click.sh by linode
# id: 691622
# description: OpenLiteSpeed WordPress One-Click
# defined fields: 
# images: ['linode/centos7', 'linode/debian10', 'linode/ubuntu20.04']
# stats: Used By: 468 + AllTime: 5390
#!/bin/bash

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

### linode
### Install OpenLiteSpeed and WordPress
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/wpimgsetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )
### Clean up ls tmp folder
sudo rm -rf /tmp/lshttpd/*