# linode/openlitespeed-nodejs-one-click.sh by linode
# id: 923031
# description: OpenLiteSpeed NodeJS One-Click
# defined fields: 
# images: ['linode/centos7', 'linode/ubuntu20.04']
# stats: Used By: 17 + AllTime: 244
#!/bin/bash
### linode
## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
### Install OpenLiteSpeed and NodeJS
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/nodejssetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )