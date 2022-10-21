# linode/servana-initscript.sh by skystackops
# id: 1206
# description: Automate your Linodes with Servana. Servana provides you with your very own operations hub in the cloud. A place to command and conquer. 
# defined fields: name-server_id-label-servana-server-id-name-metadata-label-meta-data-name-stack_id-label-servana-stack-id-name-alias-label-servana-account-alias-name-host-label-servana-hostname-name-api_user-label-servana-account-username-name-api_token-label-servana-api-token-name-api_pass-label-servana-api-password-name-base-label-servana-server-default-myservanaio-name-role-label-servana-server-role-name-environment-label-servana-server-environment-name-jurisdiction-label-servana-server-jurisdiction-name-cloud-label-cloud-provider-default-linode
# images: ['linode/centos7', 'linode/ubuntu14.04lts', 'linode/centos6.8', 'linode/ubuntu12.04lts', 'linode/ubuntu14.10']
# stats: Used By: 0 + AllTime: 102
#!/bin/bash
# Automate your Linodes with Servana. Servana provides you with your very own operations hub in the cloud. A place to command and conquer. 
# Copyright 2012, Goldspring Ventures, Ltd.
# http://Servana.io or email us on team [ at ] Servana.io
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# <UDF name="SERVER_ID" Label="SERVANA SERVER ID"/>
# <UDF name="METADATA" Label="META DATA"/>
# <UDF name="STACK_ID" Label="SERVANA STACK ID"/>
# <UDF name="ALIAS" Label="SERVANA ACCOUNT ALIAS"/>
# <UDF name="HOST" Label="SERVANA HOSTNAME"/>
# <UDF name="API_USER" Label="SERVANA ACCOUNT USERNAME"/>
# <UDF name="API_TOKEN" Label="SERVANA API TOKEN"/>
# <UDF name="API_PASS" Label="SERVANA API PASSWORD"/>
# <UDF name="BASE" Label="SERVANA SERVER" default="my.servana.io"/>
# <UDF name="ROLE" Label="SERVANA SERVER ROLE"/>
# <UDF name="ENVIRONMENT" Label="SERVANA SERVER ENVIRONMENT"/>
# <UDF name="JURISDICTION" Label="SERVANA SERVER JURISDICTION"/>
# <UDF name="CLOUD" Label="CLOUD PROVIDER" default="linode"/>

LOCAL_PATH=/opt/servana

mkdir -p "$LOCAL_PATH/downloads" "$LOCAL_PATH/src" "$LOCAL_PATH/init" "$LOCAL_PATH/etc" "$LOCAL_PATH/backups" "$LOCAL_PATH/bin" "$LOCAL_PATH/sbin" "$LOCAL_PATH/logs" "/opt/servana/local"

userdata=$LOCAL_PATH/etc/userdata.conf
cat > $userdata <<EOF
SERVER_ID=$SERVER_ID
METADATA=$METADATA
STACK_ID=$STACK_ID
ALIAS=$ALIAS
HOST=$HOST
API_USER=$API_USER
API_TOKEN=$API_TOKEN
API_PASS=$API_PASS
BASE=$BASE
ROLE=$ROLE
ENVIRONMENT=$ENVIRONMENT
JURISDICTION=$JURISDICTION
CLOUD=$SS_CLOUD
EOF

if [ ! -e "/opt/servana/firstboot" ]; then

apt-get install -y curl unzip

curl -s -L -o $LOCAL_PATH/bin/servana "https://my.servana.io/boot"
chmod +x $LOCAL_PATH/bin/servana

bash $LOCAL_PATH/bin/servana build-server >> /opt/servana/logs/install 2>&1

touch /opt/servana/firstboot

fi

exit 0