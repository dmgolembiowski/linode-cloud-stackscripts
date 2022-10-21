# linode/lamp-setup.sh by newbreed65
# id: 291813
# description: Initial LAMP setup script 
# defined fields: name-db_password-label-mysql-root-password-name-server_user-label-working-user-name-server_pass-label-working-user-password
# images: ['linode/ubuntu16.04lts', 'linode/ubuntu18.10', 'linode/ubuntu18.04']
# stats: Used By: 4 + AllTime: 89
#!/bin/bash
# <UDF name="DB_PASSWORD" Label="MySQL root Password" /> 
# <UDF name="SERVER_USER" Label="Working User" /> 
# <UDF name="SERVER_PASS" Label="Working User Password" /> 

source <ssinclude StackScriptID="1">

exec >/root/stackscript.log 2>&1 

apt-get -y install aptitude 


apt-get install software-properties-common -y --force-yes
add-apt-repository ppa:ondrej/php -y
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C
apt-get update
apt-get install -y --force-yes apache2 php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-curl php7.0-json php7.0-mysql php7.0-gd php7.0-cli php7.0-dev mysql-client
a2enmod rewrite 

echo "mysql-server mysql-server/root_password password $DB_PASSWORD" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DB_PASSWORD" | sudo debconf-set-selections

apt-get -y install mysql-server

sleep 5

mysql -u root --password=$DB_PASSWORD <<-EOF
UPDATE mysql.user SET authentication_string=PASSWORD('$DB_PASSWORD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF

sleep 5

adduser $SERVER_USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo $SERVER_USER:$SERVER_PASS | chpasswd 
usermod -aG sudo $SERVER_USER
usermod -aG www-data $SERVER_USER
chown -R www-data:www-data /var/www
chown -R $SERVER_USER:www-data /var/www

sleep 5

cd /home/hidaway
sudo -u $SERVER_USER -i -- curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 
sudo -u $SERVER_USER -i -- php wp-cli.phar --info  
sudo -u $SERVER_USER -i -- chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp  
 
sleep 5

php_tune && apache_tune && mysql_tune 40 

sleep 5

echo 'install unzip' 
sudo apt-get install zip -qq
sudo apt-get install unzip -qq

echo 'install certbot' 
add-apt-repository ppa:certbot/certbot --yes
apt update -qq
apt install python-certbot-apache -qq --yes

sudo certbot register -q --agree-tos -m certbot@caffeinatedprojects.com 

(crontab  -l ; echo "0 1,13 * * * certbot renew") | crontab -
 
echo 'Configure updates' 
# Configure basic options
cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo 'script finished'
echo 'restarting'

sudo shutdown -r now