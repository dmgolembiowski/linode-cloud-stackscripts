# linode/rails-3-ruby-193-mongodb-redis.sh by simpx
# id: 4465
# description: https://github.com/simpx/scripts/blob/master/stackscript

- Rails 3
- Ruby 1.9.3
- Nginx with Passenger
- Mongodb
- Redis
- Nodejs for javascript runtime
- Git
- Updates rubygems
- Install rails 3
- Install mongoid & bson_ext
- Add deploy user
# after deployment, your can use 
# service mongodb
# /etc/init.d/nginx
# /etc/init.d/redis-server
# defined fields: name-rr_env-label-railsrack-environment-to-run-default-production-name-deploy_user-label-username-of-deploy-user-default-deploy-name-deploy_psw-label-password-of-deploy-user-default
# images: ['linode/ubuntu10.04lts', None]
# stats: Used By: 1 + AllTime: 88
#!/bin/bash
#
# See: https://github.com/simpx/scripts/blob/master/stackscript
# Install: Ruby 1.9.3, Nodejs 0.6.14, Mongodb and Nginx with Passenger
# Reference: https://www.linode.com/stackscripts/view/?StackScriptID=1291
#
# <UDF name="rr_env" Label="Rails/Rack environment to run" default="production" />
# <UDF name="deploy_user" Label="Username of deploy user" default="deploy" />
# <UDF name="deploy_psw" Label="Password of deploy user" default="" />

source <ssinclude StackScriptID=1>

exec &> /root/stackscript.log

# Update packages and install essentials
    cd /tmp
    echo "Start to install! Good Luck!"
    system_update
    apt-get -y install build-essential zlib1g-dev libssl-dev libreadline-gplv2-dev openssh-server libyaml-dev libcurl4-openssl-dev libxslt-dev libxml2-dev libpcre3 libpcre3-dev
    goodstuff
    echo "Essentials installed"

# Install nodejs for javascript runtime
    export NODEJS_VERSION="v0.6.14"
    echo "Installing Nodejs $NODEJS_VERSION"
    echo "Downloading: (from calling wget http://nodejs.org/dist/$NODEJS_VERSION/node-$NODEJS_VERSION.tar.gz)"
    wget http://nodejs.org/dist/$NODEJS_VERSION/node-$NODEJS_VERSION.tar.gz
    echo "Extracting the file"
    tar xzf node-$NODEJS_VERSION.tar.gz
    cd node-$NODEJS_VERSION
    echo "current directory: `pwd`"
    echo "Nodejs Configuration output: (from calling ./configure)"
    ./configure
    echo "Nodejs make output: (form calling make)"
    make
    echo "Nodejs make install output: (from calling make install)"
    make install
    cd ..
    echo "Nodejs installed"

# Install Redis
    export REDIS_VERSION="redis-2.4.10"
    echo "Installing Redis $REDIS_VERSION"
    echo "Downloading: (from calling wget http://redis.googlecode.com/files/$REDIS_VERSION.tar.gz)"
    wget http://redis.googlecode.com/files/$REDIS_VERSION.tar.gz
    tar xzf $REDIS_VERSION.tar.gz
    cd $REDIS_VERSION
    ./configure
    make
    make install
    # Download Configuration for redis
    echo "Downloading Configuration files"
    wget https://raw.github.com/simpx/scripts/master/redis.conf
    wget https://raw.github.com/simpx/scripts/master/redis-server
    mv redis-server /etc/init.d/redis-server
    chmod +x /etc/init.d/redis-server
    mv redis.conf /etc/redis.conf
    # Add redis user
    echo "Add Redis user"
    mkdir -p /var/lib/redis
    mkdir -p /var/log/redis
    useradd --system --home-dir /var/lib/redis redis
    chown redis.redis /var/lib/redis
    chown redis.redis /var/log/redis
    # Start redis-server during boot and stop during shutdown
    update-rc.d redis-server defaults
    cd ..

# Installing Ruby
    export RUBY_VERSION="ruby-1.9.3-p194"
    echo "Installing Ruby $RUBY_VERSION"
    echo "Downloading: (from calling wget http://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz)"
    wget http://ftp.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.gz
    echo "tar output:"
    tar xzf $RUBY_VERSION.tar.gz
    cd $RUBY_VERSION
    echo "current directory: `pwd`"
    echo "Ruby Configuration output: (from calling ./configure)"
    ./configure
    echo "Ruby make output: (from calling make)"
    make
    echo "Ruby make install output: (from calling make install)"
    make install
    cd ..
    echo "Ruby installed!"

# Set up Nginx and Passenger
    echo "Installing Nginx and Passenger"
    gem install passenger --no-ri --no-rdoc
    passenger-install-nginx-module --auto --auto-download --prefix="/usr/local/nginx"
    #set up nginx
    ln -s /usr/local/nginx/sbin/nginx /usr/local/sbin
    wget https://raw.github.com/simpx/scripts/master/nginx
    mv nginx /etc/init.d/nginx
    chmod +x /etc/init.d/nginx
    # Start nginx during boot and stop during shutdown
    update-rc.d -f nginx defaults

# Install git
    echo "Installing Git"
    apt-get -y install git-core

# Set up rails environment
    if [ ! -n "$RR_ENV" ]; then
        RR_ENV="production"
    fi
    cat >> /etc/environment << EOF
RAILS_ENV="$RR_ENV"
RACK_ENV="$RR_ENV"
EOF

# Installing Rails 3
    gem update --system
    # Install rails
    echo "Installing Rails3 and gems"
    gem install rails --no-ri --no-rdoc
    #Install sqlite
    apt-get -y install sqlite3 libsqlite3-dev
    gem install sqlite3 --no-ri --no-rdoc
    #Install mongo gem
    gem install mongoid bson_ext --no-ri --no-rdoc

# Install mongodb
    echo "Installing Mongodb"
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
    echo "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen" >> /etc/apt/sources.list
    apt-get update
    apt-get install mongodb-10gen

# Add deploy user
    echo "Add deploy user: $DEPLOY_USER"
    echo "$DEPLOY_USER:$DEPLOY_PSW:1000:1000::/home/$DEPLOY_USER:/bin/bash" | newusers
    cp -a /etc/skel/.[a-z]* /home/$DEPLOY_USER/
    chown -R $DEPLOY_USER /home/$DEPLOY_USER
    # Add to sudoers without password
    echo "$DEPLOY_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Finished
    echo "StackScript Finished!"