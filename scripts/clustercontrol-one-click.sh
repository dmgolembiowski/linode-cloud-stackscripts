# linode/clustercontrol-one-click.sh by linode
# id: 869158
# description: ClusterControl One-Click
# defined fields: name-dbroot_password-label-mysql-root-password-name-cmonuser_password-label-cmon-user-password-name-token_password-label-your-linode-api-token-this-is-required-in-order-to-create-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-e-mail-address-example-your-email-address-name-ssl-label-would-you-like-to-use-a-free-lets-encrypt-ssl-certificate-uses-the-linodes-default-rdns-if-no-domain-is-specified-above-oneof-yesno-default-yes
# images: ['linode/ubuntu20.04']
# stats: Used By: 6 + AllTime: 97
#!/usr/bin/env bash

### UDF Variables

## Severalnines settings
#<UDF name="dbroot_password" Label="MySQL Root Password" />
#<UDF name="cmonuser_password" Label="CMON user password" />

## Domain settings
#<UDF name="token_password" label="Your Linode API token. This is required in order to create DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="E-Mail Address" example="Your email address">

## Let's Encrypt SSL
#<UDF name="ssl" label="Would you like to use a free Let's Encrypt SSL certificate? (Uses the Linode's default rDNS if no domain is specified above)" oneOf="Yes,No" default="Yes">

### Logging and other debugging helpers

# Enable logging for the StackScript
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source the Linode Bash StackScript, API, and LinuxGSM Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

# System Update
system_update

workdir=/tmp
IP=`hostname -I | awk '{print$1}'`
# if command -v dig &>/dev/null; then
#     echo -e "\nDetermining network interfaces." 
#     ext_ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
#     [[ ! -z $ext_ip ]] && IP=${ext_ip}
# fi
log_progress() {

    echo "$1" >> /root/cc_install.log
}

install_cc() {
    export HOME=/root
    export USER=root
    wget --no-check-certificate https://severalnines.com/downloads/cmon/install-cc
    chmod +x install-cc
    echo "mysql cmon password = $CMONUSER_PASSWORD" >> /root/.cc_passwords
    echo "mysql root password = $DBROOT_PASSWORD" >> /root/.cc_passwords
    SEND_DIAGNOSTICS=0 S9S_CMON_PASSWORD=$CMONUSER_PASSWORD S9S_ROOT_PASSWORD=$DBROOT_PASSWORD INNODB_BUFFER_POOL_SIZE=256 ./install-cc
}

firstboot() {
    hostnamectl set-hostname clustercontrol

    ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
    ssh-keygen -y -f /root/.ssh/id_rsa > /root/.ssh/id_rsa.pub
    SSH_KEY=$(cat /root/.ssh/id_rsa.pub)

    cat <<END > /etc/update-motd.d/99-cc-motd 
#!/bin/sh
echo "###"
echo ""
echo "Welcome to Severalnines Database Monitoring and Management Application - ClusterControl"
echo "Open your web browser to http://${IP}/clustercontrol to access ClusterControl's web application"
echo ""
echo "The public SSH key (root) is:"
echo "$SSH_KEY"
echo ""
echo "###"
END

    chmod +x /etc/update-motd.d/99-cc-motd
}

enable_fw() {
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 9999
    ufw allow 9501
}

cleanup() {
    rm -rf /tmp/* /var/tmp/* /root/scripts
    history -c
    cat /dev/null > /root/.bash_history
    unset HISTFILE

    apt-get -y autoremove
    apt-get -y autoclean

    cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp; cat /dev/null > /var/log/auth.log

    ufw enable
    ufw status

    touch /.cc-provisioned
}

log_progress "** Installing ClusterControl, this could take several minutes. Please wait ..."
install_cc
log_progress "** Setting motd ..."
firstboot
log_progress "** Enabling firewall ..."
enable_fw
if [[ "$SSL" == "Yes" ]]; then
    log_progress "** Enabling Let's Encrypt SSL ..."
    python --version | grep -q 3.
    [[ $? -eq 0 ]] && PYTHON3=1
    if [[ -n $PYTHON3 ]]; then
        apt install -y certbot python3-certbot-apache
    else
        apt install -y certbot python-certbot-apache
    fi

    certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'
fi
cleanup

# Clean up
log_progress "** Stackscript cleanup please wait ..."
stackscript_cleanup

log_progress "** Installation successful..."
/etc/update-motd.d/99-cc-motd | tee -a /root/cc_install.log

systemctl restart sshd