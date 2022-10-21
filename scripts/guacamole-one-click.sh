# linode/guacamole-one-click.sh by linode
# id: 688914
# description: Guacamole One-Click
# defined fields: name-username-label-the-limited-sudovnc-user-to-be-created-for-the-linode-name-password-label-the-password-for-the-limited-sudovnc-user-name-guacamole_user-label-the-username-to-be-used-with-guacamole-name-guacamole_password-label-the-password-to-be-used-with-guacamole-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-required-if-filling-out-any-of-the-domain-related-fields-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-default-name-domain-label-the-domain-for-the-linodes-dns-record-default-name-soa_email_address-label-admin-email-for-the-server-default-name-mx-label-do-you-need-an-mx-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-spf-label-do-you-need-an-spf-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 67 + AllTime: 2915
#!/usr/bin/env bash

### Apache Guacamole OCA
### Required UDFs

## Guacamole Settings
#<UDF name="username" label="The limited sudo/VNC user to be created for the Linode">
#<UDF name="password" label="The password for the limited sudo/VNC user">
#<UDF name="guacamole_user" label="The username to be used with Guacamole">
#<UDF name="guacamole_password" label="The password to be used with Guacamole">

### Optional UDFs

## Linode/SSH Security Settings
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required if filling out any of the domain-related fields." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">

## Logging and other debugging helpers
# Put bash into verbose mode
# set -o pipefail

# Enable logging for the StackScript
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

## Imports

# Source the Bash StackScript Library and the API functions for DNS
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

### Main Script

## Open the needed firewall ports
ufw allow http
ufw allow https

## Install Apache Guacamole Server

# Install dependencies
system_install_package build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev \
                       libtool-bin libossp-uuid-dev libvncserver-dev freerdp2-dev libssh2-1-dev \
                       libtelnet-dev libwebsockets-dev libpulse-dev libvorbis-dev libwebp-dev \
                       libssl-dev libpango1.0-dev libswscale-dev libavcodec-dev libavutil-dev \
                       libavformat-dev

# Download the Guacamole Server source code
wget https://downloads.apache.org/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz
tar -xvf guacamole-server-1.3.0.tar.gz
cd guacamole-server-1.3.0

# Build Guacamole Server using the downloaded source code
./configure --with-init-dir=/etc/init.d --enable-allow-freerdp-snapshots
make
make install

# Update installed library cache and reload systemd
ldconfig
systemctl daemon-reload

# Start guacd
systemctl enable guacd

## Install Guacamole Web App

# Install Apache Tomcat
system_install_package tomcat9 tomcat9-admin tomcat9-common tomcat9-user

# Download and install the Guacamole Client
wget https://downloads.apache.org/guacamole/1.3.0/binary/guacamole-1.3.0.war
mv guacamole-1.3.0.war /var/lib/tomcat9/webapps/guacamole.war
systemctl restart tomcat9 guacd

## Guacamole configs
mkdir /etc/guacamole
readonly ENCRYPTED_GUACAMOLE_PASSWORD="$(echo -n "$GUACAMOLE_PASSWORD" | openssl md5 | awk '{print $2}')"
cat <<EOF >> /etc/guacamole/user-mapping.xml
<user-mapping>
    <!-- Per-user authentication and config information -->
    <authorize
         username="$GUACAMOLE_USER"
         password="$ENCRYPTED_GUACAMOLE_PASSWORD"
         encoding="md5">
      
       <connection name="default">
         <protocol>vnc</protocol>
         <param name="hostname">localhost</param>
         <param name="port">5901</param>
         <param name="password">${PASSWORD}</param>
       </connection>
    </authorize>
</user-mapping>
EOF
systemctl restart tomcat9 guacd

## Install a desktop environment (XFCE) and VNC Server

# Install XFCE
system_install_package xfce4 xfce4-goodies

# Install VNC Server
system_install_package tigervnc-standalone-server expect

# Set the VNC Server password
readonly VNCSERVER_SET_PASSWORD=$(expect -c "
spawn sudo -u $USERNAME vncserver
expect \"Password:\"
send \"$PASSWORD\r\"
expect \"Verify:\"
send \"$PASSWORD\r\"
expect \"Would you like to enter a view-only password (y/n)?\"
send \"n\r\"
expect eof
")
echo "$VNCSERVER_SET_PASSWORD"
systemctl restart tomcat9 guacd
vncserver -kill :1

# Create a systemd service for Tiger VNC
touch /etc/systemd/system/vncserver@.service
cat <<EOF > /etc/systemd/system/vncserver@.service
[Unit]
Description=a wrapper to launch an X server for VNC
After=syslog.target network.target
[Service]
Type=forking
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 -localhost :%i
ExecStop=/usr/bin/vncserver -kill :%i
[Install]
WantedBy=multi-user.target
EOF

# Start and enable the systemd service
systemctl start vncserver@1.service
systemctl enable vncserver@1.service

## Reverse proxy for the Guacamole client

# Install Apache
apache_install
a2enmod proxy proxy_http headers proxy_wstunnel

# Create the VirtualHost for Guacamole
cat <<EOF > /etc/apache2/sites-available/guacamole.conf
<VirtualHost *:80>
      ServerName $FQDN
      ErrorLog ${APACHE_LOG_DIR}/guacamole_error.log
      CustomLog ${APACHE_LOG_DIR}/guacamole_access.log combined
      <Location />
          Require all granted
          ProxyPass http://localhost:8080/guacamole/ flushpackets=on
          ProxyPassReverse http://localhost:8080/guacamole/
      </Location>
     <Location /websocket-tunnel>
         Require all granted
         ProxyPass ws://localhost:8080/guacamole/websocket-tunnel
         ProxyPassReverse ws://localhost:8080/guacamole/websocket-tunnel
     </Location>
     Header always unset X-Frame-Options
</VirtualHost>
EOF

# Enable the VirtualHost
a2ensite guacamole.conf
systemctl restart apache2

## HTTPS
system_install_package python3-certbot-apache
    certbot -n --apache --agree-tos --redirect --hsts --staple-ocsp \
    --email "$SOA_EMAIL_ADDRESS" -d "$FQDN" 

## Cleanup after ourselves
stackscript_cleanup