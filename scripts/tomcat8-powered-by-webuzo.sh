# linode/tomcat8-powered-by-webuzo.sh by webuzo
# id: 9335
# description: Apache Tomcat 8 is aligned with Java EE 7. In addition to supporting updated versions of the Java EE specifications, Tomcat 8 includes a number of improvements compared to Tomcat 7
			
Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc) or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.

Path to Installation Logs : /root/webuzo-install.log

Instructions
On completion of the installation process, access http://your-ip:2004 to configure Softaculous Webuzo initially.

Contact : http://webuzo.com/contact
# defined fields: 
# images: ['linode/centos6.8', 'linode/ubuntu12.04lts', 'linode/ubuntu14.04lts', 'linode/centos5.6', 'linode/ubuntu10.04lts', 'linode/ubuntu10.04lts32bit']
# stats: Used By: 1 + AllTime: 80
#!/bin/bash

###########################################################################################################
# Install Tomcat8 and Softaculous Webuzo
# Description -
# About Webuzo :
#   Webuzo is a Single User Control Panel which helps users deploy Web Apps (WordPress, Joomla, Drupal, etc)
#   or System Apps (Apache, NGINX, PHP, Java, MongoDB, etc) on their virtual machines or in the cloud.
#
# About Tomcat8 :
#   Apache Tomcat 8 is aligned with Java EE 7. In addition to supporting updated versions of the 
#   Java EE specifications, Tomcat 8 includes a number of improvements compared to Tomcat 7
###########################################################################################################

# Install Tomcat8 application using Webuzo
function install_webuzo(){
       
    # Fetch the Webuzo Installer
    wget -N http://files.webuzo.com/install.sh >> /root/webuzo-install.log 2>&1
   
    # Modify Permissions
    chmod 0755 install.sh >> /root/webuzo-install.log 2>&1
   
    # Execute
    ./install.sh --install=tomcat8 >> /root/webuzo-install.log 2>&1
   
    # Clean Up
    rm -rf install.sh >> /root/webuzo-install.log 2>&1
   
}

#########################################################
#	Installing Tomcat8 using Softaculous Webuzo
#########################################################

install_webuzo

echo " "
echo "-------------------------------------"
echo " Installation Completed "
echo "-------------------------------------"
echo "Congratulations, Tomcat8 has been successfully installed"
echo " "
echo "You can now configure Tomcat8 and Softaculous Webuzo at the following URL :"
echo "http://$ip:2004/"
echo " "
echo "Thank you for choosing Softaculous Webuzo !"
echo " "