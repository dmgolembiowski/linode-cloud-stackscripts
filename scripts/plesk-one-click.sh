# linode/plesk-one-click.sh by linode
# id: 593835
# description: Plesk is the leading secure WordPress and website management platform. This Stackscript installs the latest publicly available Plesk, activates a trial license, installs essential extensions, and sets up and configures the firewall. Please allow the script around 15 minutes to finish.
# defined fields: 
# images: ['linode/centos7', 'linode/ubuntu20.04']
# stats: Used By: 512 + AllTime: 7440
#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
## Enable logging
set -xo pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>
## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>
## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>
## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

function pleskautoinstall {
    echo "Downloading Plesk Auto-Installer"
    sh <(curl https://autoinstall.plesk.com/one-click-installer || wget -O - https://autoinstall.plesk.com/one-click-installer)
    echo "turning on http2"
    /usr/sbin/plesk bin http2_pref --enable
}

function firewall {
    echo "Setting Firewall to allow proper ports."
    if [ "${detected_distro[distro]}" = 'centos' ]; then  
    iptables -I INPUT -p tcp --dport 21 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 25 -j ACCEPT
    iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT -p tcp --dport 110 -j ACCEPT
    iptables -I INPUT -p tcp --dport 143 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    iptables -I INPUT -p tcp --dport 465 -j ACCEPT
    iptables -I INPUT -p tcp --dport 993 -j ACCEPT
    iptables -I INPUT -p tcp --dport 995 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8443 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8447 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8880 -j ACCEPT
    elif [ "${detected_distro[distro]}" = 'ubuntu' ]; then
    ufw allow 21
    ufw allow 22
    ufw allow 25
    ufw allow 80
    ufw allow 110
    ufw allow 143
    ufw allow 443
    ufw allow 465
    ufw allow 993
    ufw allow 995
    ufw allow 8443
    ufw allow 8447
    ufw allow 8880
else 
echo "Distro Not supported"
fi
}

function main {
    pleskautoinstall
    firewall
}

# Execute script
system_update
main
stackscript_cleanup