# linode/wordpress-ca.sh by agracie
# id: 347524
# description: 
# defined fields: name-site_title-label-website-title-default-my-wordpress-site-example-my-blog-name-wpadmin-label-admin-username-example-username-for-your-wordpress-admin-panel-name-wp_password-label-admin-password-example-an0th3r_s3cure_p4ssw0rd-name-email-label-e-mail-address-example-your-email-address-name-pubkey-label-ssh-key-example-ssh-rsa-default
# images: ['linode/debian9']
# stats: Used By: 1 + AllTime: 73
#!/bin/bash

# Installs Wordpress and creates first site.

# <UDF name="site_title" Label="Website Title" default="My Wordpress Site" example="My Blog" />
# <UDF name="wpadmin" Label="Admin Username" example="Username for your WordPress admin panel" />
# <UDF name="wp_password" Label="Admin Password" example="an0th3r_s3cure_p4ssw0rd" />
# <UDF name="email" Label="E-Mail Address" example="Your email address" />
# <UDF name="pubkey" Label="SSH Key" example="ssh-rsa..." default="" />

source <ssinclude StackScriptID="401712">

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Set hostname, configure apt and perform update/upgrade

set_hostname
apt_setup_update
if [[ "$PUBKEY" != "" ]]; then
  add_pubkey
fi

apt install haveged -y
DBROOT_PASSWORD=`head -c 32 /dev/random | base64`
DB_PASSWORD=`head -c 32 /dev/random | base64 | tr -d /=+`

# UFW

ufw_install
ufw allow http
ufw allow https
ufw allow 25
ufw allow 587
ufw allow 110
ufw enable
fail2ban_install

# Set MySQL root password on install

mysql_root_preinstall
run_mysql_secure_installation

### Installations

# Install PHP

apt-get install php7.0 php7.0-cli php7.0-curl php7.0-mysql \
php7.0-mcrypt php-pear libapache2-mod-php7.0 php7.0-gd php7.0-common \
php7.0-xml php7.0-zip apache2 mysql-server unzip sendmail -y

#Install WP

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
chmod 755 /usr/local/bin/wp

### Configurations

# MySQL

mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE wordpressdb"
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT ALL ON wordpressdb.* TO 'wordpress'@'localhost' IDENTIFIED BY '$DB_PASSWORD'";
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";

# Apache

rm /var/www/html/index.html
mkdir /var/www/wordpress

# Configuration of virtualhost file, disables xmlrpc

cat <<END > /etc/apache2/sites-available/wordpress.conf
<Directory /var/www/wordpress/>
    Require all granted
</Directory>
<VirtualHost *:80>
    ServerName $IP
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/wordpress/
    ErrorLog /var/log/apache2/wordpress/error.log
    CustomLog /var/log/apache2/wordpress/access.log combined
    <files xmlrpc.php>
      order allow,deny
      deny from all
    </files>
</VirtualHost>
END

mkdir -p /var/log/apache2/wordpress
touch /var/log/apache2/wordpress/error.log
touch /var/log/apache2/wordpress/access.log

# Enable Keepalives

sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf

# Configure WordPress site

cd /var/www/wordpress

wp core download --allow-root

wp core config --allow-root \
--dbhost=localhost \
--dbname=wordpressdb \
--dbuser=wordpress \
--dbpass="$DB_PASSWORD"

wp core install --allow-root \
--url="$IP" \
--title="$SITE_TITLE" \
--admin_user="$WPADMIN" \
--admin_email="$EMAIL" \
--admin_password="$WP_PASSWORD" \
--path="/var/www/wordpress/"

chown www-data:www-data -R /var/www/wordpress/

sed -i s/post_max_size\ =.*/post_max_size\ =\ 150M/ /etc/php/7.0/apache2/php.ini
sed -i s/upload_max_filesize\ =.*/upload_max_filesize\ =\ 150M/ /etc/php/7.0/apache2/php.ini
sed -i s/memory_limit\ =.*/memory_limit\ =\ 256M/ /etc/php/7.0/apache2/php.ini

#Cron for WordPress updates

echo "0 1 * * * '/usr/local/bin/wp core update --allow-root --path=/var/www/wordpress' > /dev/null 2>&1" >> wpcron
crontab wpcron
rm wpcron

# Disable the default virtual host

a2dissite 000-default.conf
a2ensite wordpress.conf

# Restart services

systemctl restart mysql
systemctl restart apache2

stackscript_cleanup