# linode/fzv2ray.sh by liuyumei
# id: 637498
# description: 
# defined fields: 
# images: ['linode/debian9']
# stats: Used By: 1 + AllTime: 74
#! /bin/bash

cat>/root/crontab.txt<<EOF
SHELL=/bin/bash
* 3 * * * /usr/local/bin/xray restart
EOF

sudo /usr/bin/crontab  /root/crontab.txt


