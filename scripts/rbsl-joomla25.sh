# linode/rbsl-joomla25.sh by ssv445
# id: 5717
# description: Setup Joomla Node Ubuntu 10.04 LTS 64bit
# defined fields: name-arg_mysql_root_password-label-mysql-root-password-name-arg_db_name-label-joomla-database-name-name-arg_db_username-label-joomla-database-user-name-name-arg_db_password-label-joomla-database-password-name-arg_joomla_url-label-joomla-download-url-direct-link-to-zip
# images: ['linode/ubuntu10.04lts']
# stats: Used By: 0 + AllTime: 91
#!/bin/bash -x

# <UDF name="ARG_MYSQL_ROOT_PASSWORD" Label="MySQL root Password" />
#
# <UDF name="ARG_DB_NAME" Label="Joomla Database Name" />
# <UDF name="ARG_DB_USERNAME" Label="Joomla Database User Name" />
# <UDF name="ARG_DB_PASSWORD" Label="Joomla Database Password " />

# <UDF name="ARG_JOOMLA_URL" Label="Joomla download URL (direct link to zip)" />


# Include bash functions
source <ssinclude StackScriptID=1>

###########################################################
# joomla functions
###########################################################

function joomla_install {

	# $1 - required - The existing virtualhost to install into

	if [ ! -n "$1" ]; then
		echo "joomla_install() requires the vitualhost as its first argument"
		return 1;
	fi

	if [ ! -e /usr/bin/wget ]; then
		aptitude -y install wget
	fi

	VPATH=$(apache_virtualhost_get_docroot $1)

	if [ ! -n "$VPATH" ]; then
		echo "Could not determine DocumentRoot for $1"
		return 1;
	fi

	# download, extract, chown, and get our config file started
	cd $VPATH
	wget "$ARG_JOOMLA_URL"
	ls -t *Joomla*.zip | xargs -l1 unzip
	ls -t *Joomla*.zip | xargs -l1 rm

    find . -type d -print0 | xargs -0 chmod 0755
	find . -type f -print0 | xargs -0 chmod 0664
	chown www-data -R .
	chgrp www-data -R .

	# database configuration
	mysql_create_database "$ARG_MYSQL_ROOT_PASSWORD" "$ARG_DB_NAME"
	mysql_create_user "$ARG_MYSQL_ROOT_PASSWORD" "$ARG_DB_USERNAME" "$ARG_DB_PASSWORD"
	mysql_grant_user "$ARG_MYSQL_ROOT_PASSWORD" "$ARG_DB_NAME" "$ARG_DB_USERNAME"
}

# update system
system_update
postfix_install_loopback_only

# Install mysql
mysql_install "$ARG_MYSQL_ROOT_PASSWORD" && mysql_tune 40

# install php & apache 
php_install_with_apache && php_tune
apache_install && apache_tune 40 && apache_virtualhost_from_rdns

# optimize
goodstuff

# install joomla
joomla_install $(get_rdns_primary_ip)

# security
#
#apt-get install fail2ban
#apt-get install bash-completion

# finish it
restartServices