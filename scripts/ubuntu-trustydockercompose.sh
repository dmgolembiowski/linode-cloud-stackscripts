# linode/ubuntu-trustydockercompose.sh by referup
# id: 11543
# description: 
# defined fields: 
# images: ['linode/ubuntu14.04lts']
# stats: Used By: 1 + AllTime: 103
#!/bin/bash
source <ssinclude StackScriptID=1>

DEBIAN_FRONTEND=noninteractive

apt-get install -y apt-transport-https

apt-key adv --keyserver hkp://hkps.pool.sks-keyservers.net --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list

apt-key adv --keyserver hkp://hkps.pool.sks-keyservers.net --recv-keys 548C16BF
echo deb http://apt.newrelic.com/debian/ newrelic non-free > /etc/apt/sources.list.d/newrelic.list

apt-key adv --keyserver hkp://hkps.pool.sks-keyservers.net --recv-keys 7F0CEB10
echo deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen > /etc/apt/sources.list.d/mongodb.list 

apt-key adv --keyserver hkp://hkps.pool.sks-keyservers.net --recv-keys 3FE869A9
echo "deb http://ppa.launchpad.net/gluster/glusterfs-3.6/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/glusterfs.list

apt-key adv --keyserver hkp://hkps.pool.sks-keyservers.net --recv-keys 0xcbcb082a1bb943db
echo "deb http://mariadb.cu.be//repo/10.0/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/mariadb.list

system_update

if [[ ! -z ${NEWRELIC_LICENSE_KEY} ]]; then
  apt-get install -y newrelic-sysmond
  nrsysmond-config --set license_key=${NEWRELIC_LICENSE_KEY}
  service newrelic-sysmond restart
fi

apt-get install -y \
  python-pip \
  nano screen \
  bash-completion command-not-found \
  mlocate \
  htop iotop \
  ncdu mc

wget -O - http://get.docker.com | sh

pip install -U docker-compose