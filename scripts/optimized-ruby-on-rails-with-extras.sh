# linode/optimized-ruby-on-rails-with-extras.sh by fagiani
# id: 2253
# description: Installs Ruby 1.9.2 + Node.js + Nginx + Passenger + MySQL/PgSQL + Redis + Git + Bundler + BluePill + Deploy User
# defined fields: name-host_name-label-servers-hostname-default-appserver-name-domain_name-label-type-the-domains-names-for-nginx-config-default-localhost-name-user_name-label-name-of-deployment-user-default-app-name-user_password-label-password-for-deployment-user-name-user_ssh_key-label-deployment-user-public-ssh-key-name-database_type-oneof-mysqlpgsqlboth-label-select-which-database-to-install-default-mysql-name-database_password-label-mysqlpgsql-root-password-name-r_env-label-railsrack-environment-to-run-default-production-name-ruby_release-label-ruby-192-release-default-p290-example-p290-name-nginx_release-label-nginx-release-default-1011-example-1011-name-redis_version-label-redis-version-default-224-example-224
# images: ['linode/ubuntu10.04lts32bit']
# stats: Used By: 0 + AllTime: 100
#!/bin/bash
# stackscript: RoR with L(inux)E(nginx)M(ysql)P(assenger) + extras
# Installs Ruby 1.9.2 + Nginx + Passenger + MySQL + Git + Bundler + BluePill + Deploy User
# author: Paulo Fagiani <pfagiani at gmail>
#
# Things to remember after install or to automate later:
# - adjust server timezone if required
# - put SSL certificate files at /usr/local/share/ca-certificates/
# - customize nginx to suit your app and static files
# - create logrotate file to the deployed app logs
# - generate github/codeplane ssh deployment keys
# - setup reverse DNS on Linode control panel
# - run cap production deploy:setup to configure initial files
#
# <UDF name="host_name" Label="Server's hostname" default="appserver" />
# <UDF name="domain_name" Label="Type the domain(s) name(s) for nginx config" default="localhost" />
# <UDF name="user_name" Label="Name of deployment user" default="app" />
# <UDF name="user_password" Label="Password for deployment user" />
# <UDF name="user_ssh_key" Label="Deployment user public ssh key" />
# <UDF name="database_type" oneof="mysql,pgsql,both" Label="Select which database to install" default="mysql" />
# <UDF name="database_password" Label="MySQL/PgSQL root Password" />
# <UDF name="r_env" Label="Rails/Rack environment to run" default="production" />
# <UDF name="ruby_release" Label="Ruby 1.9.2 Release" default="p290" example="p290" />
# <UDF name="nginx_release" Label="Nginx release" default="1.0.11" example="1.0.11" />
# <UDF name="redis_version" Label="Redis version" default="2.2.4" example="2.2.4" />

exec &> /root/shellstack.log

echo "Installing git and cloning the shellstack script..."
apt-get install -y git-core

git clone git://github.com/fagiani/shellstack.git
shellstack/install rails