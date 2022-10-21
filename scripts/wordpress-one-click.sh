# linode/wordpress-one-click.sh by linode
# id: 401697
# description: Wordpress One Click App
# defined fields: name-site_title-label-website-title-default-my-wordpress-site-example-my-blog-name-soa_email_address-label-e-mail-address-example-your-email-address-name-wp_admin-label-admin-username-example-username-for-your-wordpress-admin-panel-name-wp_password-label-admin-password-example-an0th3r_s3cure_p4ssw0rd-name-dbroot_password-label-mysql-root-password-example-an0th3r_s3cure_p4ssw0rd-name-db_password-label-wordpress-database-password-example-an0th3r_s3cure_p4ssw0rd-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/debian11', 'linode/ubuntu22.04']
# stats: Used By: 5405 + AllTime: 41719
#!/usr/bin/env bash

## WordPress Settings
# <UDF name="site_title" label="Website Title" default="My WordPress Site" example="My Blog">
# <UDF name="soa_email_address" label="E-Mail Address" example="Your email address">
# <UDF name="wp_admin" label="Admin Username" example="Username for your WordPress admin panel">
# <UDF name="wp_password" label="Admin Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="dbroot_password" label="MySQL root Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="db_password" label="WordPress Database Password" example="an0th3r_s3cure_p4ssw0rd">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">


## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -xo pipefail
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

### Installations
function wp_oca_lamp_stack {
    local -r dbroot_password="$1"
    #local -r domain="$2"
    local -r fqdn="$3"
    local -r ip_address="$(system_primary_ip)"

    # Set MySQL root password
    mysql_root_preinstall

    # Install MySQL/MariaDB
    apt install -y mariadb-server
    # Secure MySQL install
    run_mysql_secure_installation

    # Install PHP
    system_install_package php php-curl php-common openssl php-imagick php-json php-mbstring php-mysql pcre2-utils php-xml php-zip apache2 unzip sendmail-bin sendmail
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    ### Configurations

    # MySQL
    mysql -uroot -p"$dbroot_password" -e "CREATE DATABASE wordpressdb"
    mysql -uroot -p"$dbroot_password" -e "GRANT ALL ON wordpressdb.* TO 'wordpress'@'localhost' IDENTIFIED BY '${DB_PASSWORD}'";
    mysql -uroot -p"$dbroot_password" -e "FLUSH PRIVILEGES";

    # Apache
    rm /var/www/html/index.html
    mkdir /var/www/wordpress

    # Configuration of virtualhost file, disables xmlrpc
    # Sets up a virtualhost for either the domain or the IP address
        cat <<END > /etc/apache2/sites-available/wordpress.conf
<Directory /var/www/wordpress/>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
<VirtualHost *:80>
    ServerName $fqdn
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
    # Create log files for WordPress
    mkdir -p /var/log/apache2/wordpress
    touch /var/log/apache2/wordpress/error.log
    touch /var/log/apache2/wordpress/access.log

    # Enable the needed Apache modules
    a2enmod proxy_fcgi setenvif rewrite

    # Enable Keepalives
    sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf
}


function wordpress_oca_install {
    local -r db_password="$1"
    #local -r domain="$2"
    local -r fqdn="$3"
    local -r site_title="$4"
    local -r wpadmin="$5"
    local -r wp_password="$6"
    local -r soa_email_address="$7"
    local -r ip_address="$(system_primary_ip)"


    # Install WordPress
    curl -sLo wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    chmod 755 /usr/local/bin/wp

    # Configure WordPress site
    cd /var/www/wordpress

    wp core download --allow-root

    wp core config --allow-root \
        --dbhost=localhost \
        --dbname=wordpressdb \
        --dbuser=wordpress \
        --dbpass="$db_password"

    # Configure the WordPress site to use the domain
        wp core install --allow-root \
            --url="$fqdn" \
            --title="$site_title" \
            --admin_user="$wpadmin" \
            --admin_email="$soa_email_address" \
            --admin_password="$wp_password" \
            --path="/var/www/wordpress/"

    # Set ownership of the WordPress installation folder
    chown www-data:www-data -R /var/www/wordpress/

    # Configure PHP to play nicely
    sed -i s/post_max_size\ =.*/post_max_size\ =\ 100M/ /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i s/upload_max_filesize\ =.*/upload_max_filesize\ =\ 100M/ /etc/php/$PHP_VERSION/apache2/php.ini
    sed -i s/memory_limit\ =.*/memory_limit\ =\ 256M/ /etc/php/$PHP_VERSION/apache2/php.ini

    # Cron for WordPress updates
    echo "0 1 * * * '/usr/local/bin/wp core update --allow-root --path=/var/www/wordpress' > /dev/null 2>&1" >> wpcron
    crontab wpcron
    rm wpcron

    # Disable the default virtual host
    a2dissite 000-default.conf
    a2ensite wordpress.conf

    # Fix for error stating that 
    # Restart services
    systemctl restart mariadb
    systemctl restart apache2
}


### Main Script

# Open firewall ports
ufw allow http
ufw allow https
ufw allow 25
ufw allow 587
ufw allow 110

wp_oca_lamp_stack "$DBROOT_PASSWORD" "$FQDN" "$FQDN"
wordpress_oca_install "$DB_PASSWORD" "$FQDN" "$FQDN" \
                      "$SITE_TITLE" "$WP_ADMIN" "$WP_PASSWORD" \
                      "$SOA_EMAIL_ADDRESS" 

# SSL
apt install certbot python3-certbot-apache -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'

# Cleanup
stackscript_cleanup