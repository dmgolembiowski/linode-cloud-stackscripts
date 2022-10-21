# linode/lemp-ree-passenger.sh by eclubb
# id: 271
# description: CentOS/Fedora, Ruby Enterprise Edition, hardened PHP, Nxginx (w/ Passenger, PHP-FPM), MySQL
# defined fields: name-db_password-label-mysql-root-password-name-ree_version-label-ruby-enterprise-edition-version-default-187-201001-example-187-201001-name-install_prefix-label-install-prefix-for-ree-and-passenger-default-optlocal-example-optlocal-will-install-ree-to-optlocalree-name-rr_env-label-railsrack-environment-to-run-default-production-name-install_mysql_gem-label-install-mysql-gem-oneof-yesno-name-install_sqlite_gem-label-install-sqlite3-gem-oneof-yesno-default-no
# images: ['linode/centos5.632bit', 'linode/centos5.6', 'linode/fedora1132bit']
# stats: Used By: 1 + AllTime: 103
#!/bin/bash

# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="ree_version" Label="Ruby Enterprise Edition Version" default="1.8.7-2010.01" example="1.8.7-2010.01" />
# <UDF name="install_prefix" Label="Install Prefix for REE and Passenger" default="/opt/local" example="/opt/local will install REE to /opt/local/ree" />
# <UDF name="rr_env" Label="Rails/Rack environment to run" default="production" />
# <UDF name="install_mysql_gem" label="Install MySQL gem" oneOf="yes,no" />
# <UDF name="install_sqlite_gem" label="Install Sqlite3 gem" oneOf="yes,no" default="no" />

case "$-" in
  *i*)
  PATH=$(cd ${0%/*} && pwd -P)
  source "${PATH}/ssinclude-154"
  source "${PATH}/ssinclude-269"
  source "${PATH}/ssinclude-270"
  ;;
  *)
  source '<ssinclude StackScriptID="154">' # StackScript Bash Library for RH Derivatives
  source '<ssinclude StackScriptID="269">' # REE + Nginx + Passenger Library
  source '<ssinclude StackScriptID="270">' # PHP-FPM Library
  ;;
esac

function doit {
  enable_epel_repo
  system_update
  yum install -y sudo wget htop bzip autoconf

  mysql_install "$DB_PASSWORD" && mysql_tune 40
  chkconfig --level 35 mysqld on

  ree_nginx_passenger_install
  chkconfig --level 35 nginx on

  php-fpm_install

  cd ~
  restartServices

  #read -p "Press any key to continue... " -n1 -s
}

doit | tee /tmp/stack_script.log