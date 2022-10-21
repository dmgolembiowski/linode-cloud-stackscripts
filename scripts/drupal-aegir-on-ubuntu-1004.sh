# linode/drupal-aegir-on-ubuntu-1004.sh by mclendening
# id: 1027
# description: Linode StackScript - Drupal Aegir version 04-alpha14 (HEAD)

*** It is very important that DNS is configured for the hostname before setup***

Adapted from StackScriptID=203
Added the option to set password for user aegir
Normalized for Ubuntu 10.04 LTS
Included the automate_install script from StackScriptID=203
Added fix for Drupal admin menu issue
Added command line safe characters ";" and ":"

Builds an Aegir install according to the instructions here: http://git.aegirproject.org/?p=provision.git;a=blob_plain;f=docs/INSTALL.txt;hb=provision-0.4-alpha14

Also used mig5's video as a reference here: http://www.mig5.net/content/video-installing-aegir-04-alpha5

# defined fields: name-aegir_hostname-label-enter-a-hostname-for-platform-server-example-ex-server01-name-aegir_domain-label-enter-domain-host-name-example-ex-server01examplecom-name-aegir_password-label-enter-password-for-platform-user-aegir-default-example-ex-password-for-the-user-myawes0passwrd-name-db_password-label-mysql-root-password-name-user_email-label-enter-your-email-to-recieve-a-1-time-login-link-to-aegir-example-ex-youexamplecom-name-aegir_shell-label-add-a-shell-for-the-aegir-user-oneof-yesno-default-no-name-setup_acl-label-setup-acl-for-aegir-directory-oneof-yesno-default-no
# images: ['linode/ubuntu10.04lts32bit', 'linode/ubuntu10.04lts']
# stats: Used By: 0 + AllTime: 248
#!/bin/bash
# <UDF name="aegir_hostname" label="Enter a hostname for platform server" example="Ex: server01" />
# <UDF name="aegir_domain" label="Enter domain host name" example="Ex: server01.example.com" />
# <UDF name="aegir_password" label="Enter password for platform user aegir" default="" example="Ex: Password for the user: myAwes0Passw@rd!" />
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="user_email" label="Enter your email to recieve a 1 time login link to Aegir" example="Ex: you@example.com" />
# <UDF name="aegir_shell" label="Add a shell for the aegir user" oneOf="Yes,No" default="No" />
# <UDF name="setup_acl" label="Setup ACL for Aegir directory" oneOf="Yes,No" default="No" />

source <ssinclude StackScriptID="1">

# Logs the entire Stackscript operation
exec &> /root/stackscript.log

function aegir_install {
	# install required packages
	apt-get -y install apache2 php5 php5-cli php5-mysql php5-gd mysql-server postfix sudo git-core unzip patch curl expect
	
	# Get IP
	ipAddress=$(ifconfig | grep -m 1 'inet addr:' | cut -d: -f2 | awk '{ print $1}');
	# Insert IP and hostname and domain into /etc/hosts file
	sed -i '
/127.0.0.1 localhost/ a\
'"$ipAddress"' '"$AEGIR_HOSTNAME"' '"$AEGIR_DOMAIN"'
' /etc/hosts


  # Unbind mysql to localhost
  sed -i '
/bind-address/ c\
#bind-address = 127.0.0.1
' /etc/mysql/my.cnf

  # Restart mysql to clear cache
  /etc/init.d/mysql restart


  # create aegir user
	if [ ! -n "AEGIR_PASSWORD" ]; then
	  AEGIR_PASSWORD=$(randomString 20)
	fi
        if [ "$AEGIR_SHELL" = "No" ]
	then 
	  adduser --system --group --home /var/aegir aegir
        else
          adduser --system --shell /bin/bash --group --home /var/aegir aegir
        fi

  # make aegir a user of group www-data
	adduser aegir www-data

  # Protect us from special characters when setting aegir user password
	aegir_password_safe=$(replace_special_shell_characters $AEGIR_PASSWORD)

  # Set aegir user password
	echo "aegir:$aegir_password_safe" | chpasswd

  # link aegir apache.conf into apache2/conf.d directory
	ln -s /var/aegir/config/apache.conf /etc/apache2/conf.d/aegir.conf

  # add aegir user to the sudoers file
	sed -i '$a\\naegir ALL=NOPASSWD: /usr/sbin/apache2ctl' /etc/sudoers

  # Get the aegir setup script and store it in /tmp
	cd /tmp
	curl -L -o 'install.sh.txt' 'http://git.aegirproject.org/?p=provision.git;a=blob_plain;f=install.sh.txt;hb=HEAD' 
  
  # Create the automate install script that calls the aegir script and store it in /tmp
	touch automate_install.expect
echo 'set timeout 20' >>  automate_install.expect
echo 'set script [lindex $argv 0]' >>  automate_install.expect
echo 'set aegir_hostname [lindex $argv 1]' >>  automate_install.expect
echo 'set email [lindex $argv 2]' >>  automate_install.expect
echo 'set password [lindex $argv 3]' >>  automate_install.expect
echo 'spawn sh $script $aegir_hostname --client_email=$email' >>  automate_install.expect
echo 'expect "Do you want to proceed with the install?"' >>  automate_install.expect
echo 'send "Y\n"' >>  automate_install.expect
echo 'expect "Enter password:"' >>  automate_install.expect
echo 'send "$password\n"' >>  automate_install.expect
echo 'interact' >>  automate_install.expect
echo ""


  # enable apache mode rewrite
	a2enmod rewrite
  # mark apache to restart
  	touch /tmp/restart-apache2

  # Protect us from special characters when setting db user password
  aegir_safedbpassword=$(replace_special_shell_characters $DB_PASSWORD)
   
  # Run aegir automate install script under user aegir credentials
	su -s /bin/sh aegir -c "expect automate_install.expect /tmp/install.sh.txt $AEGIR_DOMAIN $USER_EMAIL $aegir_safedbpassword"

	# enable cron tab for hosting service 
	# Can this script be run before Drupal setup?
	# su -s /bin/sh aegir
	# php /var/aegir/drush/drush.php --uri=http://aegir.$AEGIR_HOSTNAME.com hosting_setup

	if [ "$SETUP_ACL" = "Yes" ]
	then
		# Using ACL setup guide here: http://www.debianhelp.co.uk/acl.htm
		apt-get install acl
		mount -o remount,acl /dev/xvda
		sed -i'-orig' 's/noatime,errors=remount-ro/acl,noatime,errors=remount-ro/' /etc/fstab

		# add Aegir group ACL permissions
		setfacl -R -m g:aegir:rwx /var/aegir
		setfacl -R -m d:g:aegir:rwx /var/aegir
	else 
		echo "Skipping ACL setup because of user preference."
		echo "setup_acl : $SETUP_ACL"
	fi
}

function drupal_admin_menu_fix () {
  # Fixes error in Drupal admin menu -- see: http://groups.drupal.org/node/85919 
	cd /var/aegir/hostmaster-0.4-alpha12/profiles/hostmaster/modules/admin_menu

	wget -O - http://drupal.org/files/issues/615058-adminmenu-php53-D6-1.patch | patch -p0
}

function replace_special_shell_characters () {
  # Replace ! $ \ : ; characters with command line safe equivalent
  new_string=$1
  new_string=${new_string//!/\!}
  new_string=${new_string//$/\$}
  new_string=${new_string//\/\\}
  new_string=${new_string//:/\:}
  new_string=${new_string//;/\;}
  
  echo $new_string
}

function tune_php_to_aegir () {
  sudo sed -i 's/memory_limit = 32M/memory_limit = 128M/' /etc/php5/apache2/php.ini

}

function tune_set_hostname () {
  # Set hostname (required for Aegir platform to function properly)
  echo "$AEGIR_HOSTNAME" > /etc/hostname
  hostname -F /etc/hostname
}


system_update
postfix_install_loopback_only
tune_set_hostname
mysql_install "$DB_PASSWORD" && mysql_tune 40
php_install_with_apache && php_tune
tune_php_to_aegir
goodstuff
aegir_install
# drupal_admin_menu_fix
restartServices