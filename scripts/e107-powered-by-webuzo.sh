# linode/e107-powered-by-webuzo.sh by webuzo
# id: 9018
# description: e107 is a content management system written in PHP and using the popular open source MySQL database system for content storage. It's completely free, totally customisable and in constant development.
			
Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc) or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.

You can get a Webuzo License here
http://www.webuzo.com/pricing

Path to Installation Logs : /root/webuzo-install.log

Instructions
On completion of the installation process, access http://your-ip:2004 to configure e107 and Softaculous Webuzo initially.

Contact : http://webuzo.com/contact
# defined fields: 
# images: ['linode/centos6.8', 'linode/ubuntu12.04lts', 'linode/ubuntu14.04lts', 'linode/centos5.6', 'linode/ubuntu10.04lts', 'linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 0
#!/bin/bash
# <udf name="webuzo_license_key" label="Premium Webuzo License Key" example="WEBUZO-XXXXX-XXXXX-XXXXX"/>

###########################################################################################################
# Install e107 and Softaculous Webuzo
# Description -
# About Webuzo :
#   Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc)
#   or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.
#
# About e107 :
#   e107 is a content management system written in PHP and using the popular open source MySQL database 
#   system for content storage. It's completely free, totally customisable and in constant development.
###########################################################################################################

# Install e107 Script using Webuzo
function install_webuzo_script(){
   
    # Install Webuzo
    install_webuzo
   
    wget http://files.webuzo.com/ip.php >> /root/webuzo-install.log 2>&1
    ip=$(cat ip.php)
   
    /usr/local/emps/bin/curl "http://$ip:2004/install.php?prepareinstall=145&license=$1"
   
}

# Install Webuzo Function
function install_webuzo(){
       
    # Fetch the Webuzo Installer
    wget -N http://files.webuzo.com/install.sh >> /root/webuzo-install.log 2>&1
   
    # Modify Permissions
    chmod 0755 install.sh >> /root/webuzo-install.log 2>&1
   
    # Execute
    ./install.sh >> /root/webuzo-install.log 2>&1
   
    # Clean Up
    rm -rf install.sh >> /root/webuzo-install.log 2>&1
   
}

#########################################################
#	Installing e107 and Softaculous Webuzo
#########################################################

install_webuzo_script $WEBUZO_LICENSE_KEY

# Check the return of the above command and display the result accordingly

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Congratulations, e107 has been successfully installed"
echo " "
echo "You can now configure e107 and Softaculous Webuzo at the following URL :"
echo "http://$ip:2004/"
echo " "
echo "Thank you for choosing Softaculous Webuzo !"
echo " "