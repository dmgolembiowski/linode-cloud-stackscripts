# linode/openlitespeed-nodejs.sh by litespeed
# id: 458633
# description: A lightweight app which automatically installs OpenLiteSpeed and NodeJS.

The One-Click app automatically installs Linux, performance web server OpenLiteSpeed, Node.js, NPM and CertBot. OpenLiteSpeed features easy setup for SSL and RewriteRules. It's flexible enough to host multiple NodeJS apps, and supports many other apps including Django, Ruby, and CMSs like WordPress.

Whole process maybe take up to 10 minutes to finish. 
# defined fields: 
# images: ['linode/ubuntu18.04', 'linode/centos7', 'linode/centos8', 'linode/ubuntu20.04']
# stats: Used By: 7 + AllTime: 95
#!/bin/bash
### linode
### Install OpenLiteSpeed and NodeJS
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/nodejssetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )
### Reboot server
reboot