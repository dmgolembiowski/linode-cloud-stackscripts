# linode/default-drupal-lamp.sh by timani
# id: 3207
# description: 
# defined fields: name-db_password-label-mysql-root-password-name-db_name-label-create-database-default-pantheon-example-drupal-database-name-name-db_user-label-create-mysql-user-example-drupal-database-user-name-db_user_password-label-mysql-users-password-example-drupal-database-users-password-name-fqdn-label-fully-qualified-domain-name-default-example-optional-fully-qualified-hostname-ie-wwwmydomaincom-if-empty-the-hostname-will-default-to-the-one-assigned-by-linode-name-admin_user-label-administrative-user-default-example-optional-username-to-setup-with-password-less-sudo-access-you-must-also-add-the-ssh-public-key-below-this-user-is-added-as-the-first-step-so-you-can-ssh-in-before-the-script-is-finished-name-admin_pubkey-label-administrative-users-ssh-public-key-default-example-optional-ssh-public-key-from-sshid_dsapub-to-be-associated-with-the-administrative-user-above-name-notify_email-label-send-finish-notification-to-example-email-address-to-send-notification-to-when-finished-build-time-is-just-under-15-minutes
# images: ['linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 94
#!/bin/bash                                                                        
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Create Database" default="pantheon" example="Drupal database name" />
# <UDF name="db_user" Label="Create MySQL User" example="Drupal database user" />
# <UDF name="db_user_password" Label="MySQL User's Password" example="Drupal database user's password" />
# <UDF name="fqdn" Label="Fully Qualified Domain Name" default="" example="Optional fully qualified hostname, ie www.mydomain.com - if empty, the hostname will default to the one assigned by Linode." />
# <UDF name="admin_user" Label="Administrative User" default="" example="Optional username to setup with password-less sudo access.  You must also add the ssh public key below.  This user is added as the first step, so you can ssh in before the script is finished." />
# <UDF name="admin_pubkey" Label="Administrative User's SSH Public Key" default="" example="Optional SSH public key (from ~/.ssh/id_dsa.pub) to be associated with the Administrative User above." />
# <UDF name="notify_email" Label="Send Finish Notification To" example="Email address to send notification to when finished.  Build time is just under 15 minutes." />

# StackScript written by Justin Ellison <justin@techadvise.com>

source <ssinclude StackScriptID="1">

function logit {
    # Simple logging function that prepends an easy-to-find marker '=> ' and a timestamp to a message
    TIMESTAMP=$(date -u +'%m/%d %H:%M:%S')
    MSG="=> ${TIMESTAMP} $1"
    echo ${MSG}
}

function drush_install {
 
    echo
    logit "Installing drush"
    apt-get -y install cvs git-core unzip curl php5-cli php5-gd 
    cd /tmp && git clone --branch 7.x-4.x http://git.drupal.org/project/drush.git drush
    if [ ! -f /tmp/drush/drush ]; then
        echo "Could not checkout drush from git"
        exit 1                            
    fi
 
    cd /usr/local && /tmp/drush/drush -y dl drush --destination=/usr/local
    chmod 755 /usr/local/drush/drush
    cd /usr/local/bin && ln -f -s ../drush/drush drush

    if [ ! -x /usr/local/bin/drush ]; then
        echo "Could not install drush in /usr/local/bin"
        exit 1                    
    fi
 
    cd && rm -rf /tmp/drush
    logit "Done installing drush"
    
    if [ $(echo "$(get_branch) >= 1.1" | /usr/bin/bc) -eq 1 ]; then
      echo
      DRUSH_MAKE_RECOMMENDED_VERSION=`drush pm-releases drush_make-6.x | grep Recommended | awk '{ print $1 }' | cut -d'-' -f2`
      if [ $(echo "$DRUSH_MAKE_RECOMMENDED_VERSION <= 2.2" | /usr/bin/bc) -eq 1 ]; then
        V="6.x-2.x"
      else
        V="6.x"
      fi
      logit "Installing drush_make version ${V}"
      /usr/local/bin/drush dl drush_make-${V} --destination=/usr/local/drush/commands/
    fi
    
}

function get_ubuntu_version {
    VER=$(/usr/bin/lsb_release -rs)
    echo ${VER}
}

function get_ubuntu_version_name {
    NAME=$(/usr/bin/lsb_release -cs)
    echo ${NAME}
}

function update_sources {
    echo 
    logit "Setting up apt sources and applying updates"
    REL_NAME=$(get_ubuntu_version_name)
    apt-get -y install bc
    if [ $(echo "$(get_branch) >= 1.1" | /usr/bin/bc) -eq 1 ]; then
        # Some of Lucid's recommended packages are Karmic-only, and this causes BCFG2 some grief
        echo -e 'APT::Install-Recommends "0";\nAPT::Cache-Limit "100000000";' >> /etc/apt/apt.conf
        # Pin php to 5.2
        /usr/bin/wget http://pantheon-storage.chapterthree.com/mercury.list.1.1 -O /etc/apt/sources.list.d/mercury.list
        /usr/bin/wget http://pantheon-storage.chapterthree.com/lucid -O /etc/apt/preferences.d/lucid
        # New bcfg2 packages in testing break Genshi templates
        sed -i 's/lucidtesting/ppa/g' /etc/apt/sources.list.d/mercury.list
    else
        #Enable universe
        sed -i 's/^#\(.*\) universe/\1 universe/' /etc/apt/sources.list
        #Add bzr and bcfg2 ppa's
        cat <<EOD > /etc/apt/sources.list.d/bzr.list
deb http://ppa.launchpad.net/bzr/ppa/ubuntu ${REL_NAME} main
deb-src http://ppa.launchpad.net/bzr/ppa/ubuntu ${REL_NAME} main
EOD
        cat <<EOD > /etc/apt/sources.list.d/bcfg2.list
deb http://ppa.launchpad.net/bcfg2/ppa/ubuntu ${REL_NAME} main
deb-src http://ppa.launchpad.net/bcfg2/ppa/ubuntu ${REL_NAME} main
EOD
    fi
    
    apt-get install wget
    /usr/bin/wget -O /tmp/keys.txt http://pantheon-storage.chapterthree.com/gpgkeys.txt
    apt-key add /tmp/keys.txt
    apt-get -y update
    apt-get -y upgrade
    apt-get -y dist-upgrade
    
    VER=$(get_ubuntu_version)
    if [ $(echo "${VER} < 10.04" | /usr/bin/bc) -eq 1 ]; then
        # NOTE: When bcfg2 installs memcached, apt starts the service using the default config - a single instance.
        # After bcfg2 reconfigures memcached to use multiple instances, the original single instance's pid is lost, and causes issues.
        # We pre-install it, then stop it so that bcfg2 simply starts it when done configuring it
        apt-get -y install memcached language-pack-en-base 
        dpkg-reconfigure locales
        /etc/init.d/memcached stop
    fi
    logit "Done setting up apt sources and applying updates"
}

function setup_BCFG2 {
    echo
    logit "Setting up BCFG2"
    apt-get -y install bzr bcfg2-server gamin python-gamin python-genshi
    BCFG_FQDN=`getent hosts 127.0.0.1 | awk '{print $2}'`
    REL_NAME=$(get_ubuntu_version_name)
    cat <<EOD > /etc/bcfg2.conf
[server]
repository = /var/lib/bcfg2
plugins = Bundler,Cfg,Metadata,Packages,Probes,Rules,TGenshi
filemonitor = gamin

[statistics]
sendmailpath = /usr/lib/sendmail
database_engine = sqlite3
# 'postgresql', 'mysql', 'mysql_old', 'sqlite3' or 'ado_mssql'.
database_name =
# Or path to database file if using sqlite3.
#<repository>/etc/brpt.sqlite is default path if left empty
database_user =
# Not used with sqlite3.
database_password =
# Not used with sqlite3.
database_host =
# Not used with sqlite3.
database_port =
# Set to empty string for default. Not used with sqlite3.
web_debug = True

[communication]
protocol = xmlrpc/ssl
password = foobat
certificate = /etc/bcfg2.crt
key = /etc/bcfg2.key
ca = /etc/bcfg2.crt

[components]
bcfg2 = https://${BCFG_FQDN}:6789
EOD
    openssl req -batch -x509 -nodes -subj "/C=US/ST=Illinois/L=Argonne/CN=${BCFG_FQDN}" -days 1000 -newkey rsa:2048 -keyout /etc/bcfg2.key -noout
    openssl req -batch -new  -subj "/C=US/ST=Illinois/L=Argonne/CN=${BCFG_FQDN}" -key /etc/bcfg2.key | openssl x509 -req -days 1000 -signkey /etc/bcfg2.key -out /etc/bcfg2.crt
    chmod 0600 /etc/bcfg2.key
    
    rm -rf /var/lib/bcfg2/
        
    bzr branch lp:pantheon/$(get_branch) /var/lib/bcfg2
    if [ $(echo "$(get_branch) < 1.1" | /usr/bin/bc) -eq 1 ]; then
      if [ -n "$(grep 'ubuntu-vps' /var/lib/bcfg2/Metadata/groups.xml)" ]; then
          PROFILE="mercury-ubuntu-vps"
      else 
          PROFILE="mercury-ubuntu-${REL_NAME}-32"
          sed -i "s/jaunty/${REL_NAME}/" /var/lib/bcfg2/Packages/config.xml
          sed -i "s/^    <Group name='amazon-web-services'\/>/    <Group name='rackspace'\/>/" /var/lib/bcfg2/Metadata/groups.xml
          sed -i "s/^    <Group name='ubuntu-jaunty'\/>/    <Group name='ubuntu-${REL_NAME}'\/>/" /var/lib/bcfg2/Metadata/groups.xml
      fi
      cat <<EOD > /var/lib/bcfg2/Metadata/clients.xml
<Clients version="3.0">
   <Client profile="${PROFILE}" pingable="Y" pingtime="0" name="${BCFG_FQDN}"/>
</Clients> 
EOD
    else
      cat <<EOD > /var/lib/bcfg2/Metadata/clients.xml
<Clients version="3.0">
</Clients> 
EOD
    fi

    if [ -n "`grep Fasle /usr/lib/pymodules/python2.6/Bcfg2/Client/Tools/Upstart.py`" ]; then
      sed -i 's/return Fasle/return False/g' /usr/lib/pymodules/python2.6/Bcfg2/Client/Tools/Upstart.py
    fi
    logit "Done setting up BCFG2"
}

function start_BCFG2 {
    echo
    logit "Starting BCFG2 server"
    rm -rf /var/www
    /etc/init.d/bcfg2-server start
    echo "Waiting for BCFG2 to start..."
    while [ -z "$(netstat -atn | grep :6789)" ]; do
      sleep 5
    done
    logit "Done starting BCFG2 server"
    echo
    logit "Running BCFG2 client"
    bcfg2 -vqed
    logit "Done running BCFG2 client"
}
    
function install_pressflow {
    echo
    logit "Installing pressflow"
    if [ $(echo "$(get_branch) < 1.1" | /usr/bin/bc) -eq 1 ]; then
      bzr branch --use-existing-dir lp:pressflow /var/www
      mkdir /var/www/sites/all/modules
      for mod in memcache-6.x-1.x-dev varnish; do
          /usr/local/bin/drush dl --destination=/var/www/sites/all/modules ${mod}
      done
      chmod -R 775 /var/www/sites
      chmod 755 /var/www/sites/all/modules/
    fi
    mkdir /var/www/sites/default/files  
    cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php
    chown -R root:www-data /var/www/*
    chown www-data:www-data /var/www/sites/default/settings.php
    chmod 660 /var/www/sites/default/settings.php
    chmod 775 /var/www/sites/default/files    
	
    # Linode's mysql_create_database function doesn't escape properly, so we use mysqladmin instead
    /usr/bin/mysqladmin create -u root -p"${DB_PASSWORD}" "${DB_NAME}"
    mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
    mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"          
    sed -i "/^$db_url/s/mysql\:\/\/username:password/mysqli\:\/\/$DB_USER:$DB_USER_PASSWORD/" /var/www/sites/default/settings.php                                                              
    sed -i "/^$db_url/s/databasename/$DB_NAME/" /var/www/sites/default/settings.php               
    logit "Done installing pressflow"
}

function install_mercury_profile {
    echo
    logit "Installing Mercury Drupal Profile"
    if [ $(echo "$(get_branch) >= 1.1" | /usr/bin/bc) -eq 1 ]; then
        rm -rf /var/www
    	drush make --working-copy /etc/mercury/mercury.make /var/www/
    else
        bzr --use-existing-dir branch lp:pantheon/profiles /var/www/profiles/
    fi
    logit "Done installing Mercury Drupal Profile"
}

function install_solr {
    logit "Installing Solr"
    SOLR_TGZ='http://apache.inetbridge.net/lucene/solr/1.4.0/apache-solr-1.4.0.tgz'
    apt-get -y install tomcat6
    wget "${SOLR_TGZ}" -O /var/tmp/solr.tgz
    cd /var/tmp/
    tar -xzf solr.tgz
    if [ $(echo "$(get_branch) >= 1.1" | /usr/bin/bc) -eq 1 ]; then
    	mkdir /var/solr
        mv apache-solr-1.4.0/example/solr /var/solr/default
    else
        mv apache-solr-1.4.0/example/solr /var/
    fi
    mv apache-solr-1.4.0/dist/apache-solr-1.4.0.war /var/solr/solr.war
    chown -R tomcat6:root /var/solr/
    VER=$(get_ubuntu_version)
    if [ $(echo "${VER} < 10.04" | /usr/bin/bc) -eq 1 ]; then
        # Workaround for bug reported here: http://colabti.org/irclogger/irclogger_log/bcfg2?date=2010-04-01#l29
        # Since bcfg2 hangs when starting jsvc, we pre-install and configure everything tomcat, so bcfg2 doesn't attempt to reconfig and restart it.
        apt-get -y install ca-certificates-java default-jre-headless gcj-4.3-base icedtea-6-jre-cacao java-common \
          libaccess-bridge-java libcommons-collections-java libcommons-dbcp-java libcommons-pool-java libcups2 \
          libecj-java libecj-java-gcj libgcj9-0 libgcj9-jar libgcj-bc libgcj-common liblcms1 libservlet2.5-java \
          rhino tomcat6 tzdata-java
        cp /var/lib/bcfg2/Cfg/etc/default/tomcat6/tomcat6 /etc/default/tomcat6
        chown -R root:tomcat6 /etc/tomcat6/Catalina
        cp /var/lib/bcfg2/Cfg/etc/tomcat6/Catalina/localhost/solr.xml/solr.xml /etc/tomcat6/Catalina/localhost/solr.xml
        if [ -e /var/lib/bcfg2/TGenshi/etc/tomcat6/server.xml/template.newtxt ]; then
            # "New" way of firing probes instead of running config_mem.sh
            THREADS=$(bash /var/lib/bcfg2/Probes/set_tomcat_max_threads)
            cp /var/lib/bcfg2/TGenshi/etc/tomcat6/server.xml/template.newtxt /etc/tomcat6/server.xml
            sed -i "s/\${metadata.Probes\['set_tomcat_max_threads'\]}/${THREADS}/" /etc/tomcat6/server.xml
        else
            cp /var/lib/bcfg2/Cfg/etc/tomcat6/server.xml/server.xml /etc/tomcat6/server.xml
        fi
        /etc/init.d/tomcat6 restart
    fi
    logit "Done installing Solr"
}

function install_solr_module {
    echo
    logit "Installing Solr Drupal module"
    if [ $(echo "$(get_branch) < 1.1" | /usr/bin/bc) -eq 1 ]; then
      drush dl --destination=/var/www/sites/all/modules apachesolr
      /usr/bin/wget http://solr-php-client.googlecode.com/files/SolrPhpClient.r22.2009-11-09.tgz -O /tmp/SolrPhpClient.tgz
      tar -xvzf /tmp/SolrPhpClient.tgz -C /var/www/sites/all/modules/apachesolr/
      CONFPATH=/var/solr/conf/
    else
      CONFPATH=/var/solr/default/conf/
    fi
    mv /var/www/sites/all/modules/apachesolr/schema.xml ${CONFPATH}
    mv /var/www/sites/all/modules/apachesolr/solrconfig.xml ${CONFPATH}
    logit "Done installing Solr Drupal module"
}

function init_mercury {
    echo
    logit "Initializing Mercury"
    hostname $(get_rdns_primary_ip) 
    
    if [ -n "$(grep netstat /etc/mercury/init.sh)" ]; then
        # The changes we need to be there are present, we can just call init.sh
        /etc/mercury/init.sh
    elif [ -n "$(grep headless /etc/mercury/init.sh)" ]; then
        MYSQL_ROOT_PASSWORD="${DB_PASSWORD}" /etc/mercury/init.sh --headless
    else
        # We need to manually run some of this
        echo `date` > /etc/mercury/incep
        ID=`hostname -f | md5sum | sed 's/[^a-zA-Z0-9]//g'`
        /etc/mercury/config_mem.sh
        curl "http://getpantheon.com/pantheon.php?id=$ID&product=mercury"
    fi
    logit "Done initializing Mercury"
}

function get_branch {
	REL_NAME=$(get_ubuntu_version_name)
    if [ "${REL_NAME}" == "lucid" ]; then
        echo "1.1"
    else
        echo "1.0"
    fi
}

function prepare_hudson {
    logit "Configuring hudson"
    # This should be done by bcfg2, but isn't
    sed -i 's/HUDSON_ARGS="\(.*\)"/HUDSON_ARGS="\1 --httpListenAddress=localhost"/' /etc/default/hudson
    echo "hudson ALL = NOPASSWD: /usr/local/bin/drush, /etc/mercury/init.sh, /usr/bin/fab, /usr/sbin/bcfg2" >> /etc/sudoers
    usermod -a -G shadow hudson
    cat <<EOD > /etc/logrotate.d/hudson
/var/log/hudson/hudson.log
{
  daily
  copytruncate
  missingok
  compress
  delaycompress
  notifempty
  rotate 8
}
EOD
    logit "Done configuring hudson"
}

function set_fqdn {
    logit "Setting FQDN to $1"
    FQDN=$1
    HOSTNAME=`echo "${FQDN}" | cut -d'.' -f1`
    DOMAINNAME=`echo "${FQDN}" | cut -d'.' -f2-`
    logit "Hostname is ${HOSTNAME}, domain name is ${DOMAINNAME}"
    echo "${HOSTNAME}" > /etc/hostname
    sed -i "s/domain .*/domain ${DOMAINNAME}/" /etc/resolv.conf
    sed -i "s/search .*/search ${DOMAINNAME}/" /etc/resolv.conf
    hostname ${HOSTNAME}
    logit "Done setting FQDN to $1"
}

function add_admin_user {
    USER=$1
    PUBKEY=$2
    logit "Adding admin user '${USER}'"
    useradd -m -G sudo ${USER}
    mkdir -p /home/${USER}/.ssh/
    echo "${PUBKEY}" > /home/${USER}/.ssh/authorized_keys
    chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys
    chmod 600 /home/${USER}/.ssh/authorized_keys
    cat <<EOD >> /etc/sudoers
# Added by Linode Mercury Stackscript
%sudo ALL=NOPASSWD: ALL
EOD
    logit "Done adding admin user '${USER}'"
}

#Log everything to a file
exec &> /root/stackscript.log

if [ -n "${ADMIN_USER}" ]; then
    if [ -n "${ADMIN_PUBKEY}" ]; then
        add_admin_user "${ADMIN_USER}" "${ADMIN_PUBKEY}"
    fi
fi

if [ -n "${FQDN}" ]; then
    set_fqdn ${FQDN}
fi

logit "StackScript running on `get_ubuntu_version_name` against Mercury `get_branch`"
update_sources
logit "Installing and configuring Postfix"
postfix_install_loopback_only
logit "Done installing and configuring Postfix"
echo "mysql-server-5.1 mysql-server/root_password password ${DB_PASSWORD}" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password ${DB_PASSWORD}" | debconf-set-selections
setup_BCFG2
#Tomcat looks for solr.war when starting, so we do solr before bcfg2
install_solr
start_BCFG2
drush_install
if [ $(echo "$(get_branch) >= 1.1" | /usr/bin/bc) -eq 1 ]; then
  install_mercury_profile
fi
install_pressflow
install_solr_module 
prepare_hudson

# Do we need to pull a separate mercury profile from launchpad?
if [ ! -e /var/lib/bcfg2/Cfg/var/www/profiles/mercury/mercury.profile ]; then
  if [ $(echo "$(get_branch) < 1.1" | /usr/bin/bc) -eq 1 ]; then
    install_mercury_profile
  fi
fi

init_mercury
echo
logit "Restarting services"
restartServices
logit "Done restarting services"

if [ -n "${NOTIFY_EMAIL}" ]; then
    logit "Sending notification email to ${NOTIFY_EMAIL}"
    /usr/sbin/sendmail "${NOTIFY_EMAIL}" <<EOD
To: ${NOTIFY_EMAIL}
Subject: Mercury StackScript is complete
From: Mercury StackScript <no-reply@linode.com>

Your Mercury installation is complete and now ready to be configured: http://$(system_primary_ip)/install.php  Select "Mercury" as your installation profile, and continue as you normally would.

Enjoy the speed of Mercury!
EOD
fi