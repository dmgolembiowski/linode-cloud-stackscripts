# linode/setseed-8.sh by benvallack
# id: 97066
# description: PHP 5 - Do Not Use Anymore
# defined fields: name-activationcode-label-enter-your-setseed-license-activation-code-here-setseed-will-not-install-without-this-being-valid-entering-your-activation-code-here-represents-your-acceptance-of-our-eula-available-at-httpsetseedcomeula-name-fqdn-label-the-new-linodes-fully-qualified-domain-name-this-will-also-be-your-setseed-hub-primary-domain-use-a-subdomain-like-appexamplecom-all-websites-you-create-with-setseed-will-then-use-this-domain-as-a-preview-domain-for-example-if-you-created-a-site-with-the-domain-of-wwwsetseedcom-and-your-primary-domain-is-appexamplecom-the-site-would-be-visible-on-wwwsetseedcom-as-well-as-wwwsetseedcomappexamplecom-name-db_root_password-label-mysql-root-password-name-db_setseed_master_password-label-mysql-password-for-setseed_master-user-account-name-smtp_server-label-smtp-sending-server-this-is-used-to-ensure-outbound-email-from-the-server-is-routed-via-a-proper-smtp-server-recommended-smtp-providers-mailgunorg-or-sendgridcom-name-smtp_user-label-smtp-sending-server-username-name-smtp_pass-label-smtp-sending-server-password
# images: ['linode/debian8']
# stats: Used By: 3 + AllTime: 92
#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#

#<UDF name="activationcode" label="Enter your SetSeed license activation code here. SetSeed will not install without this being valid. Entering your activation code here represents your acceptance of our EULA available at http://setseed.com/eula/">
# ACTIVATIONCODE=
#
#<UDF name="fqdn" label="The new Linode's Fully Qualified Domain Name. This will also be your SetSeed Hub primary domain. Use a subdomain like app.example.com - all websites you create with SetSeed will then use this domain as a preview domain. For example, if you created a site with the domain of www.setseed.com and your primary domain is app.example.com, the site would be visible on www.setseed.com as well as www.setseed.com.app.example.com">
# FQDN=
#
#<UDF name="db_root_password" label="MySQL root password" />
# DB_ROOT_PASSWORD=
#
#<UDF name="db_setseed_master_password" label="MySQL password for setseed_master user account" />
# DB_SETSEED_MASTER_PASSWORD=
#
#<UDF name="smtp_server" label="SMTP sending server. This is used to ensure outbound email from the server is routed via a proper SMTP server. Recommended SMTP providers: mailgun.org or sendgrid.com" />
# SMTP_SERVER=
#
#<UDF name="smtp_user" label="SMTP sending server username" />
# SMTP_USER=
#
#<UDF name="smtp_pass" label="SMTP sending server password" />
# SMTP_PASS=
#


exec >/root/stdout.txt
echo "Starting Script"

# This sets the variable $IPADDR to the IP address the new Linode receives.

IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# This updates the packages on the system from the distribution repositories.
apt-get update
apt-get upgrade -y


# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
echo $IPADDR $FQDN >> /etc/hosts

# Install Apache
aptitude -y install apache2
# Disable default and add SetSeed Virtual Host
a2dissite 000-default
echo "<VirtualHost *:80>" > /etc/apache2/sites-available/setseed.conf
echo "    ServerName setseed" >> /etc/apache2/sites-available/setseed.conf
echo "    DocumentRoot /var/www/html/" >> /etc/apache2/sites-available/setseed.conf
echo "    <Directory /var/www/>" >> /etc/apache2/sites-available/setseed.conf
echo "            Options Indexes FollowSymLinks" >> /etc/apache2/sites-available/setseed.conf
echo "            AllowOverride All" >> /etc/apache2/sites-available/setseed.conf
echo "            Require all granted" >> /etc/apache2/sites-available/setseed.conf
echo "    </Directory>" >> /etc/apache2/sites-available/setseed.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/setseed.conf
a2ensite setseed
echo "<!doctype html> <html lang=\"\">     <head>         <meta charset=\"utf-8\">         <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\">         <title>Installing.. Please Wait.</title> 		    <link rel=\"stylesheet\" href=\"https://secure.setseed.com/static/css/style.css?v19\" type=\"text/css\" media=\"screen\" /> 		<script src=\"https://secure.setseed.com/static/js/jquery.js\" type=\"text/javascript\" charset=\"utf-8\"></script> 		<script type=\"text/javascript\"> 			\$(document).ready(function(){ 				function test() { 					\$.ajax({ cache: false, 					    url: \"/sh/\", 					    success: function (data) { 							window.location.href=\"/sh/?installsuccess=1\"; 					    }, 					    error: function (ajaxContext) { 							setTimeout(function () { 								test();  							}, 2000); 					    } 					}); 				} 				setTimeout(function () { 					test();  				}, 2000); 			}); 		</script> 		<style type=\"text/css\" media=\"screen\"> 		#middle { 			position:absolute; 			top:50%; 			left:0; 			width:100%; 			transform:translateY(-50%); 		} 		.spinner { 		  width: 40px; 		  height: 40px; 		  margin: 40px auto; 		  background-color: #333;  		  border-radius: 100%;   		  -webkit-animation: sk-scaleout 1.0s infinite ease-in-out; 		  animation: sk-scaleout 1.0s infinite ease-in-out; 		}  		@-webkit-keyframes sk-scaleout { 		  0% { -webkit-transform: scale(0) } 		  100% { 		    -webkit-transform: scale(1.0); 		    opacity: 0; 		  } 		}  		@keyframes sk-scaleout { 		  0% {  		    -webkit-transform: scale(0); 		    transform: scale(0); 		  } 100% { 		    -webkit-transform: scale(1.0); 		    transform: scale(1.0); 		    opacity: 0; 		  } 		} 		</style>     </head>     <body style=\"background:#fff\"> 		<div id=\"middle\"> 		 		<p style='text-align:center'><img src=\"http://setseed.com/graphics/setseed-logo-for-email.png\" width=\"144\" height=\"67\"/></p> 		<p style=\"text-align:center;font-size:14px;color:#888\">Installing... Please Wait.</p> 		<div class=\"spinner\"></div> 		</div>     </body> </html> " > /var/www/html/index.html

# Install MySQL
echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

apt-get -y install mysql-server mysql-client >> /root/mysqlinstall.txt 2>&1

echo "MYSQL Installed successfully"
mysql -u root -proot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DB_ROOT_PASSWORD'); flush privileges;" >> /root/mysqlinstall.txt 2>&1
echo "MYSQL Root pass successfully changed to $DB_ROOT_PASSWORD"
mysql -u root -p$DB_ROOT_PASSWORD -e "CREATE DATABASE setseed_master DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci; CREATE USER 'setseed_master'@'localhost' IDENTIFIED BY '$DB_SETSEED_MASTER_PASSWORD'; GRANT ALL PRIVILEGES ON *.* TO 'setseed_master'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES; USE setseed_master; CREATE TABLE \`email_campaigns\` (   \`id\` int(11) unsigned NOT NULL AUTO_INCREMENT,   \`hash\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`content\` mediumtext COLLATE latin1_general_ci NOT NULL,   \`subject\` text COLLATE latin1_general_ci NOT NULL,   \`server_name\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`from_name\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`from_email\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`smtp_server\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`username\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`password\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`belongs_to_site\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`webversion\` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',   \`complete\` int(11) NOT NULL,   \`failed\` int(11) NOT NULL,   \`date_created\` datetime NOT NULL,   \`cancelled\` int(11) NOT NULL,   PRIMARY KEY (\`id\`) ) ENGINE=InnoDB AUTO_INCREMENT=128 DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci; CREATE TABLE \`email_queue\` (   \`id\` int(11) unsigned NOT NULL AUTO_INCREMENT,   \`campaign_id\` int(11) NOT NULL,   \`email\` varchar(255) NOT NULL DEFAULT '',   \`first_name\` varchar(255) NOT NULL DEFAULT '',   \`last_name\` varchar(255) NOT NULL DEFAULT '',   \`pending\` int(11) NOT NULL,   \`newsletter_email_id\` int(11) NOT NULL,   \`sent\` int(11) NOT NULL,   \`seen\` int(11) NOT NULL,   \`unsubscribe\` int(11) NOT NULL,   \`failed\` int(11) NOT NULL,   PRIMARY KEY (\`id\`),   KEY \`campaign_id\` (\`campaign_id\`),   KEY \`campaign_id_2\` (\`campaign_id\`,\`sent\`),   KEY \`campaign_id_3\` (\`campaign_id\`,\`seen\`),   KEY \`campaign_id_4\` (\`campaign_id\`,\`unsubscribe\`),   KEY \`campaign_id_5\` (\`campaign_id\`,\`failed\`) ) ENGINE=InnoDB AUTO_INCREMENT=80018 DEFAULT CHARSET=latin1; CREATE TABLE sites (url mediumtext NOT NULL,invisible_key varchar(255) NOT NULL,theme varchar(255) NOT NULL DEFAULT 'default',db_username varchar(255) NOT NULL,db_password varchar(255) NOT NULL,db_name varchar(255) NOT NULL,db_host varchar(255) NOT NULL,branding_name varchar(255) NOT NULL,branding_key varchar(255) NOT NULL,branding_logo_light text NOT NULL,	branding_logo_dark text NOT NULL,branding_favicon text NOT NULL,UNIQUE KEY url (url(300))) ENGINE=MyISAM DEFAULT CHARSET=latin1; CREATE TABLE admin (username varchar(255) NOT NULL,password char(40) NOT NULL,salt varchar(255) NOT NULL,logged_in_key VARCHAR(255) NOT NULL,age VARCHAR(255) NOT NULL,uaip VARCHAR(255) NOT NULL) ENGINE=MyISAM DEFAULT CHARSET=latin1;" >> /root/mysqlinstall.txt 2>&1
echo "setseed_master created with user pass as $DB_SETSEED_MASTER_PASSWORD and initial tables created"

# Install PHP
aptitude -y install php5 php5-mysql libapache2-mod-php5 php5-curl php5-gd


# Enable some mods
a2enmod rewrite
a2enmod headers
a2enmod ssl

# Install IonCube
MODULES=$(php -i | grep extension_dir | awk '{print $NF}')
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xvfz ioncube_loaders_lin_x86-64.tar.gz
sudo cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" $MODULES
echo "zend_extension = $MODULES/ioncube_loader_lin_${PHP_VERSION}.so" >> /etc/php5/apache2/php.ini 
echo "zend_extension = $MODULES/ioncube_loader_lin_${PHP_VERSION}.so" >> /etc/php5/cli/php.ini 
# Restart Apache for changes to take effect
systemctl restart apache2

systemctl enable apache2
systemctl enable mysql

# Install SetSeed
wget -O download.tgz https://secure.setseed.com/main/download_tgz/?c=$ACTIVATIONCODE 
rm -rf /var/www/html
tar -xvzf download.tgz -C /var/www/
mv /var/www/* /var/www/html
chmod 777 /var/www/html/sites
cp -rp /var/www/html/install/default /var/www/html/sites/.
chmod 777 /var/www/html/sites/default/cache
chmod 777 /var/www/html/sites/default/cache/cache
chmod 777 /var/www/html/sites/default/cache/templates_c
chmod 777 /var/www/html/sites/default/cache/configs
chmod 777 /var/www/html/sites/default/downloads
chmod 777 /var/www/html/sites/default/email_attachments
chmod 777 /var/www/html/sites/default/images
chmod 777 /var/www/html/sites/default/images/galleries
chmod 777 /var/www/html/sites/default/images/thumbs
chmod 777 /var/www/html/sites/default/livechatlogs
chmod 777 /var/www/html/sites/default/livechatsaves
chmod 777 /var/www/html/sites/default/media

chmod 777 /var/www/html/sites/customer_signup/cache
chmod 777 /var/www/html/sites/customer_signup/cache/cache
chmod 777 /var/www/html/sites/customer_signup/cache/templates_c
chmod 777 /var/www/html/sites/customer_signup/cache/configs
chmod 777 /var/www/html/sites/customer_signup/downloads
chmod 777 /var/www/html/sites/customer_signup/email_attachments
chmod 777 /var/www/html/sites/customer_signup/images
chmod 777 /var/www/html/sites/customer_signup/images/galleries
chmod 777 /var/www/html/sites/customer_signup/images/thumbs
chmod 777 /var/www/html/sites/customer_signup/livechatlogs
chmod 777 /var/www/html/sites/customer_signup/livechatsaves
chmod 777 /var/www/html/sites/customer_signup/media

chmod 777 /var/www/html/sites/theme-school/cache
chmod 777 /var/www/html/sites/theme-school/cache/cache
chmod 777 /var/www/html/sites/theme-school/cache/templates_c
chmod 777 /var/www/html/sites/theme-school/cache/configs
chmod 777 /var/www/html/sites/theme-school/downloads
chmod 777 /var/www/html/sites/theme-school/email_attachments
chmod 777 /var/www/html/sites/theme-school/images
chmod 777 /var/www/html/sites/theme-school/images/galleries
chmod 777 /var/www/html/sites/theme-school/images/thumbs
chmod 777 /var/www/html/sites/theme-school/livechatlogs
chmod 777 /var/www/html/sites/theme-school/livechatsaves
chmod 777 /var/www/html/sites/theme-school/media

chmod 777 /var/www/html/sites/theme-coffee/cache
chmod 777 /var/www/html/sites/theme-coffee/cache/cache
chmod 777 /var/www/html/sites/theme-coffee/cache/templates_c
chmod 777 /var/www/html/sites/theme-coffee/cache/configs
chmod 777 /var/www/html/sites/theme-coffee/downloads
chmod 777 /var/www/html/sites/theme-coffee/email_attachments
chmod 777 /var/www/html/sites/theme-coffee/images
chmod 777 /var/www/html/sites/theme-coffee/images/galleries
chmod 777 /var/www/html/sites/theme-coffee/images/thumbs
chmod 777 /var/www/html/sites/theme-coffee/livechatlogs
chmod 777 /var/www/html/sites/theme-coffee/livechatsaves
chmod 777 /var/www/html/sites/theme-coffee/media

chmod 777 /var/www/html/sites/theme-adventure/cache
chmod 777 /var/www/html/sites/theme-adventure/cache/cache
chmod 777 /var/www/html/sites/theme-adventure/cache/templates_c
chmod 777 /var/www/html/sites/theme-adventure/cache/configs
chmod 777 /var/www/html/sites/theme-adventure/downloads
chmod 777 /var/www/html/sites/theme-adventure/email_attachments
chmod 777 /var/www/html/sites/theme-adventure/images
chmod 777 /var/www/html/sites/theme-adventure/images/galleries
chmod 777 /var/www/html/sites/theme-adventure/images/thumbs
chmod 777 /var/www/html/sites/theme-adventure/livechatlogs
chmod 777 /var/www/html/sites/theme-adventure/livechatsaves
chmod 777 /var/www/html/sites/theme-adventure/media

rm -rf /var/www/html/install
mv /var/www/html/rename-during-install.htaccess /var/www/html/.htaccess
rm /var/www/html/app/configuration.php

echo "<?php" > /var/www/html/app/configuration.php
echo "/*" >> /var/www/html/app/configuration.php
echo "	Enter the MySQL connection information for your primary SetSeed database below: " >> /var/www/html/app/configuration.php
echo "*/" >> /var/www/html/app/configuration.php
echo "\$mysql_database = \"setseed_master\";" >> /var/www/html/app/configuration.php
echo "\$mysql_username = \"setseed_master\";" >> /var/www/html/app/configuration.php
echo "\$mysql_password = \"$DB_SETSEED_MASTER_PASSWORD\";" >> /var/www/html/app/configuration.php
echo "\$mysql_server = \"localhost\";" >> /var/www/html/app/configuration.php
echo "" >> /var/www/html/app/configuration.php
echo "/* " >> /var/www/html/app/configuration.php
echo "	Enter the primary domain for this server. This can be a generic domain or subdomain that you use to identify and view this server. Enter it without http:// and without a trailing slash. " >> /var/www/html/app/configuration.php
echo "*/" >> /var/www/html/app/configuration.php
echo "\$primaryDomain = \"$FQDN\";" >> /var/www/html/app/configuration.php
echo "" >> /var/www/html/app/configuration.php
echo "// Do not edit below this line //////////////////////////////////////////////////////////////////////////////////////////" >> /var/www/html/app/configuration.php
echo "\$rootdir = dirname(dirname(__FILE__));define( 'ROOT_DIR', \$rootdir );if (!isset(\$installer)) { require_once \"boot.php\"; }" >> /var/www/html/app/configuration.php
echo "?>" >> /var/www/html/app/configuration.php

mkdir /var/www/html/app/cache/cache
mkdir /var/www/html/app/cache/configs
mkdir /var/www/html/app/cache/templates_c

chmod 777 /var/www/html/app/cache
chmod 777 /var/www/html/app/cache/cache
chmod 777 /var/www/html/app/cache/configs
chmod 777 /var/www/html/app/cache/templates_c
chmod 777 /var/www/html/admin/css/css_archives
chmod 777 /var/www/html/admin/javascripts/js_archives
chmod 777 /var/www/html/admin/javascripts/js_archives2

echo "dc_eximconfig_configtype='satellite'" > /etc/exim4/update-exim4.conf.conf
echo "dc_other_hostnames=''" >> /etc/exim4/update-exim4.conf.conf
echo "dc_local_interfaces=''" >> /etc/exim4/update-exim4.conf.conf
echo "dc_readhost=''" >> /etc/exim4/update-exim4.conf.conf
echo "dc_relay_domains=''" >> /etc/exim4/update-exim4.conf.conf
echo "dc_minimaldns='false'" >> /etc/exim4/update-exim4.conf.conf
echo "dc_relay_nets=''" >> /etc/exim4/update-exim4.conf.conf
echo "dc_smarthost='$SMTP_SERVER::587'" >> /etc/exim4/update-exim4.conf.conf
echo "CFILEMODE='644'" >> /etc/exim4/update-exim4.conf.conf
echo "dc_use_split_config='false'" >> /etc/exim4/update-exim4.conf.conf
echo "dc_hide_mailname='true'" >> /etc/exim4/update-exim4.conf.conf
echo "dc_mailname_in_oh='true'" >> /etc/exim4/update-exim4.conf.conf
echo "dc_localdelivery='mail_spool'" >> /etc/exim4/update-exim4.conf.conf

echo "$SMTP_SERVER:$SMTP_USER:$SMTP_PASS" >> /etc/exim4/passwd.client

systemctl restart exim4

echo "*/1 * * * * php \"/var/www/html/sh/email-queue-send.php\" > \"/var/www/html/sh/mailinglist.log\"" > tempct
crontab tempct
rm tempct

echo "#!/bin/bash" > /root/update.sh
echo "ACTIVATIONCODE=\$1" >> /root/update.sh
echo "VERSION=\${2:Latest}-" >> /root/update.sh
echo "wget -O download.tgz \"https://secure.setseed.com/main/download_tgz/?c=\$ACTIVATIONCODE&v=\$VERSION\"" >> /root/update.sh
echo "tar -xvzf download.tgz -C /var/www/" >> /root/update.sh
echo "rm download.tgz" >> /root/update.sh
echo "mv /var/www/SetSeed /var/www/html-new" >> /root/update.sh
echo "cd /var/www" >> /root/update.sh
echo "rm -rf html-old" >> /root/update.sh
echo "cp html/.htaccess html-new/." >> /root/update.sh
echo "cp -rp html-new/themes/global_design_mode_theme html-new/." >> /root/update.sh
echo "rm -rf html-new/themes" >> /root/update.sh
echo "cp -rp html/themes html-new/." >> /root/update.sh
echo "rm -rf html-new/kb_custom_content" >> /root/update.sh
echo "cp -rp html/kb_custom_content html-new/." >> /root/update.sh
echo "cp -rpf html-new/global_design_mode_theme html-new/themes/." >> /root/update.sh
echo "rm -rf html-new/global_design_mode_theme" >> /root/update.sh
echo "rm -rf html-new/libraries/Smarty/custom_plugins/*" >> /root/update.sh
echo "cp -rp html/libraries/Smarty/custom_plugins/* html-new/libraries/Smarty/custom_plugins/." >> /root/update.sh
echo "rm -rf html-new/install" >> /root/update.sh
echo "rm -rf html-new/sites" >> /root/update.sh
echo "mkdir html-new/app/cache/cache" >> /root/update.sh
echo "mkdir html-new/app/cache/configs" >> /root/update.sh
echo "mkdir html-new/app/cache/templates_c" >> /root/update.sh
echo "chmod 777 html-new/app/cache" >> /root/update.sh
echo "chmod 777 html-new/app/cache/cache" >> /root/update.sh
echo "chmod 777 html-new/app/cache/configs" >> /root/update.sh
echo "chmod 777 html-new/app/cache/templates_c" >> /root/update.sh
echo "chmod 777 html-new/admin/css/css_archives" >> /root/update.sh
echo "chmod 777 html-new/admin/javascripts/js_archives" >> /root/update.sh
echo "chmod 777 html-new/admin/javascripts/js_archives2" >> /root/update.sh
echo "cp html/app/configuration.php html-new/app/configuration.php" >> /root/update.sh
echo "mv html/sites html-new/." >> /root/update.sh
echo "mv html html-old" >> /root/update.sh
echo "mv html-new html" >> /root/update.sh
chmod +x /root/update.sh