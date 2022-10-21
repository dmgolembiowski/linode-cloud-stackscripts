# linode/easyengine.sh by ikcam
# id: 117089
# description: Easy Engine
# defined fields: name-hostname-label-hostname-name-fqdn-label-fully-qualified-domain-name-name-timezone-label-timezone
# images: ['linode/ubuntu16.04lts', 'linode/ubuntu18.04']
# stats: Used By: 2 + AllTime: 27
#!/bin/bash
# Fast deploy EasyEngine NGINX + PHP + Redis
#
#
#<UDF name="hostname" label="Hostname">
# HOSTNAME=
#
#<UDF name="fqdn" label="Fully Qualified Domain Name">
# FQDN=
#
#<UDF name="timezone" label="Timezone">
# TIMEZONE=

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPV4=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
IPV6=$(ip -6 addr | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^::1 | grep -v ^fe80)

function set_hostname {
    echo "$1" > /etc/hostname
    hostname -F /etc/hostname
}

function set_hosts {
    echo $1 $4 $3 >> /etc/hosts
    echo $2 $4 $3 >> /etc/hosts
}

function set_timezone {
    timedatectl set-timezone $1
}

function easyengine_install {
    wget -qO ee rt.cx/ee4
    sudo bash ee
}

set_hostname "$HOSTNAME"
set_hosts "$IPV4" "$IPV6" "$HOSTNAME" "$FQDN"
set_timezone "$TIMEZONE"
easyengine_install