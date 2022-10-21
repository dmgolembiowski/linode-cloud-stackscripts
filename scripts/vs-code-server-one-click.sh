# linode/vs-code-server-one-click.sh by linode
# id: 688903
# description: Visual Studio Code One-Click
# defined fields: name-vs_code_password-label-the-password-to-login-to-the-vs-code-web-ui-name-vs_code_ver-label-the-version-of-vs-code-server-youd-like-installed-default-3102-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-recommended-default-name-disable_root-label-would-you-like-to-disable-root-login-over-ssh-recommended-oneof-yesno-default-yes-name-token_password-label-your-linode-api-token-this-is-required-for-creating-dns-records-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-and-domain-default-name-soa_email_address-label-your-email-address-for-your-virtualhost-configuration-dns-records-if-required-and-ssl-certificates-if-required-name-ssl-label-would-you-like-to-use-a-free-lets-encrypt-ssl-certificate-uses-the-linodes-default-rdns-if-no-domain-is-specified-above-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 88 + AllTime: 2786
#!/usr/bin/env bash

## VS Code Server OCA Script

### UDF Variables

## VS Code Web Password
#<UDF name="vs_code_password" label="The password to login to the VS Code Web UI">
#<UDF name="vs_code_ver" label="The version of VS Code Server you'd like installed" default="3.10.2">

## User and SSH Security
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode (Recommended)" default="">
#<UDF name="disable_root" label="Would you like to disable root login over SSH? (Recommended)" oneOf="Yes,No" default="Yes">

## Domain
#<UDF name="token_password" label="Your Linode API token - This is required for creating DNS records" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token and domain)" default="">
#<UDF name="soa_email_address" label="Your email address for your VirtualHost configuration, DNS records (If Required), and SSL certificates (If Required).">

## Let's Encrypt SSL
#<UDF name="ssl" label="Would you like to use a free Let's Encrypt SSL certificate? (Uses the Linode's default rDNS if no domain is specified above" oneOf="Yes,No" default="No">


### Logging and other debugging helpers

# Enable logging for the StackScript
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Bash StackScript Library and the API functions for DNS
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>


function get_code_server {
    local -r username="$1" vs_code_ver="$2"

    cd "/home/$username"

    wget "https://github.com/cdr/code-server/releases/download/v${vs_code_ver}/code-server-${vs_code_ver}-linux-amd64.tar.gz"
    tar -xf "code-server-${vs_code_ver}-linux-amd64.tar.gz"
    mv code-server-*/ bin/

    chown -R "${username}:${username}" bin/
    chmod +x bin/code-server
    mkdir data/
    chown -R "${username}:${username}" data/

    cd /root/
}

function enable_code_service {
    local -r vs_code_password="$1" username="$2"

    # Set the password in /etc/systemd/system/code-server.service
    cat << EOF > /etc/systemd/system/code-server.service
[Unit]
Description=code-server
After=nginx.service
[Service]
User=$username
WorkingDirectory=/home/$username
Environment=PASSWORD=$vs_code_password
ExecStart=/home/${username}/bin/code-server --host 127.0.0.1 --user-data-dir /home/${username}/data --auth password
Restart=always
[Install]
WantedBy=multi-user.target
EOF

    # Enable code-server as a service
    systemctl daemon-reload
    systemctl start code-server
    systemctl enable code-server
}

function certbot_standalone {
    local -r email_address="$1" ssl_domain="$2"

    # Get an SSL certificate from CertBot
    system_install_package "certbot"
    certbot -n certonly --standalone --agree-tos -m "$email_address" -d "$ssl_domain"
}

function nginx_reverse_proxy {
    local -r ssl_domain="$1"

    ## Setup a reverse proxy with Nginx
    system_install_package "nginx"

    cat << EOF > /etc/nginx/sites-available/code-server
server {
    listen 80;
    server_name $ssl_domain;
    # enforce https
    return 301 https://\$server_name:443\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $ssl_domain;
    ssl_certificate /etc/letsencrypt/live/${ssl_domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${ssl_domain}/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host \$host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
    }
}
EOF

    ln -s /etc/nginx/sites-available/code-server /etc/nginx/sites-enabled
    nginx -t
    systemctl restart nginx
}

### Install UFW and open the needed firewall ports
ufw allow 80,443/tcp

### Install and configure VS Code Server
get_code_server "$USERNAME" "$VS_CODE_VER"
enable_code_service "$VS_CODE_PASSWORD" "$USERNAME"
check_dns_propagation "$FQDN" "$IP"
certbot_standalone "$SOA_EMAIL_ADDRESS" "$FQDN"
nginx_reverse_proxy "$FQDN"

### Clean up
stackscript_cleanup