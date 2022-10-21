# linode/drupal-lamp.sh by cyberswat
# id: 7748
# description: A simple installation of a Drupal Lamp stack.  Nothing fancy to see here, just a simple, working Drupal install complete with the latest version of Drush (installed via git) ... and nothing else.  The php memory_limit is set to a hard 128MB to allow Drupal an install without issue.
# defined fields: name-db_password-label-mysql-root-password-name-db_drupal_password-label-drupal-db-password-name-drupal_admin_username-label-drupal-admin-username-name-drupal_admin_password-label-drupal-admin-password
# images: [None, 'linode/ubuntu12.04lts32bit']
# stats: Used By: 0 + AllTime: 34
#!/bin/bash -x
# <UDF name="db_password" Label="MySql root password" />
# <UDF name="db_drupal_password" Label="Drupal db password" />
# <UDF name="drupal_admin_username" Label="Drupal admin username" />
# <UDF name="drupal_admin_password" Label="Drupal admin password" />
 
source <ssinclude StackScriptID=1>
system_update
postfix_install_loopback_only
mysql_install "$DB_PASSWORD" && mysql_tune 40
php_install_with_apache && php_tune
apache_install && apache_tune 40 && apache_virtualhost_from_rdns
goodstuff

mysql_create_database "$DB_PASSWORD" drupal
mysql_create_user "$DB_PASSWORD" drupal "$DB_DRUPAL_PASSWORD"
mysql_grant_user "$DB_PASSWORD" drupal drupal

apt-get install git php5-gd -y
a2enmod rewrite
git clone https://github.com/drush-ops/drush.git /opt/drush
ln -s /opt/drush/drush /usr/bin/drush

sed -i'-orig' 's/memory_limit = [0-9]\+M/memory_limit = 128M/' /etc/php5/apache2/php.ini

/usr/bin/drush -y dl drupal --destination=/srv/www/$(get_rdns $(system_primary_ip)) --drupal-project-rename=public_html
mkdir -p /srv/www/$(get_rdns $(system_primary_ip))/public_html/sites/default/files
chown -R www-data:www-data /srv/www/$(get_rdns $(system_primary_ip))/public_html
chmod a+w /srv/www/$(get_rdns $(system_primary_ip))/public_html/sites/default/files
restartServices
/usr/bin/drush site-install -y standard --root=/srv/www/$(get_rdns $(system_primary_ip))/public_html --uri=$(get_rdns $(system_primary_ip)) --account-name=$DRUPAL_ADMIN_USERNAME --account-pass=$DRUPAL_ADMIN_PASSWORD --db-url=mysql://drupal:$DB_DRUPAL_PASSWORD@localhost/drupal