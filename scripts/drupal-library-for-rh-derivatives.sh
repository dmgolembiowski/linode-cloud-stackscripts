# linode/drupal-library-for-rh-derivatives.sh by henszey
# id: 162
# description: 
# defined fields: 
# images: ['linode/centos5.632bit', 'linode/centos5.6', 'linode/fedora1132bit']
# stats: Used By: 0 + AllTime: 1
#!/bin/bash

#RH Bash Lib
case "$-" in
	*i*) 
		PATH=$(cd ${0%/*} && pwd -P)
		source "${PATH}/bash_lib_rh.sh"
	;;
	*) 
		source '<ssinclude StackScriptID="154">'
	;;
esac

function drush_install {

	if [ ! -e /usr/bin/cvs ]; then
		yum -yq install cvs
	fi    
	if [ ! -e /usr/bin/which ]; then
		yum -yq install which
	fi    
	cd /tmp && cvs -z6 -d:pserver:anonymous:anonymous@cvs.drupal.org:/cvs/drupal-contrib checkout -d drush contributions/modules/drush
	if [ ! -f /tmp/drush/drush ]; then
		echo "Could not checkout drush from cvs"
		exit 1                             
	fi

	cd /usr/local && /tmp/drush/drush dl drush && cd bin && ln -s ../drush/drush drush && ln -s /usr/local/bin/drush /usr/bin/drush
	if [ ! -x /usr/local/bin/drush ]; then
		echo "Could not install drush in /usr/local/bin"
		exit 1                     
	fi

	cd && rm -rf /tmp/drush
}

function drush_make_install {
	mkdir ~/.drush && cd ~/.drush && /usr/local/bin/drush dl drush_make
	if [ ! -d ~/.drush/drush_make ]; then
		echo "Could not install drush_make"
		exit 1
	fi
}

function drupal_install {
        # installs the latest drupal version from drupal.org

        # $1 - required - The existing virtualhost to install into

        if [ ! -n "$1" ]; then
                echo "drupal_install() requires the virtualhost as its first argument"
                return 1;                                                             
        fi                                                                            

        if [ ! -e /usr/bin/wget ]; then
                yum -yq install wget
        fi                              

        # Install drush to install drupal latest version
        if [ ! -e /usr/bin/php ]; then
                php_install_with_apache
        fi                                              

        if [ ! -e /usr/local/bin/drush ]; then
		drush_install
        fi                                                                                   

        VPATH=$(apache_virtualhost_get_docroot $1)

        if [ ! -n "$VPATH" ]; then
                echo "Could not determine DocumentRoot for $1"
                return 1;                                     
        fi                                                    

        # download, extract, chown, and get our config file started
        cd $VPATH                                                  
        cd .. && rm -rf public_html                                
        drush dl drupal && mv $(find . -type d -name drupal\*) public_html
        cd $VPATH                                                         
        cp sites/default/default.settings.php sites/default/settings.php  
        mkdir -p sites/default/files                                         
        chmod 640 sites/default/settings.php                              
        chown -R apache: .                                              

        # database configuration
        if [ ! -n "$DB_USER_PASSWORD" ]; then
                DB_USER_PASSWORD=$(randomString 20)
        fi                                         

        mysql_create_database "$DB_PASSWORD" "$DB_NAME"
        mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
        mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"          

        sed -i "/^$db_url/s/mysql\:\/\/username:password/mysqli\:\/\/$DB_USER:$DB_USER_PASSWORD/" sites/default/settings.php                                                              
        sed -i "/^$db_url/s/databasename/$DB_NAME/" sites/default/settings.php               

        # setup crontab and clean-urls
	if [ -e /etc/cron.daily/drupal-crons ]; then
		cat <<EOD >> /etc/cron.daily/drupal-crons
/usr/local/bin/drush -r $VPATH cron >/dev/null
EOD
	else
		cat <<EOD > /etc/cron.daily/drupal-crons
#!/bin/bash
/usr/local/bin/drush -r $VPATH cron >/dev/null
EOD
		chmod 755 /etc/cron.daily/drupal-crons
	fi
        touch /tmp/restart-httpd                                                           

}