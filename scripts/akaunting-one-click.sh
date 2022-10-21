# linode/akaunting-one-click.sh by linode
# id: 923033
# description: Akaunting One-Click
# defined fields: name-company_name-label-company-name-example-my-company-name-company_email-label-company-email-example-mycompanycom-name-admin_email-label-admin-email-example-mycompanycom-name-admin_password-label-admin-password-example-s3cur39a55w0r0-name-db_name-label-mysql-database-name-example-akaunting-name-db_password-label-mysql-root-password-example-s3cur39a55w0r0-name-dbuser-label-mysql-username-example-akaunting-name-dbuser_password-label-mysql-user-password-example-s3cur39a55w0r0
# images: ['linode/ubuntu22.04']
# stats: Used By: 14 + AllTime: 256
#!/bin/bash

# <UDF name="company_name" Label="Company Name" example="My Company" />
# <UDF name="company_email" Label="Company Email" example="my@company.com" />
# <UDF name="admin_email" Label="Admin Email" example="my@company.com" />
# <UDF name="admin_password" Label="Admin Password" example="s3cur39a55w0r0" />

# <UDF name="db_name" Label="MySQL Database Name" example="akaunting" />
# <UDF name="db_password" Label="MySQL root Password" example="s3cur39a55w0r0" />
# <UDF name="dbuser" Label="MySQL Username" example="akaunting" />
# <UDF name="dbuser_password" Label="MySQL User Password" example="s3cur39a55w0r0" />

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null

###########################################################
# Install NGINX
###########################################################
apt-get install -y nginx

cat <<'END' >/var/www/html/index.html
<html>
    <head>
        <InvalidTag charset="UTF-8">
        <InvalidTag name="viewport" content="width=device-width, initial-scale=1">
        <InvalidTag name="title" content="Installing Akaunting">
        <InvalidTag http-equiv="refresh" content="180;url=auth/login" />

        <title>Installing Akaunting</title>

        <link rel="shortcut icon" href="https://akaunting.com/public/images/logo.ico">
        <link media="all" type="text/css" rel="stylesheet" href="https://akaunting.com/public/themes/front/css/bootstrap.css">

        <style type="text/css">
            .row.cloud {
                margin-left  : 0px;
                margin-right : 0px;
            }

            .col-8.col-md-6.avatar {
                padding-left  : 0px;
                padding-right : 0px;
            }

            .col-8.col-md-6.avatar img {
                height : 100%;
            }

            .col-8.col-md-6.message img {
                height       : 16%;
                margin-top   : 300px;
                display      : block;
                margin-left  : auto;
                margin-right : auto;
            }

            .col-8.col-md-6.message p {
                text-align  : center;
                line-height : 26px;
                color       : #404041;
                font-size   : 2em;
            }

            #create-company-content, #create-company-message {
                position : absolute;
                z-index  : -3;
            }
        </style>
    </head>

    <body>
        <div class="row cloud">
            <div class="col-8 col-md-6 avatar">
                <img src="https://akaunting.com/public/assets/media/akaunting_entering.png">
            </div>

            <div class="col-8 col-md-6 message">
                <img src="https://akaunting.com/public/assets/media/akaunting.gif">
                <br>
                <br>
                <p>Installing...<br><br>Get back after 3 minutes!</p>
            </div>
        </div>
    </body>
</html>
END

chown www-data:www-data /var/www/html/index.html
chmod 644 /var/www/html/index.html

###########################################################
# MySQL
###########################################################
apt install -y mariadb-server expect

function mysql_secure_install {
    # $1 - required - Root password for the MySQL database
    [ ! -n "$1" ] && {
        printf "mysql_secure_install() requires the MySQL database root password as its only argument\n"
        return 1;
    }
    local -r db_root_password="$1"
    local -r secure_mysql=$(
expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$db_root_password\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
    printf "$secure_mysql\n"
}

# Set DB root password
echo "mysql-server mysql-server/root_password password ${DB_PASSWORD}" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password ${DB_PASSWORD}" | debconf-set-selections

mysql_secure_install "$DB_PASSWORD"

# Create DB
echo "CREATE DATABASE ${DB_NAME};" | mysql -u root -p"$DB_PASSWORD"

# create DB user with password
echo "CREATE USER '$DBUSER'@'localhost' IDENTIFIED BY '$DBUSER_PASSWORD';" | mysql -u root -p"$DB_PASSWORD"

echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DBUSER'@'localhost';" | mysql -u root -p"$DB_PASSWORD"
echo "FLUSH PRIVILEGES;" | mysql -u root -p"$DB_PASSWORD"


###########################################################
# Install PHP 
###########################################################
apt-get install -y zip unzip php-mbstring php-zip php-gd php-cli php-curl php-intl php-imap php-xml php-xsl php-tokenizer php-sqlite3 php-pgsql php-opcache php-simplexml php-fpm php-bcmath php-ctype php-json php-pdo php-mysql

###########################################################
# Akaunting
###########################################################
mkdir -p /var/www/akaunting \
 && curl -Lo /tmp/akaunting.zip 'https://akaunting.com/download.php?version=latest&utm_source=linode&utm_campaign=developers' \
 && unzip /tmp/akaunting.zip -d /var/www/html \
 && rm -f /tmp/akaunting.zip

cat <<END >/var/www/html/.env
APP_NAME=Akaunting
APP_ENV=production
APP_LOCALE=en-GB
APP_INSTALLED=false
APP_KEY=
APP_DEBUG=false
APP_SCHEDULE_TIME="09:00"
APP_URL=

DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DBUSER}
DB_PASSWORD=${DBUSER_PASSWORD}
DB_PREFIX=

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
LOG_CHANNEL=stack

MAIL_MAILER=mail
MAIL_HOST=localhost
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_NAME=null
MAIL_FROM_ADDRESS=null

FIREWALL_ENABLED=false
END

cd /var/www/html && php artisan key:generate

# Install Akaunting
php /var/www/html/artisan install --db-host="localhost" --db-name="$DB_NAME" --db-username="$DBUSER" --db-password="$DBUSER_PASSWORD" --company-name="$COMPANY_NAME" --company-email="$COMPANY_EMAIL" --admin-email="$ADMIN_EMAIL" --admin-password="$ADMIN_PASSWORD"

# Fix permissions
chown -Rf www-data:www-data /var/www/html
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

###########################################################
# Configure NGINX
###########################################################
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
cat << END > /etc/nginx/nginx.conf
# Generic startup file.
user www-data;

#usually equal to number of CPUs you have. run command "grep processor /proc/cpuinfo | wc -l" to find it
worker_processes  auto;
worker_cpu_affinity auto;

error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

# Keeps the logs free of messages about not being able to bind().
#daemon     off;

events {
worker_connections  1024;
}

http {
#   rewrite_log on;

include mime.types;
default_type       application/octet-stream;
access_log         /var/log/nginx/access.log;
sendfile           on;
#   tcp_nopush         on;
keepalive_timeout  64;
#   tcp_nodelay        on;
#   gzip               on;
        #php max upload limit cannot be larger than this       
client_max_body_size 13m;
index              index.php index.html index.htm;

# Upstream to abstract backend connection(s) for PHP.
upstream php {
        #this should match value of "listen" directive in php-fpm pool
        server unix:/run/php/php$PHP_VERSION-fpm.sock;
        server 127.0.0.1:9000;
}

server {
        listen 80 default_server;

        server_name _;

        root /var/www/html;

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Content-Type-Options "nosniff";

        index index.html index.htm index.php;

        charset utf-8;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        # Prevent Direct Access To Protected Files
        location ~ \.(env|log) {
                deny all;
        }

        # Prevent Direct Access To Protected Folders
        location ~ ^/(^app$|bootstrap|config|database|overrides|resources|routes|storage|tests|artisan) {
                deny all;
        }

        # Prevent Direct Access To modules/vendor Folders Except Assets
        location ~ ^/(modules|vendor)\/(.*)\.((?!ico|gif|jpg|jpeg|png|js\b|css|less|sass|font|woff|woff2|eot|ttf|svg).)*$ {
                deny all;
        }

        error_page 404 /index.php;

        # Pass PHP Scripts To FastCGI Server
        location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)\$;
                fastcgi_pass php;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
        }

        location ~ /\.(?!well-known).* {
                deny all;
        }
}
}
END

# Remove installation screen
rm -f /var/www/html/index.html

service nginx reload

###########################################################
# Firewall
###########################################################
apt-get install ufw -y
ufw limit ssh
ufw allow http
ufw allow https

ufw --force enable

###########################################################
# Stackscript cleanup
###########################################################
rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"