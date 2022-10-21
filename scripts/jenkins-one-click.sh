# linode/jenkins-one-click.sh by linode
# id: 607401
# description: Jenkins One-Click App
# defined fields: 
# images: ['linode/debian10']
# stats: Used By: 133 + AllTime: 1083
#!/bin/bash

source <ssinclude StackScriptID="401712">
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install Prereq's & Jenkins
apt install -y default-jre wget gnupg2
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt_setup_update
apt install -y jenkins
systemctl enable --now jenkins

# Cleanup 
stackscript_cleanup