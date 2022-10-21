# linode/8bitbase-lemp-latest.sh by lechidung
# id: 133836
# description: PHP7
Nginx Latest
MariaDB 10
# defined fields: name-db_root_password-label-mysqlmariadb-root-password-name-db_name-label-create-database-default-example-create-this-empty-database
# images: ['linode/centos7', 'linode/debian8', 'linode/debian9', 'linode/centos6.8', 'linode/debian7']
# stats: Used By: 2 + AllTime: 74
#!/usr/bin/env python

"""
LEMP StackScript
    
    Author: LE CHI DUNG <8bitbase.com>
    Version: 1.0.0.3
    Requirements:
        - ss://linode/python-library <ssinclude StackScriptID="3">
        - ss://linode/nginx <ssinclude StackScriptID="133859">
        - ss://linode/mysql <ssinclude StackScriptID="133877">
        - ss://linode/php <ssinclude StackScriptID="133846">

This StackScript both deploys and provides a library of functions for
creating a LAMP stack. The functions in this StackScript are designed to be 
run across Linode's core distributions:
    - Ubuntu
    - CentOS
    - Debian
    - Fedora

StackScript User-Defined Variables (UDF): 

<UDF name="db_root_password" label="MySQL/MariaDB root password" />
<UDF name="db_name" label="Create Database" default="" example="create this empty database" />
"""

import os
import sys

try: # we'll need to rename included StackScripts before we can import them
    os.rename("/root/ssinclude-3", "/root/pythonlib.py")
    os.rename("/root/ssinclude-133859", "/root/nginx.py")
    os.rename("/root/ssinclude-133877", "/root/mysql.py")
    os.rename("/root/ssinclude-133846", "/root/php.py")
except:
    pass

import pythonlib
import nginx
import mysql
import php


def main():
    """Install Nginx, MySQL/MariaDB, and PHP."""
    # add logging support
    pythonlib.init()
    
    if os.environ['DB_ROOT_PASSWORD'] != "":
        db_root_password = os.environ['DB_ROOT_PASSWORD']
    else:
        db_root_password = False
    
    if os.environ['DB_NAME'] != "":
        db_name = os.environ['DB_NAME']
    else:
        db_name = False

    pythonlib.system_update()
    nginx.nginx_install()
    mysql.mysql_install(db_root_password, db_name)
    php.php7_fpm_install()
    php.php7_install_module_common()

    pythonlib.end()


if __name__ == "__main__":
    sys.exit(main())