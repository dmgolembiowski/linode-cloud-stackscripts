# linode/openlitespeed-django.sh by litespeed
# id: 458602
# description: A lightweight app which automatically installs OpenLiteSpeed and Django with virtualenv.

The One-Click app automatically installs Linux, performance web server OpenLiteSpeed, Python LSAPI and CertBot. OpenLiteSpeed features easy setup for SSL and RewriteRules. It's flexible enough to host multiple Django apps, and supports many other apps including NodeJS, Ruby, and CMSs like WordPress.

Whole process maybe take up to 10 minutes to finish. 
# defined fields: 
# images: ['linode/ubuntu18.04', 'linode/centos7', 'linode/centos8', 'linode/ubuntu20.04']
# stats: Used By: 2 + AllTime: 91
#!/bin/bash
### linode
### Install OpenLiteSpeed and Django
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/djangosetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )
### Reboot server
reboot