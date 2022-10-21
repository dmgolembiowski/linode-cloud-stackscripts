# linode/ruby-on-rails-one-click.sh by linode
# id: 609048
# description: Ruby on Rails One-Click
# defined fields: name-railsapp-label-rails-application-name-example-railsapp
# images: ['linode/ubuntu20.04']
# stats: Used By: 17 + AllTime: 334
#!/bin/bash
#<UDF name="railsapp" Label="Rails Application name" example="railsapp"/>

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install Ruby on Rails
apt install -y ruby rails

# Configure rails Directory
mkdir /home/railsapp
cd /home/railsapp
rails new $RAILSAPP
cd $RAILSAPP
rails s -b 0.0.0.0 &

# Start rails app on reboot
crontab -l | { cat; echo "@reboot cd /home/railsapp/app1/ && rails s -b 0.0.0.0 &"; } | crontab -

# Cleanup
stackscript_cleanup