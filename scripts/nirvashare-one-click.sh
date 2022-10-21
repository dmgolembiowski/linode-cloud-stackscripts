# linode/nirvashare-one-click.sh by linode
# id: 869156
# description: NirvaShare One-Click
# defined fields: name-dbpassword-label-database-password
# images: ['linode/ubuntu20.04']
# stats: Used By: 6 + AllTime: 112
#!/bin/bash
#
# Script to install NirvaShare applications on Linode
# Installs docker, docker-compose, postgres db, nirvashare admin and user share app
#
#
# <UDF name="dbpassword" Label="Database Password" />

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

## Linode Docker OCA
source <ssinclude StackScriptID=607433>

# Configure service file
cat <<END > /etc/systemd/system/nirvashare.service
[Unit]
Description=Docker Compose NirvaShare Application Service
Requires=nirvashare.service
After=nirvashare.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
ExecReload=/usr/local/bin/docker-compose up -d
WorkingDirectory=/var/nirvashare/
[Install]
WantedBy=multi-user.target
END

# Get Docker Composer file
mkdir -p /var/nirvashare
cd /var/nirvashare
echo "version: '3'
services:
  admin:
    image: nirvato/nirvashare-admin:latest
    container_name: nirvashare_admin
    networks:
      - nirvashare
    restart: always
    ports:
#      # Public HTTP Port:
      - 8080:8080
    environment:
      ns_db_jdbc_url: 'jdbc:postgresql://nirvashare_database:5432/postgres'
      ns_db_username: 'nirvashare'
      ns_db_password: '$DBPASSWORD'
    volumes:
      - /var/nirvashare:/var/nirvashare     
    depends_on:
      - db
  userapp:
    image: nirvato/nirvashare-userapp:latest
    container_name: nirvashare_userapp
    networks:
      - nirvashare
    restart: always
    ports:
#      # Public HTTP Port:
      - 8081:8080
    environment:
      ns_db_jdbc_url: 'jdbc:postgresql://nirvashare_database:5432/postgres'
      ns_db_username: 'nirvashare'
      ns_db_password: '$DBPASSWORD'
    volumes:
      - /var/nirvashare:/var/nirvashare      
    depends_on:
      - admin
  db:
   image: postgres:13.2
   networks:
      - nirvashare
   container_name: nirvashare_database
   restart: always
#   ports:
#        - 5432:5432
   environment: 
     POSTGRES_PASSWORD: '$DBPASSWORD'
     POSTGRES_USER: 'nirvashare'
   volumes:
      - db_data:/var/lib/postgresql/data
volumes:
   db_data:
networks:
  nirvashare: {}
"  > /var/nirvashare/docker-compose.yml

# Enable Nirvashare daemon
systemctl daemon-reload
systemctl enable nirvashare.service
systemctl start nirvashare.service

# Clean up
stackscript_cleanup