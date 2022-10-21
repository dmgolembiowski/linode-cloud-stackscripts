# linode/mean-powered-by-webuzo.sh by webuzo
# id: 9352
# description: MEAN is an acronym for MongoDB, Express, AngularJs and NodeJs. MEAN is an opinionated fullstack javascript framework - which simplifies and accelerates web application development.
			
Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc) or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.

Path to Installation Logs : /root/webuzo-install.log

Instructions
On completion of the installation process, access http://your-ip:2004 to configure Softaculous Webuzo initially.

Contact : http://webuzo.com/contact
# defined fields: 
# images: ['linode/centos6.8', 'linode/ubuntu12.04lts', 'linode/ubuntu14.04lts', 'linode/centos5.6', 'linode/ubuntu10.04lts', 'linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 73
#!/bin/bash

###########################################################################################################
# Install MEAN and Softaculous Webuzo
# Description -
# About Webuzo :
#   Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc)
#   or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.
#
# About MEAN :
#   MEAN is an acronym for MongoDB, Express, AngularJs and NodeJs. MEAN is an opinionated fullstack 
#   javascript framework - which simplifies and accelerates web application development.
###########################################################################################################

# Install MEAN application using Webuzo
function install_webuzo(){
       
    # Fetch the Webuzo Installer
    wget -N http://files.webuzo.com/install.sh >> /root/webuzo-install.log 2>&1
   
    # Modify Permissions
    chmod 0755 install.sh >> /root/webuzo-install.log 2>&1
   
    # Execute
    ./install.sh --install=mean >> /root/webuzo-install.log 2>&1
   
    # Clean Up
    rm -rf install.sh >> /root/webuzo-install.log 2>&1
   
}

#########################################################
#	Installing MEAN using Softaculous Webuzo
#########################################################

install_webuzo

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Congratulations, MEAN has been successfully installed"
echo " "
echo "You can now configure MEAN and Softaculous Webuzo at the following URL :"
echo "http://$ip:2004/"
echo " "
echo "Thank you for choosing Softaculous Webuzo !"
echo " "