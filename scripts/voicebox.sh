# linode/voicebox.sh by funnymonkey
# id: 1905
# description: The VoiceBox installation profile is designed to simplify the work of groups looking to create or expand their online presence. Groups who could use this site range from media organizations to not-for-profits to schools to advocacy groups. If an organization wants to build a place for their stakeholders to publish, interact, and get more informed, then VoiceBox could support that work.

VoiceBox is built on Drupal, and is freely available. Because VoiceBox is built using Drupal from open source components, you are free to take it, install it, and modify it to meet your needs.

VoiceBox was built as part of the Knight Drupal Initiative, which was funded by the Knight Foundation.

Steps to Install:
1. After provisioning a linode. Choose "rebuild" from the control panel.
2. Choose "Deploying Using Stackscripts"
3. Search for voicebox and choose "funnymonkey/voicebox"
4. Wait for the rebuild.
5. Boot the server. Note that booting the server will boot the server and then run the stackscript. Running the stackscript to completion can take several minutes. It is best to monitor the progress via the lish AJAX console. Beginning the voicebox install prior to the stackscript completing can cause errors that are difficult to troubleshoot and resolve. You should monitor the 
progress of the stackscript via the console and wait for the scrolling to stop with a login prompt. It should look something like the following;
<pre>
Ubuntu 10.04 LTS li280-10 hvc0                                                                      

li280-10 login:
</pre>
6. Continue with the voicebox install at the appropriate IP address or hostname if you configured the domain name.

See also:
http://code.funnymonkey.com/introducing-voicebox
http://drupal.org/project/voicebox
# defined fields: name-ssh_user_name-label-ssh-users-login-name-name-ssh_user_password-label-ssh-users-password-name-db_password-label-mysql-root-password-name-db_name-label-create-database-default-drupal-example-optional-drupal-database-name-name-db_user-label-create-mysql-user-default-drupal-example-optional-drupal-database-user-name-db_user_password-label-mysql-users-password-default-example-optional-drupal-database-users-password-name-drupal_hostname-label-drupals-hostname-default-example-optional-eg-wwwexamplecom-leave-this-blank-if-you-do-not-have-a-domain-name
# images: ['linode/ubuntu10.04lts32bit', 'linode/ubuntu10.04lts']
# stats: Used By: 0 + AllTime: 73
#!/bin/bash
# $Id: $
# <UDF name="ssh_user_name" Label="SSH user's login name" />
# <UDF name="ssh_user_password" Label="SSH user's password" />
# <UDF name="db_password" Label="MySQL root Password" />                           
# <UDF name="db_name" Label="Create Database" default="drupal" example="(optional) Drupal database name" />
# <UDF name="db_user" Label="Create MySQL User" default="drupal" example="(optional) Drupal database user" />
# <UDF name="db_user_password" Label="MySQL User's Password" default="" example="(optional) Drupal database user's password" />
# <UDF name="drupal_hostname" Label="Drupal's hostname" default="" example="(optional) eg. www.example.com Leave this blank if you do not have a Domain Name" />

function base_setup {
  if [ ! -n "${DRUPAL_HOSTNAME}" ]; then 
    # default to the linode DNS
    export DRUPAL_HOSTNAME=`hostname`.members.linode.com
  fi
  
  
  # install shar utils for uuencode for password generation
  apt-get -y install sharutils
  
  # install bc used for various math calculations
  apt-get -y install bc
  
  #export DB_PASSWORD=`head -c 16 < /dev/random | uuencode -m - | sed '1d' | sed '2d'`
  #export DB_NAME=voicebox
  #export DB_USER=voicebox
  #export DB_USER_PASSWORD=voicebox
  export SERVERSTATS_HTACCESS_USERNAME=admin
  export SERVERSTATS_HTACCESS_PASSWORD=`head -c 16 < /dev/random | uuencode -m - | sed '1d' | sed '2d'`
  
  
}

###########################################################
# Users with sudo
###########################################################
function add_sudo_user {
  if [ -n "$1" ]; then
    # $1 - username
    # $2 - password
    USERNAME=`echo $1 | tr A-Z a-z`
    PASSWORD=$2
    SHELL="/bin/bash"
    useradd --create-home --shell "$SHELL" --user-group --groups sudo "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
  fi
}

###########################################################
# mysql-server
###########################################################
function mysql_install {
  # $1 - the mysql root password

  if [ ! -n "$1" ]; then
    echo "mysql_install() requires the root pass as its first argument"
    return 1;
  fi

  echo "mysql-server-5.1 mysql-server/root_password password $1" | debconf-set-selections
  echo "mysql-server-5.1 mysql-server/root_password_again password $1" | debconf-set-selections
  apt-get -y install mysql-server mysql-client

  echo "Sleeping while MySQL starts up for the first time..."
  sleep 5
}

function mysql_tune {
  sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

  # mysql config options we want to set to the percentages in the second list, respectively
  OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size query_cache_size)
  DISTLIST=(32 4 4 4 8)

  for opt in ${OPTLIST[@]}; do
    # enable the option if it is disabled
    sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
  done

  for i in ${!OPTLIST[*]}; do
    config="${config}\n${OPTLIST[$i]} = ${DISTLIST[$i]}M"
  done

  config="${config}\ntable_cache = 512"

  sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

  # install the MySQL tuning-primer and install the necessary libs
  curl -o /root/tuning-primer.sh http://www.day32.com/MySQL/tuning-primer.sh
  chmod +x /root/tuning-primer.sh

  touch /tmp/restart-mysql
}

function mysql_limit_connections {
  # intended to be ran after apache_tune this limits mysql's max_connections relative to Apache's MaxClients
  MYSQLMAX=`echo "${MAXCLIENTS} * 2" | bc`
  if [ $MYSQLMAX -lt 12 ]
    then MYSQLMAX=12
  fi
  sed -i -e "s/^#max_connections.*/max_connections = ${MYSQLMAX}/" /etc/mysql/my.cnf
  
  touch /tmp/restart-mysql  
}

function mysql_create_database {
  # $1 - the mysql root password
  # $2 - the db name to create

  if [ ! -n "$1" ]; then
    echo "mysql_create_database() requires the root pass as its first argument"
    return 1;
  fi
  if [ ! -n "$2" ]; then
    echo "mysql_create_database() requires the name of the database as the second argument"
    return 1;
  fi

  echo "CREATE DATABASE $2 DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;" | mysql -u root -p$1
}

function mysql_create_user {
  # $1 - the mysql root password
  # $2 - the user to create
  # $3 - their password

  if [ ! -n "$1" ]; then
    echo "mysql_create_user() requires the root pass as its first argument"
    return 1;
  fi
  if [ ! -n "$2" ]; then
    echo "mysql_create_user() requires username as the second argument"
    return 1;
  fi
  if [ ! -n "$3" ]; then
    echo "mysql_create_user() requires a password as the third argument"
    return 1;
  fi

  echo "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';" | mysql -u root -p$1
}

function mysql_grant_user {
  # $1 - the mysql root password
  # $2 - the user to bestow privileges 
  # $3 - the database

  if [ ! -n "$1" ]; then
    echo "mysql_create_user() requires the root pass as its first argument"
    return 1;
  fi
  if [ ! -n "$2" ]; then
    echo "mysql_create_user() requires username as the second argument"
    return 1;
  fi
  if [ ! -n "$3" ]; then
    echo "mysql_create_user() requires a database as the third argument"
    return 1;
  fi

  echo "GRANT ALL PRIVILEGES ON $3.* TO '$2'@'localhost';" | mysql -u root -p$1
  echo "FLUSH PRIVILEGES;" | mysql -u root -p$1

}

###########################################################
# Apache
###########################################################

function apache_install {
  # installs the system default apache2 MPM
  aptitude -y install apache2

  a2dissite default # disable the interfering default virtualhost

  # clean up, or add the NameVirtualHost line to ports.conf
  sed -i -e 's/^NameVirtualHost \*$/NameVirtualHost *:80/' /etc/apache2/ports.conf
  if ! grep -q NameVirtualHost /etc/apache2/ports.conf; then
    echo 'NameVirtualHost *:80' > /etc/apache2/ports.conf.tmp
    cat /etc/apache2/ports.conf >> /etc/apache2/ports.conf.tmp
    mv -f /etc/apache2/ports.conf.tmp /etc/apache2/ports.conf
  fi
  
  # Server stats runs on 8080
  echo "NameVirtualHost *:8080" >> /etc/apache2/ports.conf
  echo "Listen 8080" >> /etc/apache2/ports.conf
}

function apache_tune {
  # sets AVAIL
  available_memory
  
  PERPROCMEM=96 # the amount of memory in MB each apache process is likely to utilize
  MAXCLIENTS=`echo "$AVAILMEM/$PERPROCMEM" | bc`
  
  # 6 MaxClients is an absolute minimum... lower than this and Apache just doesn't work properly
  if [ $MAXCLIENTS -lt 6 ]
    then MAXCLIENTS=6
  fi
  
  sed -i -e "s/\(^[ \t]*MaxClients[ \t]*\)[0-9]*/\1$MAXCLIENTS/" /etc/apache2/apache2.conf

  mysql_limit_connections

  touch /tmp/restart-apache2
}

function apache_virtualhost {
  # Configures a VirtualHost

  # $1 - required - the hostname of the virtualhost to create 
  if [ ! -n "$1" ]; then
    echo "apache_virtualhost() requires the hostname as the first argument"
    return 1;
  fi

  if [ -e "/etc/apache2/sites-available/$1" ]; then
    echo /etc/apache2/sites-available/$1 already exists
    return;
  fi

  mkdir -p /srv/www/$1/public_html 

  echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$1
  echo "    ServerName $1" >> /etc/apache2/sites-available/$1
  echo "    DocumentRoot /srv/www/$1/public_html/" >> /etc/apache2/sites-available/$1
  echo "    ErrorLog /var/log/apache2/$1-error.log" >> /etc/apache2/sites-available/$1
        echo "    CustomLog /var/log/apache2/$1-access.log combined" >> /etc/apache2/sites-available/$1
  echo "</VirtualHost>" >> /etc/apache2/sites-available/$1

  a2ensite $1

  touch /tmp/restart-apache2
}

function apache_virtualhost_from_rdns {
  # Configures a VirtualHost using the rdns of the first IP as the ServerName

  apache_virtualhost $(get_rdns_primary_ip)
}


function apache_virtualhost_get_docroot {
  if [ ! -n "$1" ]; then
    echo "apache_virtualhost_get_docroot() requires the hostname as the first argument"
    return 1;
  fi

  if [ -e /etc/apache2/sites-available/$1 ];
    then echo $(awk '/DocumentRoot/ {print $2}' /etc/apache2/sites-available/$1 )
  fi
}           

###########################################################
# PHP
###########################################################
function php_tune {
  sed -i -e "s/^upload_max_filesize = [0-9]*M/upload_max_filesize = 16M/" /etc/php5/apache2/php.ini # set max upload to 16M
  sed -i -e "s/^post_max_size = [0-9]*M/post_max_size = 18M/" /etc/php5/apache2/php.ini # set max upload to 16M
  
  # configure apc
  apt-get -y install php-apc
  
  echo 'apc.shm_size="64"' >> /etc/php5/apache2/conf.d/apc.ini
}


###########################################################
# Postfix
###########################################################
 
function postfix_install_loopback_only {
    # Installs postfix and configure to listen only on the local interface. Also
    # allows for local mail delivery
 
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string localhost" | debconf-set-selections
    echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
    aptitude -y install postfix
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"
    #/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"
 
    touch /tmp/restart-postfix
}
 
###########################################################
# Other niceties!
###########################################################
 
function goodstuff {
    # Installs the REAL vim, wget, less, and enables color root prompt and the "ll" list long alias
 
    aptitude -y install wget vim less screen
    sed -i -e 's/^#PS1=/PS1=/' /root/.bashrc # enable the colorful root bash prompt
    sed -i -e "s/^#alias ll='ls -l'/alias ll='ls -al'/" /root/.bashrc # enable ll list long alias <3
}
 
###########################################################
# utility functions
###########################################################
 
function restartServices {
    # restarts services that have a file in /tmp/needs-restart/
 
    for service in $(ls /tmp/restart-* | cut -d- -f2); do
        /etc/init.d/$service restart
        rm -f /tmp/restart-$service
    done
}

###########################################################
# FunnyMonkey
###########################################################

function drush_install {
  apt-get install -y cvs php5-cli

  if [ ! -e /usr/local/bin/drush ]; then
    cd /usr/local && cvs -z6 -d:pserver:anonymous:anonymous@cvs.drupal.org:/cvs/drupal-contrib checkout -d drush contributions/modules/drush                          
    if [ ! -f /usr/local/drush/drush ]; then                                           
           echo "Could not checkout drush from cvs"
           exit 1
    fi
    /usr/local/drush/drush -y dl drush && cd /usr/local/bin && ln -s ../drush/drush drush                                                                             
    if [ ! -x /usr/local/bin/drush ]; then                                       
           echo "Could not install drush in /usr/local/bin"
           exit 1
    fi
  fi
}

function fix_locales {
  apt-get install -y locales
  locale-gen en_US.UTF-8
}

function VoiceBox_install {
  VPATH=$(apache_virtualhost_get_docroot $1)

  if [ ! -n "$VPATH" ]; then
    echo "Could not determine DocumentRoot for $1"
    return 1;                                     
  fi

  # A few dependencies
  apt-get install -y php5-imap php5-gd php5-dev php-pear php5-mysql php5-curl
  pecl install uploadprogress
  echo "extension=uploadprogress.so" > /etc/php5/apache2/conf.d/uploadprogress.ini

  # lucid has a deprecated comment tag in imap.ini
  sed -i -e 's/# configuration for php Imap module/; configuration for php Imap module/' /etc/php5/cli/conf.d/imap.ini

  # Install the VoiceBox Package
  apt-get install -y libxml-xpath-perl
  wget -O VoiceBox-project.xml http://code.funnymonkey.com/fserver/voicebox/6.x
  RELEASENAME=`xpath -q -e '/project/releases/release[1]/name' VoiceBox-project.xml | \
    perl -e '<STDIN> =~ /<name>(.*)<\/name>/; $name=$1; $name =~ s/ /-/; print $name;'`
  RELEASE=`xpath -q -e '/project/releases/release[1]/download_link' VoiceBox-project.xml | \
    perl -e '<STDIN> =~ /<download_link>(.*)<\/download_link>/; print $1;'`

  # download, extract, chown, and get our config file started
  cd $VPATH                                                  
  cd .. && rm -rf public_html                                
  wget -O $RELEASENAME.tgz $RELEASE
  tar -zxf $RELEASENAME.tgz
  mv `find . -maxdepth 1 -type d -name 'voicebox*'` public_html
  drush_install

  cd $VPATH                                                         

  # fix issue with the mimedetect module See; http://drupal.org/node/306217
  echo "\$conf['mimedect_magic'] = '/usr/share/file/magic'; " >> sites/default/default.settings.php

  cp sites/default/default.settings.php sites/default/settings.php  
  mkdir sites/default/files                                         
  chmod 640 sites/default/settings.php                              
  # make sure to only issue recursive chown if we are where we think we are
  cd $VPATH && chown -R root:root .                                              
  chown -R www-data:www-data $VPATH/sites/default/files
  chown -R www-data:www-data $VPATH/sites/default/settings.php
  # database configuration
  if [ ! -n "$DB_USER_PASSWORD" ]; then
    DB_USER_PASSWORD=$(randomString 20)
  fi                                         

  mysql_create_database "$DB_PASSWORD" "$DB_NAME"
  mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
  mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"          

  # setup crontab and clean-urls
  echo "0 * * * * /usr/local/bin/drush -r $VPATH cron >/dev/null" | crontab -
  a2enmod rewrite

  # make sure there is a minimum of 96M for php
  sed -i "/^memory_limit/s/=.*/= 96M/" /etc/php5/apache2/php.ini

  touch /tmp/restart-apache2  
}

function iptables_install {
  # write the initial iptables file
  iptablesFile="/etc/iptables-"`date +%Y%m%d`

cat > $iptablesFile <<EOF
*filter 
-A INPUT -d 127.0.0.0/8 -i ! lo -j REJECT --reject-with icmp-port-unreachable 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth0 -j ACCEPT 
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -i eth1 -p icmp -m icmp --icmp-type 8 -m limit --limit 1/sec -j ACCEPT 
-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name DEFAULT --rsource -j DROP 
-A INPUT -p tcp -m tcp --dport 22 -m state --state NEW -m recent --set --name DEFAULT --rsource 
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT 
-A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT 
-A INPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
EOF

  ln -sf $iptablesFile /etc/iptables
}

function make_iptables_resilient {
  cat >> /etc/network/interfaces <<"INTERFACES"
        pre-up iptables-restore < /etc/iptables
        post-down iptables-save -c > /etc/iptables-`date +%Y%m%d`
INTERFACES
}

function serverstats_install {
  apt-get install -y serverstats

  # modify the serverstats config file to enable apache and mysql monitoring
  cp /etc/serverstats/simple.php /etc/serverstats/simple.php-`date +%Y%m%d%H%M%S`
  cat /etc/serverstats/simple.php | \
    perl -e "
      \$/=undef; 
      \$config = <STDIN>; 
      \$config =~ s/(apache.*?used[^>]+>)[^,]+,/\$1 true,/s;
      \$config =~ s/(apache.*?hosts[^>]+>)[^,]+,/\$1 array('localhost:8080'),/s; 
      \$config =~ s/(mysql.*?used[^>]+>)[^,]+,/\$1 true,/s; 
      \$config =~ s/(mysql.*?user[^>]+>)\s*'[^']+',/\$1 '$DB_USER',/s; 
      \$config =~ s/(mysql.*?password[^>]+>)\s*'[^']+',/\$1 '$DB_USER_PASSWORD',/s; 
      print \$config;" > \
    /tmp/simple.php
  mv /tmp/simple.php /etc/serverstats/simple.php

  # define_syslog_variables() is deprecated
  sed -i -e 's/define_syslog_variables()\;//' /usr/share/serverstats/includes/logger_syslog.class.php

  enable_server_stats_apache

  # enable serverstats cronjob
  crontab -l > /tmp/serverstats_install_crontab
  echo "* * * * * php /usr/share/serverstats/update.php >/dev/null 2>&1" >> /tmp/serverstats_install_crontab
  cat /tmp/serverstats_install_crontab |crontab -
  rm /tmp/serverstats_install_crontab
  touch /tmp/restart-apache2  
}

function enable_server_stats_apache() {
  # password protect server stats
  HTUSERS_FILE=$(dirname $(apache_virtualhost_get_docroot $DRUPAL_HOSTNAME))/htusers

  htpasswd -bc $HTUSERS_FILE $SERVERSTATS_HTACCESS_USERNAME $SERVERSTATS_HTACCESS_PASSWORD
  a2ensite default
cat > /etc/apache2/sites-enabled/000-default <<SSAPACHE
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost

    DocumentRoot /usr/share/serverstats
    <Directory usr/share/serverstats>
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Order allow,deny
        AuthType Basic
        AuthName "Server Statistics"
        AuthUserFile $HTUSERS_FILE
        require valid-user
        allow from 127.0.0.1
        Satisfy Any
    </Directory>

    ErrorLog /var/log/apache2/error.log

    # Possible values include: debug, info, notice, warn, error, crit,
    # alert, emerg.
    LogLevel warn

    CustomLog /var/log/apache2/access.log combined

</VirtualHost>
SSAPACHE
}

# Instructions: https://help.ubuntu.com/10.04/serverguide/C/automatic-updates.html
function setup_unattented_upgrades {
  apt-get install -y unattended-upgrades

# Is there a way to do this independently of the ubuntu release name?
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<"UUPGRADES"
Unattended-Upgrade::Allowed-Origins {
        "Ubuntu lucid-security";
//      "Ubuntu lucid-updates";
};
UUPGRADES

cat > /etc/apt/apt.conf.d/10periodic <<PERIODIC
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
PERIODIC
}

function setup_fail2ban {
  apt-get install -y fail2ban

  #enable the different jails for fail2ban
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf-`date +%Y%m%d%H%M%S`
  cat /etc/fail2ban/jail.conf | \
    perl -e "
      \$/=undef; 
      \$config = <STDIN>; 
      \$config =~ s/(\[ssh\].*?enabled\s*=\s*)[^\n]+/\$1true,/s; 
      \$config =~ s/(\[ssh-ddos\].*?enabled\s*=\s*)[^\n]+/\$1true,/s; 
      \$config =~ s/(\[apache\].*?enabled\s*=\s*)[^\n]+/\$1true,/s; 
      \$config =~ s/(\[apache-noscript\].*?enabled\s*=\s*)[^\n]+/\$1true,/s; 
      \$config =~ s/(\[apache-overflows\].*?enabled\s*=\s*)[^\n]+/\$1true,/s; 
      print \$config;" > \
    /tmp/jail.conf
  mv /tmp/jail.conf /etc/fail2ban/jail.conf

  touch /tmp/restart-fail2ban
}

function available_memory {
  MEM=$(grep MemTotal /proc/meminfo | awk '{ print int($2/1024) }') # how much memory in MB this system has
  
  if [ $MEM -lt 512 ]
    then MEM=512
  fi

  # Mysql: ~150M this is an approximation it is really 50M + ~50M per thread.
  MYSQLMEM=150
  # apc: 64M  apc.shm_size
  APCMEM=64
  
  # 80% of the total physical RAM minus the above "fixed" values
  AVAILMEM=`echo "$MEM * 8 / 10 - $MYSQLMEM - $APCMEM" | bc`
}



###########################################################
# Actual install steps 
###########################################################
base_setup 
apt-get install -y aptitude
system_update
echo "############################ SETTING UP FIREWALL ############################" 
iptables_install
make_iptables_resilient
iptables-restore < /etc/iptables

fix_locales
postfix_install_loopback_only

echo "############################## SETTING UP MYSQL #############################" 
mysql_install "$DB_PASSWORD" && mysql_tune
goodstuff

echo "########################### SETTING UP APACHE/PHP ###########################" 
apache_install && apache_tune
apache_virtualhost $DRUPAL_HOSTNAME
php_tune

echo "############################ SETTING UP VOICEBOX ############################" 
VoiceBox_install $DRUPAL_HOSTNAME


serverstats_install
setup_unattented_upgrades
setup_fail2ban

add_sudo_user "$SSH_USER_NAME" "$SSH_USER_PASSWORD"

restartServices