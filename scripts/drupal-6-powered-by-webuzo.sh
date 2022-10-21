# linode/drupal-6-powered-by-webuzo.sh by webuzo
# id: 9022
# description: Drupal is an open-source platform and content management system for building dynamic web sites offering a broad range of features and services including user administration, publishing workflow, discussion capabilities, news aggregation, metadata functionalities using controlled vocabularies and XML publishing for content sharing purposes.
			
Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc) or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.

You can get a Webuzo License here
http://www.webuzo.com/pricing

Path to Installation Logs : /root/webuzo-install.log

Instructions
On completion of the installation process, access http://your-ip:2004 to configure Drupal 6 and Softaculous Webuzo initially.

Contact : http://webuzo.com/contact
# defined fields: 
# images: ['linode/centos6.8', 'linode/ubuntu12.04lts', 'linode/ubuntu14.04lts', 'linode/centos5.6', 'linode/ubuntu10.04lts', 'linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 0
#!/bin/bash
# <udf name="webuzo_license_key" label="Premium Webuzo License Key" example="WEBUZO-XXXXX-XXXXX-XXXXX"/>

###########################################################################################################
# Install Drupal 6 and Softaculous Webuzo
# Description -
# About Webuzo :
#   Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc)
#   or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.
#
# About Drupal 6 :
#   Drupal is an open-source platform and content management system for building dynamic web sites 
#   offering a broad range of features and services including user administration, publishing workflow,
#   discussion capabilities, news aggregation, metadata functionalities using controlled vocabularies 
#   and XML publishing for content sharing purposes.
###########################################################################################################

# Install Drupal 6 Script using Webuzo
function install_webuzo_script(){
   
    # Install Webuzo
    install_webuzo
   
    wget http://files.webuzo.com/ip.php >> /root/webuzo-install.log 2>&1
    ip=$(cat ip.php)
   
    /usr/local/emps/bin/curl "http://$ip:2004/install.php?prepareinstall=12&license=$1"
   
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
#	Installing Drupal 6 and Softaculous Webuzo
#########################################################

install_webuzo_script $WEBUZO_LICENSE_KEY

# Check the return of the above command and display the result accordingly

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Congratulations, Drupal 6 has been successfully installed"
echo " "
echo "You can now configure Drupal 6 and Softaculous Webuzo at the following URL :"
echo "http://$ip:2004/"
echo " "
echo "Thank you for choosing Softaculous Webuzo !"
echo " "