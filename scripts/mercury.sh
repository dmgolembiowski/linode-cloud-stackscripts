# linode/mercury.sh by lazaros
# id: 701
# description: Mercury
# defined fields: name-db_password-label-mysql-root-password-name-db_name-label-create-database-example-drupal-database-name-name-db_user-label-create-mysql-user-example-drupal-database-user-name-db_user_password-label-mysql-users-password-example-drupal-database-users-password-name-fqdn-label-fully-qualified-domain-name-default-example-optional-fully-qualified-hostname-ie-wwwmydomaincom-if-empty-the-hostname-will-default-to-the-one-assigned-by-linode-name-admin_user-label-administrative-user-default-example-optional-username-to-setup-with-password-less-sudo-access-you-must-also-add-the-ssh-public-key-below-this-user-is-added-as-the-first-step-so-you-can-ssh-in-before-the-script-is-finished-name-admin_pubkey-label-administrative-users-ssh-public-key-default-example-optional-ssh-public-key-from-sshid_dsapub-to-be-associated-with-the-administrative-user-above-name-notify_email-label-send-finish-notification-to-default-example-optional-email-address-to-send-notification-to-when-finished-name-solr_tgz-label-url-for-solr-build-default-httpmirroratlanticmetronetapachelucenesolr140apache-solr-140tgz-example-url-of-apache-solr-build-to-use-see-httphudsonzonesapacheorghudsonjobsolr-trunklastsuccessfulbuildartifacttrunksolrdisttgz-for-a-list-or-use-the-default-name-pantheon_branch-label-which-release-of-mercury-default-10-oneof-10-example-currently-10-is-the-only-supported-release
# images: ['linode/ubuntu10.04lts']
# stats: Used By: 0 + AllTime: 90
#!/bin/bash                                                                        
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Create Database" example="Drupal database name" />
# <UDF name="db_user" Label="Create MySQL User" example="Drupal database user" />
# <UDF name="db_user_password" Label="MySQL User's Password" example="Drupal database user's password" />
# <UDF name="fqdn" Label="Fully Qualified Domain Name" default="" example="Optional fully qualified hostname, ie www.mydomain.com - if empty, the hostname will default to the one assigned by Linode." />
# <UDF name="admin_user" Label="Administrative User" default="" example="Optional username to setup with password-less sudo access.  You must also add the ssh public key below.  This user is added as the first step, so you can ssh in before the script is finished." />
# <UDF name="admin_pubkey" Label="Administrative User's SSH Public Key" default="" example="Optional SSH public key (from ~/.ssh/id_dsa.pub) to be associated with the Administrative User above." />
# <UDF name="notify_email" Label="Send Finish Notification To" default="" example="Optional email address to send notification to when finished." />
# <UDF name="solr_tgz" Label="URL for Solr Build" default="http://mirror.atlanticmetro.net/apache/lucene/solr/1.4.0/apache-solr-1.4.0.tgz" example="URL of Apache Solr build to use.  See http://hudson.zones.apache.org/hudson/job/Solr-trunk/lastSuccessfulBuild/artifact/trunk/solr/dist/*.tgz for a list, or use the default." />
# <UDF name="pantheon_branch" Label="Which release of Mercury?" default="1.0" oneOf="1.0" example="Currently 1.0 is the only supported release.">

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
    apt-get -y install php5-cli php5-gd cvs git-core unzip curl
    cd /tmp && cvs -z6 -d:pserver:anonymous:anonymous@cvs.drupal.org:/cvs/drupal-contrib checkout -d drush contributions/modules/drush
    if [ ! -f /tmp/drush/drush ]; then
        echo "Could not checkout drush from cvs"
        exit 1                            
    fi
 
    cd /usr/local && /tmp/drush/drush dl drush 
    # drush changed dl behavior of itself.  Sometimes it dl's to cwd, other times to ~/.drush/drush
    if [ -d ~/.drush/drush ]; then
        mv ~/.drush/drush .
    fi
    cd bin && ln -s ../drush/drush drush
    if [ ! -x /usr/local/bin/drush ]; then
        echo "Could not install drush in /usr/local/bin"
        exit 1                    
    fi
 
    cd && rm -rf /tmp/drush
    logit "Done installing drush"
}

function get_ubuntu_version {
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d'=' -f2)
    echo ${VER}
}

function get_ubuntu_version_name {
    NAME=$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d'=' -f2)
    echo ${NAME}
}

function update_sources {
	echo 
    logit "Setting up apt sources and applying updates"
    REL_NAME=$(get_ubuntu_version_name)
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

    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8C6C1EFD
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 98932BEC
    apt-get -y update
    apt-get -y install language-pack-en-base
    dpkg-reconfigure locales
    apt-get -y upgrade
    apt-get -y dist-upgrade
    
    # NOTE: When bcfg2 installs memcached, apt starts the service using the default config - a single instance.
    # After bcfg2 reconfigures memcached to use multiple instances, the original single instance's pid is lost, and causes issues.
    # We pre-install it, then stop it so that bcfg2 simply starts it when done configuring it
    apt-get -y install memcached
    /etc/init.d/memcached stop
    logit "Done setting up apt sources and applying updates"
}

function setup_BCFG2 {
	echo
    logit "Setting up BCFG2"
    apt-get -y install bzr bcfg2-server gamin python-gamin python-genshi
    BCFG_FQDN=localhost
    REL_NAME=$(get_ubuntu_version_name)
    cat <<EOD > /etc/bcfg2.conf
[server]
repository = /var/lib/bcfg2
plugins = Base,Bundler,Cfg,Metadata,Packages,Probes,Rules,SSHbase,TGenshi
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
    if [ -n "$(grep '-vps-' /var/lib/bcfg2/Metadata/groups.xml)" ]; then
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
    bzr branch --use-existing-dir lp:pressflow /var/www
    mkdir /var/www/sites/default/files  
    mkdir /var/www/sites/all/modules
    for mod in memcache-6.x-1.x-dev varnish; do
        /usr/local/bin/drush dl --destination=/var/www/sites/all/modules ${mod}
    done
    cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php
    chown -R root:www-data /var/www/*
    chmod -R 775 /var/www/sites
    chmod 755 /var/www/sites/all/modules/
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
    bzr --use-existing-dir branch lp:pantheon/profiles /var/www/profiles/
    logit "Done installing Mercury Drupal Profile"
}

function install_solr {
	echo
    logit "Installing Solr"
    DATE=$(date +%Y-%m-%d)
    apt-get -y install wget tomcat6
    wget "${SOLR_TGZ}" -O /var/tmp/solr.tgz
    cd /var/tmp/
    tar -xzf solr.tgz
    mv apache-solr-1.4.0/example/solr /var/
    mv apache-solr-1.4.0/dist/apache-solr-1.4.0.war /var/solr/solr.war
    # Workaround for bug reported here: http://colabti.org/irclogger/irclogger_log/bcfg2?date=2010-04-01#l29
    # Since bcfg2 hangs when starting jsvc, we pre-install and configure everything tomcat, so bcfg2 doesn't attempt to reconfig and restart it.
    apt-get -y install ca-certificates-java default-jre-headless gcj-4.3-base icedtea-6-jre-cacao java-common \
      libaccess-bridge-java libcommons-collections-java libcommons-dbcp-java libcommons-pool-java libcups2 \
      libecj-java libecj-java-gcj libgcj9-0 libgcj9-jar libgcj-bc libgcj-common liblcms1 libservlet2.5-java \
      rhino tomcat6 tzdata-java
    chown -R tomcat6:root /var/solr/
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
    logit "Done installing Solr"
}

function install_solr_module {
	echo
    logit "Installing Solr Drupal module"
    drush dl --destination=/var/www/sites/all/modules apachesolr
    svn checkout -r22 http://solr-php-client.googlecode.com/svn/trunk/ /var/www/sites/all/modules/apachesolr/SolrPhpClient
    mv /var/www/sites/all/modules/apachesolr/schema.xml /var/solr/conf/
    mv /var/www/sites/all/modules/apachesolr/solrconfig.xml /var/solr/conf/ 
    logit "Done installing Solr Drupal module"
}

function init_mercury {
	echo
    logit "Initializing Mercury"
    hostname $(get_rdns_primary_ip) 
    
    if [ -n "$(grep netstat /etc/mercury/init.sh)" ]; then
        # The changes we need to be there are present, we can just call init.sh
        /etc/mercury/init.sh
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
	if [ "${PANTHEON_BRANCH}" == "1" ]; then
		echo "1.0"
	else
      echo ${PANTHEON_BRANCH}
    fi
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
    sed -i 's/^# %sudo/%sudo /' /etc/sudoers
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

update_sources
echo
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
install_pressflow
install_solr_module 

# Do we need to pull a separate mercury profile from launchpad?
if [ ! -e /var/lib/bcfg2/Cfg/var/www/profiles/mercury/mercury.profile ]; then
  install_mercury_profile
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