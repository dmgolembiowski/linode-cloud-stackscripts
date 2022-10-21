# linode/ant-media-server-enterprise-edition-one-click.sh by linode
# id: 985374
# description: Ant Media Enterprise Edition One-Click
# defined fields: 
# images: ['linode/ubuntu20.04']
# stats: Used By: 79 + AllTime: 495
#!/usr/bin/env bash

## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

ZIP_FILE="https://antmedia.io/linode/antmedia.zip"
INSTALL_SCRIPT="https://raw.githubusercontent.com/ant-media/Scripts/master/install_ant-media-server.sh"

wget -q --no-check-certificate $ZIP_FILE -O /tmp/antmedia.zip && wget -q --no-check-certificate $INSTALL_SCRIPT -P /tmp/

if [ $? == "0" ]; then
  bash /tmp/install_ant-media-server.sh -i /tmp/antmedia.zip
else
  logger "There is a problem in installing the ant media server. Please send the log of this console to contact@antmedia.io"
  exit 1
fi