# linode/2012-rails-rumble-mini-stack-official.sh by rumble
# id: 5503
# description: Rails Rumble 2012 - "Mini Stack" - StackScript

This StackScript will install Ruby 1.9.3, RubyGems 1.8.24, Git, and Memcached. It will also configure SSH deploy keys that should be added to your GitHub repository's deploy keys area.

After booting your server for the first time when using this StackScript as its configuration, you should SSH in as root and `tail -f ~/log.txt` to see the progress of the installation. It will take about 10 minutes to complete and will end with a note saying: "StackScript Finished".
# defined fields: 
# images: ['linode/ubuntu10.04lts32bit', 'linode/ubuntu10.04lts', 'linode/ubuntu12.04lts32bit', None]
# stats: Used By: 0 + AllTime: 74
#!/bin/bash

source <ssinclude StackScriptID="1">

logfile="/root/log.txt"

RUBY_VERSION='ruby-1.9.3-p194'
RUBYGEMS_VERSION='1.8.24'

export logfile

echo "StackScript Starting" >> $logfile
echo "********************" >> $logfile

system_update
echo "System Updated" >> $logfile
echo "" >> $logfile

postfix_install_loopback_only
echo "Configured: postfix_install_loopback_only" >> $logfile
echo "" >> $logfile

goodstuff
echo "Installed: goodstuff" >> $logfile
echo "" >> $logfile

apt-get -y install build-essential
apt-get -y install libssl-dev
apt-get -y install libreadline5-dev
apt-get -y install zlib1g-dev
apt-get -y install libyaml-dev
apt-get -y install libxslt-dev
apt-get -y install git
apt-get -y install git-core
apt-get -y install memcached
apt-get -y install libcurl4-openssl-dev
apt-get -y install apache2-prefork-dev
apt-get -y install libapr1-dev
apt-get -y install libaprutil1-dev
apt-get -y install libreadline-dev
echo "Installed: various libraries" >> $logfile
echo "" >> $logfile

# Install Ruby
echo "Installing: Ruby"
echo "$RUBY_VERSION.tar.gz" >> $logfile
echo "$RUBY_VERSION" >> $logfile

echo "" >> $logfile
echo "Downloading: (from calling wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz)" >> $logfile
echo "" >> $logfile
wget ftp://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz  >> $logfile

echo "" >> $logfile
echo "tar output:" >> $logfile
tar xzf $RUBY_VERSION.tar.gz >> $logfile
rm $RUBY_VERSION.tar.gz
cd $RUBY_VERSION

echo "" >> $logfile
echo "Current Directory:" >> $logfile
pwd >> $logfile

echo "" >> $logfile
echo "Ruby configure output: (from calling ./configure --disable-ucontext --enable-pthread)" >> $logfile
echo "" >> $logfile
./configure --disable-ucontext --enable-pthread >> $logfile

echo "" >> $logfile
echo "Ruby make output: (from calling make)" >> $logfile
echo "" >> $logfile
make >> $logfile

echo "" >> $logfile
echo "Ruby make install output: (from calling make install)" >> $logfile
echo "" >> $logfile
make install >> $logfile
cd
rm -rf $RUBY_VERSION

echo "" >> $logfile
echo "Downloading Ruby Gems with wget http://production.cf.rubygems.org/rubygems/rubygems-$RUBYGEMS_VERSION.tgz" >> $logfile
echo "" >> $logfile
wget http://production.cf.rubygems.org/rubygems/rubygems-$RUBYGEMS_VERSION.tgz >> $logfile

echo "" >> $logfile
echo "tar output:" >> $logfile
tar xzvf rubygems-$RUBYGEMS_VERSION.tgz  >> $logfile
rm rubygems-$RUBYGEMS_VERSION.tgz

echo "" >> $logfile
echo "Installing: RubyGems" >> $logfile
cd rubygems-$RUBYGEMS_VERSION
ruby setup.rb >> $logfile
cd
rm -rf rubygems-$RUBYGEMS_VERSION

echo "" >> $logfile
echo "gem update --system:" >> $logfile
gem update --system >> $logfile

ssh -T -oStrictHostKeyChecking=no git@github.com
echo "Configured: github.com as known host" >> $logfile

mkdir -p ~/.ssh

ssh-keygen -N '' -f ~/.ssh/github-deploy-key -t rsa -q
echo "Generated: SSH key for deployment (you need to add ~/.ssh/github-deploy-key.pub to your GitHub repository's deploy keys)" >> $logfile

touch ~/.ssh/config

echo "Host github.com
  IdentityFile ~/.ssh/github-deploy-key" >> ~/.ssh/config

echo "Configured: ~/.ssh/config (this ensures the above deploy key is used for github.com)" >> $logfile

touch ~/.ssh/authorized_keys

curl http://railsrumble.com.s3.amazonaws.com/rumblebot.pub >> ~/.ssh/authorized_keys

chmod 0700 ~/.ssh/
chmod 0644 ~/.ssh/authorized_keys

echo "Configured: ~/.ssh/authorized_keys (do not remove the key for organizers@railsrumble.com, this is necessary for verification)" >> $logfile

restartServices
echo "********************" >> $logfile
echo "StackScript Finished" >> $logfile