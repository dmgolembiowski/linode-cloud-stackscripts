# linode/u_stackscript.sh by vincentleungtheegg
# id: 37184
# description: NODE, PYTHON, 
# defined fields: name-db_root_password-default-upstory-label-mysqlmariadb-root-password-name-db_name-label-create-database-default-upstory-example-create-this-empty-database-name-new_user_name-label-work-user-name-default-work-example-user-name-cannot-be-empty-name-new_user_password-default-work-label-work-user-password-name-local_ip-label-local-ip-default-example-local-ip-cannot-be-empty
# images: ['linode/ubuntu14.04lts']
# stats: Used By: 5 + AllTime: 79
#!/usr/bin/env python

"""
LAMP StackScript

    Author: Ricardo N Feliciano <rfeliciano@linode.com>
    Version: 1.0.0.0
    Requirements:
        - ss://linode/python-library <ssinclude StackScriptID="3">
        - ss://linode/apache <ssinclude StackScriptID="5">
        - ss://linode/mysql <ssinclude StackScriptID="7">
        - ss://linode/php <ssinclude StackScriptID="8">

This StackScript both deploys and provides a library of functions for
creating a LAMP stack. The functions in this StackScript are designed to be
run across Linode's core distributions:
    - Ubuntu
    - CentOS
    - Debian
    - Fedora

StackScript User-Defined Variables (UDF):

<UDF name="db_root_password" default="upstory" label="MySQL/MariaDB root password" />
<UDF name="db_name" label="Create Database" default="upstory" example="create this empty database" />

<UDF name="new_user_name" label="work user name" default="work" example="User name cannot be empty" />
<UDF name="new_user_password" default="work" label="work user password" />

<UDF name="local_ip" label="local ip" default="" example="local ip cannot be empty" />


"""

import os
import sys
try: # we'll need to rename included StackScripts before we can import them
    os.rename("/root/ssinclude-3", "/root/pythonlib.py")
    os.rename("/root/ssinclude-7", "/root/mysql.py")
except:
    pass

import pythonlib
import mysql

__author__ = 'woo'

def main():

    """Install MYSQL MONGODB NGINX TOOL"""
    # add logging support

    pythonlib.init()
    # DB
    if os.environ['DB_ROOT_PASSWORD'] != "":
        db_root_password = os.environ['DB_ROOT_PASSWORD']
    else:
        db_root_password = False

    if os.environ['DB_NAME'] != "":
        db_name = os.environ['DB_NAME']
    else:
        db_name = False

    # USER WORK
    if os.environ['NEW_USER_PASSWORD'] != "":
        new_user_password = os.environ['NEW_USER_PASSWORD']
    else:
        new_user_password = False

    if os.environ['NEW_USER_NAME'] != "" and os.environ['NEW_USER_NAME'] != "root":
        new_user_name = os.environ['NEW_USER_NAME']
    else:
        new_user_name = False

    #LOCAL IP
    if os.environ['LOCAL_IP'] != "":
        local_ip = os.environ['LOCAL_IP']
    else:
        local_ip = False


    pythonlib.system_update()
    os.system('apt-get update')
    os.system('apt-get upgrade')
    os.system('apt-get install python-pexpect')

    mysql_install(db_root_password, db_name)
    other_install()
    java_install()
    mongo_install()
    redis_install()
    supervisor_install()


    create_user(new_user_name, new_user_password)
    mkdir_work(new_user_name)
    ip_config(local_ip)
    sys_config()
    pythonlib.end()
    os.system('reboot')


def other_install():

    os.system('apt-get install -y screen')
    os.system('apt-get install -y vim')
    os.system('apt-get install -y zip')
    os.system('apt-get install -y tar')
    os.system('apt-get install -y make')
    os.system('apt-get install -y build-essential')

def java_install():
    os.system('apt-get install -y software-properties-common')
    os.system('add-apt-repository -y ppa:webupd8team/java')
    os.system('apt-get update')
    os.system('echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections')
    os.system('apt-get -y install Oracle-java8-installer')

def mongo_install():

    #install mongo
    os.system("apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927")
    os.system('echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list')
    os.system("apt-get -y update")
    os.system("apt-get install -y mongodb-org")

def mysql_install(password, db_name):

    os.system('echo "mysql-community-server mysql-community-server/data-dir select ''"')
    os.system('echo "mysql-community-server mysql-community-server/root-pass password {}" | debconf-set-selections'.format(password))
    os.system('echo "mysql-community-server mysql-community-server/re-root-pass password {}" | debconf-set-selections'.format(password))

    os.system('apt-get install -y libaio1')
    os.system('groupadd mysql')
    os.system('useradd -r -g mysql mysql')


    os.chdir('/usr/local/src')
    os.system('wget  mysql-server_5.7.15-1ubuntu14.04_amd64.deb-bundle.tar http://cdn.mysql.com//Downloads/MySQL-5.7/mysql-server_5.7.15-1ubuntu14.04_amd64.deb-bundle.tar')

    os.system('tar -xvf mysql-server_5.7.15-1ubuntu14.04_amd64.deb-bundle.tar')
    os.system('dpkg -i mysql-common_5.7.15-1ubuntu14.04_amd64.deb')
    os.system('dpkg-preconfigure mysql-community-server_5.7.15-1ubuntu14.04_amd64.deb')

    os.system('dpkg -i mysql-client_5.7.15-1ubuntu14.04_amd64.deb')
    os.system('dpkg -i mysql-community-client_5.7.15-1ubuntu14.04_amd64.deb')
    os.system('apt-get install -y libmecab2')


    os.system('dpkg -i mysql-community-server_5.7.15-1ubuntu14.04_amd64.deb')
    os.system('dpkg -i libmysqlclient20_5.7.15-1ubuntu14.04_amd64.deb')


    os.chdir('/usr/local/')
    os.system('ln -s /var/lib/mysql  /usr/local/mysql')
    os.system('mkdir /usr/local/mysql/data')
    os.system('chown -R mysql. /usr/local/mysql/data')


def redis_install():
    os.system('wget http://download.redis.io/releases/redis-3.2.5.tar.gz')
    os.system('tar xzf redis-3.2.5.tar.gz')
    os.chdir('redis-3.2.5')
    os.system('make')
    os.system('make install')

def twemproxy_install():

    os.system('apt-get install -y autoconf automake')
    os.system('apt-get install -y libtool')
    os.system('wget https://github.com/twitter/twemproxy/archive/v0.4.0.tar.gz')
    os.system('tar -xvf v0.4.0.tar.gz')
    os.system('rm -r ./v0.4.0.tar.gz')
    os.chdir('twemproxy-0.4.0/')
    os.system('autoreconf -fvi')
    os.system('./configure && make')


def supervisor_install():

    os.system('apt-get -y install supervisor')


def create_user(username, password):

    os.system('echo [create user:{}]'.format(username))
    os.system('aptitude -y install sudo')
    os.system('adduser {} --disabled-password --gecos ""'.format(username))
    os.system('echo "{}:{}" | chpasswd'.format(username, password))

def mkdir_work(username):

    # upstory
    os.system('mkdir /home/{}/upstory'.format(username))
    os.system('mv /manage/ /home/{}/upstory'.format(username))
    print('[chown -R {}:{} /home/{}/upstory]'.format(username, username, username))
    os.system('chown -R {}:{} /home/{}/upstory'.format(username, username, username))

    # pub-tools
    # os.system('mkdir /home/{}/pub-tools'.format(username))
    # os.system('mv /pub-tools/ /home/{}/pub-tools'.format(username))
    # print('[chown -R {}:{} /home/{}/pub-tools]'.format(username, username, username))
    # os.system('chown -R {}:{} /home/{}/pub-tools'.format(username, username, username))

    # mysql
    os.system('mkdir /home/mysql')
    os.system('chown -R mysql:mysql /home/mysql')

    # mongodb
    os.system('mkdir /home/mongodb')
    os.system('chown -R mongodb:mongodb /home/mongodb')

def python_config():

    rf = open('/etc/python2.7/sitecustomize.py')
    lines = rf.readlines()
    rf.close()

    wf = open('/etc/python2.7/sitecustomize.py', 'w')
    for i in range(0, len(lines)):
        if i == 1:
            wf.write("import sys\nreload(sys)\nsys.setdefaultencoding('utf-8')\n")
        wf.write(lines[i])
    wf.close()

def ip_config(local_ip):
    if local_ip:
        os.system('echo "auto eth0:0" >> /etc/network/interfaces')
        os.system('echo "iface eth0:0 inet static" >> /etc/network/interfaces')
        os.system('echo "   address {}" >> /etc/network/interfaces'.format(local_ip))

def sys_config():
    os.system('echo "*  -   nofile     165536 # add this line" >>/etc/security/limits.conf')
    os.system('echo "vm.max_map_count=262144" >>/etc/sysctl.conf ')

if __name__ == "__main__":
    sys.exit(main())