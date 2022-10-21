# linode/drupal-7-install-akhilesh-rai.sh by suprajit
# id: 11340
# description: This script creates a out of the box D7 site. It has served me well over the past 3 years for several sites! 
# defined fields: name-db_password-label-mysql-root-password-name-db_name-label-create-database-default-drupal-example-drupal-database-name-name-db_user-label-create-mysql-user-default-drupal-example-drupal-database-user-name-db_user_password-label-mysql-users-password-default-example-optionally-drupal-database-users-password-name-drupal_hostname-label-drupals-hostname-default-example-example-wwwexamplecom-name-drupal_admin-label-drupal-admin-user-login-default-example-admin-name-drupal_password-label-drupal-password
# images: ['linode/ubuntu14.04lts', 'linode/ubuntu10.04lts', 'linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 24
#!/bin/bash
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Create Database" default="drupal" example="Drupal database name" />
# <UDF name="db_user" Label="Create MySQL User" default="drupal" example="Drupal database user" />
# <UDF name="db_user_password" Label="MySQL User's Password" default="" example="Optionally Drupal database user's password" />
# <UDF name="drupal_hostname" Label="Drupal's hostname" default="" example="Example www.example.com" />
# <UDF name="drupal_admin" Label="Drupal Admin User Login" default="" example="admin" />
# <UDF name="drupal_password" Label="Drupal Password" />
# If you want to run as a bash script uncomment
# DB_PASSWORD="drupal7"
# DB_NAME="drupal7"
# DB_USER="drupal7"
# DB_USER_PASSWORD="drupal7"

source <ssinclude StackScriptID="1">
#If using bash script use this:
#source /root/ssinclude-1


#d7 install script
function drupal_install {
  apt-get -y install wget
  apt-get -y install php5-gd
  apt-get -y install php-pear

  #get server ready for a php install and include php install script
  rm /root/phpmyadmin.sh
  echo 'echo '"'"'Include /etc/phpmyadmin/apache.conf'"'"' >> /etc/apache2/apache2.conf' >> /root/phpmyadmin.sh
  echo 'apt-get -y install phpmyadmin' >> /root/phpmyadmin.sh

  #Let it all settle down:
  wait
  pear upgrade
  pear channel-discover pear.drush.org
  pear install drush/drush
  echo Installation Starting...
  echo $DB_USER_PASSWORD
  VPATH=$(apache_virtualhost_get_docroot $1)
  echo Path is $VPATH
  cd $VPATH/../
  rm -rf public_html




  #remove vpath slash
  VPATHS=`echo "${VPATH}" | sed -e "s/\/*$//" `
  echo Path now is $VPATHS
  drush dl -y drupal-7
  mv drupal-7* $VPATHS
  #.. instead of: drush dl -y drupal-7 && mv drupal-7* $VPATH
  cd $VPATH
  cp sites/default/default.settings.php sites/default/settings.php
  chmod 640 sites/default/settings.php
  chown -R www-data: .

  # database configuration
  if [ ! -n "$DB_USER_PASSWORD" ]; then
       DB_USER_PASSWORD=$(randomString 20)
  fi

  mysql_create_database "$DB_PASSWORD" "$DB_NAME"
  mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
  mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"

  sed -i "/^$db_url/s/mysql\:\/\/username:password/mysqli\:\/\/$DB_USER:$DB_USER_PASSWORD/" sites/default/settings.php
  sed -i "/^$db_url/s/databasename/$DB_NAME/" sites/default/settings.php
 
  #Modify max execution times to suite drupal better
  sed -i'-orig' 's/memory_limit = [0-9]\+M/memory_limit = 256M/' /etc/php5/apache2/php.ini
  sed -i'-orig' 's/max_execution_time = [0-9]\+/max_execution_time = 20/' /etc/php5/apache2/php.ini


  # setup crontab and clean-urls
  echo "0 * * * * /usr/local/bin/drush -r $VPATH cron >/dev/null" | crontab
  a2enmod rewrite                                                            
  touch /tmp/restart-apache2
  drush site-install standard -y --account-name=$DRUPAL_ADMIN --account-pass=$DRUPAL_PASSWORD --db-url=mysql://$DB_USER:$DB_USER_PASSWORD@localhost/$DB_NAME
}

exec &> /root/stackscript.log
system_update
postfix_install_loopback_only
mysql_install "$DB_PASSWORD" && mysql_tune 40
php_install_with_apache && php_tune
goodstuff
a2enmod rewrite

if [ ! -n "$DRUPAL_HOSTNAME" ]; then
  apache_install && apache_tune 40 && apache_virtualhost_from_rdns
  drupal_install $(get_rdns_primary_ip)
else
  apache_install && apache_tune 40 && apache_virtualhost $DRUPAL_HOSTNAME
  drupal_install $DRUPAL_HOSTNAME
fi

#correcting apache2 installation
rm -rf /etc/apache2/sites-enabled/*
mv /etc/apache2/sites-available/$(get_rdns_primary_ip) /etc/apache2/sites-available/$(get_rdns_primary_ip).conf
cp /etc/apache2/sites-available/$(get_rdns_primary_ip).conf /etc/apache2/sites-enabled/$(get_rdns_primary_ip).conf
sed -i '/#<Directory \/srv\//,+5s/#//' /etc/apache2/apache2.conf
sed -i '/<Directory \/srv\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
sed -i '/NameVirtualHost \*:80/s/^/#/' /etc/apache2/ports.conf

#making files directory writable, needed for ctools and other drupal modules 
chown www-data:www-data $VPATH/sites/default/files

restartServices

service mysql restart

echo 'Installation Complete!'