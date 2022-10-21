# linode/bitninja-one-click.sh by linode
# id: 923034
# description: BitNinja One-Click
# defined fields: name-license_key-label-license-key
# images: ['linode/centos7', 'linode/debian10', 'linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 16
#!bin/bash

# <UDF name="license_key" label="License Key" />

## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

wget -qO- https://get.bitninja.io/install.sh | /bin/bash -s - --license_key="$license_key" -y