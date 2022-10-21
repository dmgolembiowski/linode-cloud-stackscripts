# linode/beef-one-click.sh by linode
# id: 913277
# description: BeEF One-Click
# defined fields: name-beefpassword-label-beef-password-name-soa_email_address-label-email-address-for-the-lets-encrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-the-username-cannot-contain-any-spaces-or-capitol-letters-for-this-application-the-username-beef-is-reserved-for-the-application-so-please-choose-an-alternative-username-for-this-deployment-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default
# images: ['linode/ubuntu20.04']
# stats: Used By: 2022 + AllTime: 19210
#!/bin/bash
#
# Script to install BEEF on Linode
# <UDF name="beefpassword" Label="BEEF Password" />
# <UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode. The username cannot contain any spaces or capitol letters. For this application the username 'beef' is reserved for the application, so please choose an alternative username for this deployment." default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">

## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>
## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>
## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>
## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

beef_config="/home/beef/config.yaml"
key="privkey.pem"
cert="fullchain.pem"

# System Update
apt_setup_update

# UFW
ufw allow 80
ufw allow 443
ufw allow 3000

function configure_nginx {
    apt install git nginx -y
    # NGINX
    mkdir -p /var/www/certs/.well-known
    chown -R www-data:www-data /var/www/certs/
    cat <<EOF > /etc/nginx/sites-available/$FQDN
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;
    root /var/www/certs;
    location / {
        try_files \$uri \$uri/ =404;
    }
# allow .well-known
    location ^~ /.well-known {
      allow all;
      auth_basic off;
      alias /var/www/certs/.well-known;
    }
}
EOF
    ln -s /etc/nginx/sites-available/$FQDN /etc/nginx/sites-enabled/$FQDN
    unlink /etc/nginx/sites-enabled/default
    systemctl restart nginx
}

function configure_ssl {
    apt install certbot python3-certbot-nginx -y
    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'nginx'
}

function create_beef_user {
    function create_beef {
        groupadd --system beef
        useradd -s /sbin/nologin --system -g beef beef
    }

    grep beef /etc/passwd
    if [ $? -eq 1 ];then
        create_beef
    else
        echo "[INFO] beef already on the system. Deleting user"
        deluser --remove-home beef
        create_beef
    fi
}

function configure_beef {
    git clone https://github.com/beefproject/beef.git /home/beef
    chown -R beef: /home/beef
    cd /home/beef
    cp /etc/letsencrypt/live/$FQDN/$key .
    cp /etc/letsencrypt/live/$FQDN/$cert .

    # get line number to replace
    get_https_enable=$(grep -n -C 10 "key:" $beef_config | grep -v "#" | grep "https:" -A 5 | grep "enable:" | awk -F "-" {'print $1'})
    get_https_public_enabled=$(grep -n -C 10 "key:" $beef_config | grep -v "#" | grep "https:" -A 5 | grep "public_enabled:" | awk -F "-" {'print $1'})

    # replacing line numebr
    sed -i ""$get_https_enable"s/enable: false/enable: true/" $beef_config
    sed -i ""$get_https_public_enabled"s/public_enabled: false/public_enabled: true/" $beef_config
    sed -i "/key:/c\            key:  \"$key\"" $beef_config
    sed -i "/cert:/c\            cert: \"$cert\"" $beef_config

    # creds
    #sed -i "/user:/c\        user:   \"beef\"" $beef_config
    sed -i "/passwd:/c\        passwd: \"$BEEFPASSWORD\"" $beef_config

    # install local copy of beef
    yes | ./install
}

function beef_startup {
    cat <<EOF > /home/beef/start_beef
#!/bin/bash
function start_beef {
    cd /home/beef
    echo no | ./beef
}
start_beef
EOF
    chown -R beef:beef /home/beef
    chmod +x /home/beef/start_beef
}
 
function beef_job {
    cat <<EOF  > /etc/systemd/system/beef.service
[Unit]
Description=Browser Exploitation Framework
Wants=network-online.target
After=network-online.target
[Service]
User=beef
Group=beef
ExecStart=/home/beef/start_beef
[Install]
WantedBy=default.target
EOF
    systemctl daemon-reload
    systemctl start beef
    systemctl enable beef
}

function ssl_renew_cron {
    cat <<END >/root/certbot-beef-renewal.sh
#!/bin/bash
#
# Script to handle Certbot renewal & BeEf
# Debug
# set -xo pipefail
export BEEF_FULL=/home/beef/fullchain.pem
export BEEF_PRIVKEY=/home/beef/privkey.pem
export FULLCHAIN=/etc/letsencrypt/live/$FQDN/fullchain.pem
export PRIVKEY=/etc/letsencrypt/live/$FQDN/privkey.pem
certbot renew
cat \$FULLCHAIN > \$BEEF_FULL
cat \$PRIVKEY > \$BEEF_PRIVKEY
service beef reload
END
    chmod +x /root/certbot-beef-renewal.sh

# Setup Cron
    crontab -l > cron
    echo "* 1 * * 1 bash /root/certbot-beef-renewal.sh" >> cron
    crontab cron
    rm cron

}

function install_complete {
    cat <<EOF > /root/beef.info
##############################
# BEEF INSTALLATION COMPLETE #
##############################
Endpoint: https://$FQDN:3000/ui/panel
Credentials can be found here:
/home/beef/config.yaml
Happy hunting!
EOF
}

function main {
    create_beef_user
    configure_nginx
    configure_ssl
    configure_beef
    beef_startup
    beef_job
    ssl_renew_cron
    install_complete
}
main

# Clean up
stackscript_cleanup
cat /root/beef.info