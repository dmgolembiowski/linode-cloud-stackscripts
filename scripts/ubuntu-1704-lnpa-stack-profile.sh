# linode/ubuntu-1704-lnpa-stack-profile.sh by lucretia
# id: 61492
# description: Sets up a LNPA (Linux, nginx, PostgreSQL, Ada) server on Ubuntu 16.10, updates the system and installs:

1) Add an "admin" user for doing all admin login's using ssh before "su -"
2) Email using Postfix, Dovecot and PostgreSQL.
3) SSL certificates using Let's Encrypt.
4) GIT
5) GNAT Ada compiler.

# defined fields: name-sys_debug-default-on-oneof-onoff-label-enable-debug-logging-name-sys_add_dns-default-yes-oneof-yesno-label-automatically-add-dns-entries-name-sys_admin_user_name-default-admin-label-the-username-for-the-administrator-user-this-user-will-be-doing-all-admin-work-via-sudo-or-su-dont-really-use-admin-though-use-something-better-and-more-obscure-name-sys_admin_user_password-label-the-password-for-the-admin-linux-user-name-sys_hostname-example-somehostname-label-the-hostname-for-the-new-linode-name-sys_fqdn-example-somedomaincom-label-the-new-linodes-fully-qualified-domain-name-name-sys_alias_fqdn-default-example-somedomaincouk-label-alias-for-this-linodes-other-fully-qualified-domain-name-name-sys_admin_user_email_password_fqdn-label-password-for-adminsomehostnamesomedomaincom-email-user-name-sys_fqdn_1-default-example-otherdomain1com-label-this-linodes-other-fully-qualified-domain-name-name-sys_alias_fqdn_1-default-example-otherdomain1couk-label-alias-for-this-linodes-other-fully-qualified-domain-name-name-sys_admin_user_email_password_fqdn_1-default-label-password-for-adminsomehostnameotherdomain1com-email-user-name-sys_fqdn_2-default-example-otherdomain2com-label-this-linodes-other-fully-qualified-domain-name-name-sys_alias_fqdn_2-default-example-otherdomain2net-label-alias-for-this-linodes-other-fully-qualified-domain-name-name-sys_admin_user_email_password_fqdn_2-default-label-password-for-adminsomehostnameotherdomain2com-email-user-name-sys_fqdn_3-default-example-otherdomain3com-label-this-linodes-other-fully-qualified-domain-name-name-sys_alias_fqdn_3-default-example-otherdomain3org-label-alias-for-this-linodes-other-fully-qualified-domain-name-name-sys_admin_user_email_password_fqdn_3-default-label-password-for-adminsomehostnameotherdomain3com-email-user-name-sys_fqdn_4-default-example-otherdomain4com-label-this-linodes-other-fully-qualified-domain-name-name-sys_alias_fqdn_4-default-example-otherdomain4couk-label-alias-for-this-linodes-other-fully-qualified-domain-name-name-sys_admin_user_email_password_fqdn_4-default-label-password-for-adminsomehostnameotherdomain4com-email-user-name-sys_admin_user_sshkey-label-ssh-key-so-you-can-login-as-the-admin-user-name-sys_ssh_port-label-re-assign-ssh-to-listen-on-this-port-number-name-sys_enable_letsencrypt-default-off-oneof-onoff-label-enable-letsencrypt-ssl-certificates-name-sys_postgres_user_password-label-the-password-for-the-postgres-linux-user-name-sys_postgres_db_user_password-label-the-password-for-the-postgres-postgresql-user-name-sys_email_db_server_name-default-mailserver-label-the-name-for-the-postgresql-mail-server-database-name-sys_email_db_user_name-default-mailuser-label-the-username-who-can-administer-the-postgresql-mailserver-database-name-sys_email_db_user_password-label-the-password-for-the-postgresql-mailuser-to-enable-access-to-the-mailserver-database-name-sys_api_key-example-my-key-label-your-api-key-for-you-linode-account-name-sys_clamav_db_country-example-uk-default-uk-label-your-country-code-for-the-clamav-database-name-sys_enable_nginx-default-no-oneof-yesno-label-automatically-install-nginx
# images: ['linode/ubuntu17.04']
# stats: Used By: 0 + AllTime: 93
#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
# Basic system.
#
#<UDF name="SYS_DEBUG" default="on" oneof="on,off" label="Enable debug logging?" />
#
#<UDF name="SYS_ADD_DNS" default="yes" oneof="yes,no" label="Automatically add DNS entries?" />
#
#<UDF name="SYS_ADMIN_USER_NAME" default="admin" label="The username for the Administrator user. This user will be doing all admin work via sudo or su. Don't really use 'admin' though, use something better and more obscure!" />
#
#<UDF name="SYS_ADMIN_USER_PASSWORD" label="The password for the 'admin' Linux user." />
#
#<UDF name="SYS_HOSTNAME" example="somehostname" label="The hostname for the new Linode." />
#
#<UDF name="SYS_FQDN" example="somedomain.com" label="The new Linode's Fully Qualified Domain Name" />
#
#<UDF name="SYS_ALIAS_FQDN" default="" example="somedomain.co.uk" label="Alias for this Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN" label="Password for 'admin@somehostname.somedomain.com' email user." />
#
#<UDF name="SYS_FQDN_1" default="" example="otherdomain1.com" label="This Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ALIAS_FQDN_1" default="" example="otherdomain1.co.uk" label="Alias for this Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN_1" default="" label="Password for 'admin@somehostname.otherdomain1.com' email user." />
#
#<UDF name="SYS_FQDN_2" default="" example="otherdomain2.com" label="This Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ALIAS_FQDN_2" default="" example="otherdomain2.net" label="Alias for this Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN_2" default="" label="Password for 'admin@somehostname.otherdomain2.com' email user." />
#
#<UDF name="SYS_FQDN_3" default="" example="otherdomain3.com" label="This Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ALIAS_FQDN_3" default="" example="otherdomain3.org" label="Alias for this Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN_3" default="" label="Password for 'admin@somehostname.otherdomain3.com' email user." />
#
#<UDF name="SYS_FQDN_4" default="" example="otherdomain4.com" label="This Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ALIAS_FQDN_4" default="" example="otherdomain4.co.uk" label="Alias for this Linode's other Fully Qualified Domain Name" />
#
#<UDF name="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN_4" default="" label="Password for 'admin@somehostname.otherdomain4.com' email user." />
#
#<UDF name="SYS_ADMIN_USER_SSHKEY" label="SSH key so you can login as the 'admin' user." />
#
#<UDF name="SYS_SSH_PORT" label="Re-assign ssh to listen on this port number." />
#
# SSL
#
#<UDF name="SYS_ENABLE_LETSENCRYPT" default="off" oneof="on,off" label="Enable LetsEncrypt SSL certificates?" />
#
# PostgreSQL.
#
#<UDF name="SYS_POSTGRES_USER_PASSWORD" label="The password for the 'postgres' Linux user." />
#
#<UDF name="SYS_POSTGRES_DB_USER_PASSWORD" label="The password for the 'postgres' PostgreSQL user." />
#
# Email database.
#
#<UDF name="SYS_EMAIL_DB_SERVER_NAME" default="mailserver" label="The name for the PostgreSQL mail server database." />
#
#<UDF name="SYS_EMAIL_DB_USER_NAME" default="mailuser" label="The username who can administer the PostgreSQL 'mailserver' database." />
#
#<UDF name="SYS_EMAIL_DB_USER_PASSWORD" label="The password for the PostgreSQL 'mailuser' to enable access to the 'mailserver' database." />
#
# API Key
#
#<UDF name="SYS_API_KEY" example="my key" label="Your API key for you Linode account" />
#
# ClamAV database country code
#
#<UDF name="SYS_CLAMAV_DB_COUNTRY" example="uk" default="uk" label="Your country code for the ClamAV database" />
#
# NGINX
#
#<UDF name="SYS_ENABLE_NGINX" default="no" oneof="yes,no" label="Automatically install NGINX?" />

LOG=/var/log/stackscript
SYS_TOTAL_FQDNS=4
DKIM_DATE=`date +%Y%m`
DKIM_DATE_NEXT_MONTH=`date +%Y%m --date='+1 month'`

export LINODE_API_KEY=$SYS_API_KEY

# This won't source other scripts for some reason.

if [ "$SYS_DEBUG" == "on" ]; then
    echo -e '#!/bin/sh\n\n' > /root/remove-all-dns-entries.sh
fi

################################################################
# Modified version of https://www.linode.com/stackscripts/view/1
################################################################

function system_update {
    echo "[system_update]" >> $LOG

    apt-get update
    apt-get -y install aptitude cronic
    aptitude -y full-upgrade
}

function system_primary_ip {
    # returns the primary IP assigned to eth0
    if [ ! -e /sbin/ifconfig ]; then
        aptitude -y install net-tools > /dev/null
    fi

    echo $(ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
}

function system_primary_ip6 {
    # returns the primary IP assigned to eth0
    if [ ! -e /sbin/ifconfig ]; then
        aptitude -y install net-tools > /dev/null
    fi

    echo $(ifconfig eth0 | grep global | awk '/inet6 / { print $2 }' | sed 's/addr://')
}

function get_rdns {
    # calls host on an IP address and returns its reverse dns

    if [ ! -e /usr/bin/host ]; then
        aptitude -y install dnsutils > /dev/null
    fi
    echo $(host $1 | awk '/pointer/ {print $5}' | sed 's/\.$//')
}

function get_rdns_primary_ip {
    # returns the reverse dns of the primary IP assigned to this system
    echo $(get_rdns $(system_primary_ip))
}

function system_set_hostname {
    # $1 - The hostname to define
    HOSTNAME="$1"

    echo "[system_set_hostname $HOSTNAME]" >> $LOG

    if [ ! -n "$HOSTNAME" ]; then
        echo "Hostname undefined"
        return 1;
    fi

    echo "$HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
}

function system_add_host_entry {
    echo "  [system_add_host_entry]" >> $LOG

    # $1 - The Domain name to set to the IP
    # $2 - The FQDN to set to the IP
    IPADDR=$(system_primary_ip)
    IPADDR6=$(system_primary_ip6)
    DOMAIN="$1"
    FQDN="$2"

    # echo "IPADDR - $IPADDR" >> $LOG
    # echo "FQDN   - $FQDN" >> $LOG

    if [ -z "$IPADDR" -o -z "$FQDN" ]; then
        echo "IP address and/or FQDN Undefined" >> $LOG
        return 1;
    fi

    echo "  [system_add_host_entry] $DOMAIN.$FQDN" >> $LOG

    ##########################################################
    # IPv4

    # echo "$IPADDR $DOMAIN.$FQDN $DOMAIN"  >> /etc/hosts

    # Add the IPv4 address just after the localhost line.
    sed -i '/127.0.0.1/ a'"$IPADDR"'\t'"$DOMAIN"'.'"$FQDN"'\t'"$DOMAIN" /etc/hosts

    ##########################################################
    # IPv6

    # Insert the correct 127.0.1.1 loopback address back this domain just before the IPv6 stuff.
    #sed -i '/127.0.1.1/ i'"$DOMAIN"'.'"$FQDN"' '"$DOMAIN"'/' /etc/hosts
    sed -i '/^# The following/ i127.0.1.1\t'"$DOMAIN"'.'"$FQDN"'\t'"$DOMAIN" /etc/hosts

    # Append the IPv6 address to the end of the file.
    if [ ! -z "$IPADDR6" ]; then
	echo -e "$IPADDR6\t$DOMAIN.$FQDN\t$DOMAIN" >> /etc/hosts
    fi
}

function system_set_host_info {
    echo "[system_set_host_info]" >> $LOG

    # Add extra domains.
    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	if [ ! -z ${!FQDN} ]; then
	    echo "  [system_set_host_info] Setting extra domain: $SYS_HOSTNAME - ${!FQDN}" >> $LOG

	    system_add_host_entry "$SYS_HOSTNAME" "${!FQDN}"
	fi

	if [ ! -z ${!ALIAS_FQDN} ]; then
	    echo "  [system_set_host_info] Setting extra domain: $SYS_HOSTNAME - ${!ALIAS_FQDN}" >> $LOG

	    system_add_host_entry "$SYS_HOSTNAME" "${!ALIAS_FQDN}"
	fi
    done

    echo "  [system_set_host_info] Setting domain: $SYS_HOSTNAME - $SYS_FQDN" >> $LOG

    # Add first alias domain.
    if [ ! -z $SYS_ALIAS_FQDN ]; then
	echo "  [system_set_host_info] Setting extra domain: $SYS_HOSTNAME - $SYS_ALIAS_FQDN" >> $LOG

	system_add_host_entry "$SYS_HOSTNAME" "$SYS_ALIAS_FQDN"
    fi

    # Set ip4/6 hosts entries.
    # This is set last so it goes to the top of the list and `hostname -f` returns this.
    system_add_host_entry "$SYS_HOSTNAME" "$SYS_FQDN"

    sed -i '/ubuntu.members.linode.com\tubuntu/d' /etc/hosts
}

function system_set_timezone {
    echo "[system_set_timezone]" >> $LOG

    # Overwrites an existing entry.
    timedatectl set-timezone 'Europe/London'
}

function system_rsyslog {
    echo "[system_rsyslog]" >> $LOG

    # Set compression on.
    sed -i 's/#compress/compress/' /etc/logrotate.conf

    # Make sure mail messages don't go to syslog as well.
    sed -i 's/*.*;auth,authpriv.none.*-\/var\/log\/syslog/*.*;mail.none;mail.error;auth,authpriv.none             -\/var\/log\/syslog/' /etc/rsyslog.d/50-default.conf

    # NB: Without the next 2 lines, we don't get a /var/log/mail.log created by Postfix.
    chown syslog:adm /var/log
    chmod 0775 /var/log

    service rsyslog restart
}


function system_set_linode_key {
    echo "export LINODE_API_KEY=$SYS_API_KEY" >> /etc/profile.d/linode_api_key.sh
}


###########################################################
# Users and Authentication
###########################################################

function user_add_sudo {
    # Installs sudo if needed and creates a user in the sudo group.
    #
    # $1 - Required - username
    # $2 - Required - password
    USERNAME="$1"
    USERPASS="$2"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        echo "No new username and/or password entered" >> $LOG
        return 1;
    fi

    aptitude -y install sudo
    adduser $USERNAME --disabled-password --gecos ""
    echo "$USERNAME:$USERPASS" | chpasswd
    usermod -aG sudo $USERNAME
}

function user_add_pubkey {
    # Adds the users public key to authorized_keys for the specified user. Make sure you wrap your input variables in double quotes, or the key may not load properly.
    #
    #
    # $1 - Required - username
    # $2 - Required - public key
    USERNAME="$1"
    USERPUBKEY="$2"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPUBKEY" ]; then
        echo "Must provide a username and the location of a pubkey" >> $LOG
        return 1;
    fi

    if [ "$USERNAME" == "root" ]; then
        mkdir /root/.ssh
        echo "$USERPUBKEY" >> /root/.ssh/authorized_keys
        return 1;
    fi

    mkdir -p /home/$USERNAME/.ssh
    echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys
    chown -R "$USERNAME":"$USERNAME" /home/$USERNAME/.ssh
}

function ssh_disable_root {
    # Disables root SSH access.
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    touch /tmp/restart-ssh
}

###########################################################
# Postfix
###########################################################

function postfix_install_loopback_only {
    echo "[postfix_install_loopback_only]" >> $LOG
    # Installs postfix and configure to listen only on the local interface. Also
    # allows for local mail delivery

    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string localhost" | debconf-set-selections
    echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
    aptitude -y install postfix
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"
    #/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"

    touch /tmp/restart-postfix
}

#########################################################
# Taken from https://www.linode.com/stackscripts/view/123
#########################################################

function lower {
    # helper function
    echo $1 | tr '[:upper:]' '[:lower:]'
}

function system_sshd_edit_bool {
    # system_sshd_edit_bool (param_name, "Yes"|"No")
    VALUE=`lower $2`
    if [ "$VALUE" == "yes" ] || [ "$VALUE" == "no" ]; then
        sed -i "s/^#*\($1\).*/\1 $VALUE/" /etc/ssh/sshd_config
    fi
}

function system_sshd_permitrootlogin {
    system_sshd_edit_bool "PermitRootLogin" "$1"
}

function system_sshd_passwordauthentication {
    system_sshd_edit_bool "PasswordAuthentication" "$1"
}

# Force SSH login's only.
function system_sshd_lockdown {
    echo "[sshd lockdown]" >> $LOG

    system_sshd_permitrootlogin "no"
    system_sshd_passwordauthentication "no"

    # Re-assign the SSH port
    sed -i 's/#Port 22/Port '"$SYS_SSH_PORT"'/' /etc/ssh/sshd_config

    echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config

    systemctl restart sshd
}

# TODO: Need a way of detecting persistent abusers, mail their abuse@ip with log, then ban them permanently.
# TODO: Check if detecting SMTP port!
function system_security_fail2ban {
    echo "  [system_security_fail2ban]" >> $LOG

    aptitude -y install fail2ban

    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

    cat <<EOF > /etc/fail2ban/jail.d/sshd.conf
[sshd]
enabled = true
port    = $SYS_SSH_PORT
filter  = sshd
logpath = %(sshd_log)s
backend = %(sshd_backend)s
#maxretry = 5
#bantime = 600
banaction = iptables-allports
EOF

    service fail2ban restart
}

function system_security_ufw_configure_basic {
    echo "  [system_security_ufw_configure_basic]" >> $LOG

    # see https://help.ubuntu.com/community/UFW
    ufw logging on

    ufw default deny

    #ufw deny ssh

    ufw allow $SYS_SSH_PORT/tcp
    ufw limit $SYS_SSH_PORT/tcp

    ufw allow http/tcp
    ufw allow https/tcp

    # Configure firewall rules to allow IMAPS, POP3S, SMTP(S)
    ufw allow imaps/tcp
    ufw allow pop3s/tcp
    ufw allow smtps/tcp

    ufw deny imap/tcp
    ufw deny pop-3/tcp

    #ufw deny out smtp/tcp

    # Otherwise nobody can send me email!
    ufw allow smtp/tcp

    ufw enable
}

################
# My stuff here.
################

# SSL certificates.
function system_lets_encrypt {
    if [ "$SYS_ENABLE_LETSENCRYPT" == "yes" ]; then
	echo "[system_lets_encrypt]" >> $LOG

	system_git
	system_letsencrypt
    fi
}

function system_linode_cli {
    echo "[system_linode_cli]" >> $LOG

    sudo bash -c 'echo "deb http://apt.linode.com/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/linode.list'

    # bash -c 'echo "deb http://apt.linode.com/ stable main" > /etc/apt/sources.list.d/linode.list'
    wget -O- https://apt.linode.com/linode.gpg | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y install linode-cli
    echo "  [system_linode_cli] Remember to call linode configure to set defaults" >> $LOG
}

function system_git {
    aptitude -y install git
}

function system_letsencrypt_get_domains {
    DOMAINS="-d $SYS_FQDN -d www.$SYS_FQDN"

    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"

	if [ ! -z ${!FQDN} ]; then
	    DOMAINS="$DOMAINS -d ${!FQDN} -d www.${!FQDN}"
	fi
    done

    echo $DOMAINS
}

function system_letsencrypt {
    git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

    cd /opt/letsencrypt

    DOMAINS=`system_letsencrypt_get_domains`

    ./letsencrypt-auto certonly --standalone $DOMAINS -m "$SYS_ADMIN_USER_NAME@$SYS_FQDN" -n --agree-tos >> $LOG 2>&1

    # Renew the SSL certs monthly.
    echo '@monthly root /opt/letsencrypt/letsencrypt-auto certonly --quiet --standalone --renew-by-default $DOMAINS >> /var/log/letsencrypt/letsencrypt-auto-update.log' | sudo tee --append /etc/crontab

    # Update the Git repo weekly.
    echo '@weekly root cd /opt/letsencrypt && git pull >> /var/log/letsencrypt/letsencrypt-auto-update.log' | sudo tee --append /etc/crontab
}

# $1 - FQDN
function system_spf_add_dns {
    echo "  [system_spf_add_dns] Adding SPF DNS records for $1" >> $LOG

    linode domain record-create "$1" TXT "" "v=spf1 a:mail.$1 -all" --ttl 300 >> $LOG

    if [ "$SYS_DEBUG" == "on" ]; then
	echo "linode domain record-delete \"$1\" TXT \"\"" >> /root/remove-all-dns-entries.sh
    fi
}

function system_mail_install_packages {
    echo "[system_mail_install_packages]" >> $LOG

    echo "  [system_mail_install_packages] Postgres, Postfix, Dovecot, OpenDKIM" >> $LOG

    aptitude -y install postgresql postfix-pgsql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-pgsql
    aptitude -y install opendkim opendkim-tools postfix-policyd-spf-python

    export PSQL_VERSION=`psql -V | awk  {'print $3'}| awk -F \. {'print $1"."$2'}`

    cp /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf.orig

    usermod -aG opendkim postfix

    # Add SPF TXT DNS records.
    if [ "$SYS_ADD_DNS" == "yes" ]; then
	system_spf_add_dns $SYS_FQDN

	if [ ! -z $SYS_ALIAS_FQDN ]; then
	    system_spf_add_dns $SYS_ALIAS_FQDN
	fi

	# Do any extra domains.
	for i in `seq 1 $SYS_TOTAL_FQDNS`;
	do
	    FQDN="SYS_FQDN_$i"
	    ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	    if [ ! -z ${!FQDN} ]; then
		system_spf_add_dns ${!FQDN}
	    fi

	    if [ ! -z ${!ALIAS_FQDN} ]; then
		system_spf_add_dns ${!ALIAS_FQDN}
	    fi
	done
    fi

    # Spam, virus checking.
    echo "  [system_mail_install_packages] Amavis, SpamAssassin, ClamAV" >> $LOG

    aptitude -y install amavisd-new spamassassin clamav-daemon libnet-dns-perl libmail-spf-perl pyzor razor
    aptitude -y install arj bzip2 cabextract cpio file gzip lha nomarch pax rar unrar unzip zip zoo

    echo "  [system_mail_install_packages] Updating ClamAV" >> $LOG

    sed -i '/Checks 24/ aDatabaseMirror db.'"$SYS_CLAMAV_DB_COUNTRY"'.clamav.net' /etc/clamav/freshclam.conf

    service clamav-freshclam stop
    freshclam >> $LOG
    service clamav-freshclam start

    # ClamAV

    adduser clamav amavis
    adduser amavis clamav

    echo -e '0 1\t* * *\troot\t/usr/bin/freshclam --quiet' | sudo tee --append /etc/crontab

    # SpamAssassin
    cp /etc/default/spamassassin /etc/default/spamassassin.orig

    sed -i 's/CRON=0/CRON=1/' /etc/default/spamassassin

    cp /etc/spamassassin/local.cf /etc/spamassassin/local.cf.orig

    sed -i '/required_score/ arequired_score 8' /etc/spamassassin/local.cf

    systemctl enable spamassassin.service
    service spamassassin start

    # Amavis
    cp /etc/amavis/conf.d/15-content_filter_mode /etc/amavis/conf.d/15-content_filter_mode.orig

    sed -i '/bypass_virus_checks_maps/,+2 s/#//' /etc/amavis/conf.d/15-content_filter_mode
    sed -i '/bypass_spam_checks_maps/,+2 s/#//' /etc/amavis/conf.d/15-content_filter_mode

    sed -i 's/admin = undef/admin = '"'"'abuse@'"$SYS_FQDN'"'/' /etc/amavis/conf.d/21-ubuntu_defaults

    chmod -R g+w /var/lib/amavis/tmp

    service amavis restart
    service clamav-daemon restart
}

function system_postgres_virtual_mail {
    echo "[system_postgres_virtual_mail]" >> $LOG

    SCHEMA="$SYS_EMAIL_DB_USER_NAME"

    echo "  [system_postgres_virtual_mail] Creating postgres user" >> $LOG

    sudo -u postgres createuser -U postgres -E "$SYS_EMAIL_DB_USER_NAME" >> $LOG 2>&1

    echo "  [system_postgres_virtual_mail] Creating postgres database" >> $LOG

    sudo -u postgres createdb -U postgres -O "$SYS_EMAIL_DB_USER_NAME" "$SYS_EMAIL_DB_SERVER_NAME" "$SYS_FQDN's email server" >> $LOG 2>&1

    echo "  [system_postgres_virtual_mail] Installing extensions" >> $LOG

    sudo -u postgres psql -w -U postgres >> $LOG 2>&1 <<EOF
--  Add extensions to the mail server database.
\c $SYS_EMAIL_DB_SERVER_NAME
-- Ubuntu doesn't have Blowfish
CREATE EXTENSION pgcrypto;
CREATE EXTENSION citext;
EOF

    echo "  [system_postgres_virtual_mail] Changing permissions on $SYS_EMAIL_DB_USER_NAME" >> $LOG

    # Temporarily give access to the mail user without a password.
    sed -i '/postgres/ ilocal   all            '"$SYS_EMAIL_DB_USER_NAME"'                                     trust' /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf

    systemctl reload postgresql

    echo "  [system_postgres_virtual_mail] Installing database tables" >> $LOG

    # Hash password.
    HASHED_SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN=$(doveadm pw -s SSHA512.base64 -p $SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN)
    #echo "HASHED_SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN = $HASHED_SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN" >> $LOG

cat <<EOF > /tmp/psql-config.sql
--  Make sure the search path can find the schema by naming it after the user.
CREATE SCHEMA $SCHEMA AUTHORIZATION $SYS_EMAIL_DB_USER_NAME;

--  Create the mail server tables.
CREATE TABLE $SCHEMA.virtual_domains (
  domain_id SERIAL,
  domain_name varchar(253) NOT NULL UNIQUE,
  PRIMARY KEY (domain_id)
);

COMMENT ON TABLE virtual_domains IS 'Domains';

CREATE TABLE $SCHEMA.virtual_users (
  user_id SERIAL,
  domain_id INTEGER NOT NULL,
--  Can't do Blowfish
--  password varchar(60) NOT NULL,
  password varchar(108) NOT NULL,
  email citext NOT NULL UNIQUE,
  PRIMARY KEY (user_id),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(domain_id) ON DELETE CASCADE
);

COMMENT ON TABLE virtual_users IS 'Users';

CREATE TABLE $SCHEMA.virtual_aliases (
  alias_id SERIAL,
  domain_id INTEGER NOT NULL,
  source citext NOT NULL UNIQUE,
  destination citext NOT NULL,
  PRIMARY KEY (alias_id),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(domain_id) ON DELETE CASCADE
);

COMMENT ON TABLE virtual_aliases IS 'Email aliases';

--  Populate the database.
INSERT INTO virtual_domains
  (domain_name)
VALUES
  ('$SYS_FQDN');

INSERT INTO virtual_users
  (domain_id, password , email)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'),
--  Can't do Blowfish - Added backslash so the password doesn't get dumped to the log.
--    crypt('\$SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN', gen_salt('bf', 8)), '$SYS_ADMIN_USER_NAME@$SYS_FQDN');
    '$HASHED_SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN', '$SYS_ADMIN_USER_NAME@$SYS_FQDN');

--  Set initial aliases of root@, abuse@, postmaster@ and webmaster@ and send them to admin@.
INSERT INTO virtual_aliases
  (domain_id, source, destination)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'root@$SYS_FQDN', '$SYS_ADMIN_USER_NAME@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'abuse@$SYS_FQDN', '$SYS_ADMIN_USER_NAME@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'postmaster@$SYS_FQDN', '$SYS_ADMIN_USER_NAME@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'webmaster@$SYS_FQDN', '$SYS_ADMIN_USER_NAME@$SYS_FQDN');
EOF

    # Add the email addresses for the optional other FQDN's.
    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	EMAIL_PASSWORD="SYS_ADMIN_USER_EMAIL_PASSWORD_FQDN_$i"
	export HASHED_EMAIL_PASSWORD=$(sudo doveadm pw -s SSHA512.base64 -p ${!EMAIL_PASSWORD})
	#echo "HASHED_EMAIL_PASSWORD = $HASHED_EMAIL_PASSWORD" >> $LOG

	if [ ! -z ${!FQDN} -o ! -z ${!EMAIL_PASSWORD} ]; then
cat <<EOF >> /tmp/psql-config.sql
--  Optional fqdn's.
INSERT INTO virtual_domains
  (domain_name)
VALUES
  ('${!FQDN}');

INSERT INTO virtual_users
  (domain_id, password , email)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'),
--  Can't do Blowfish
--    crypt('${!EMAIL_PASSWORD}', gen_salt('bf', 8)), '$SYS_ADMIN_USER_NAME@${!FQDN}');
    '$HASHED_EMAIL_PASSWORD', '$SYS_ADMIN_USER_NAME@${!FQDN}');

INSERT INTO virtual_aliases
  (domain_id, source, destination)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'root@${!FQDN}', '$SYS_ADMIN_USER_NAME@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'abuse@${!FQDN}', '$SYS_ADMIN_USER_NAME@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'postmaster@${!FQDN}', '$SYS_ADMIN_USER_NAME@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'webmaster@${!FQDN}', '$SYS_ADMIN_USER_NAME@${!FQDN}');
EOF
	fi
    done

    # Add the alias domain for the main system FQDN.
    if [ ! -z $SYS_ALIAS_FQDN ]; then
cat <<EOF >> /tmp/psql-config.sql
--  Main domain's alias domain.
INSERT INTO virtual_domains
  (domain_name)
VALUES
  ('$SYS_ALIAS_FQDN');

INSERT INTO virtual_aliases
  (domain_id, source, destination)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'root@$SYS_ALIAS_FQDN', 'root@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'abuse@$SYS_ALIAS_FQDN', 'abuse@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'postmaster@$SYS_ALIAS_FQDN', 'postmaster@$SYS_FQDN'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '$SYS_FQDN'), 'webmaster@$SYS_ALIAS_FQDN', 'webmaster@$SYS_FQDN');
EOF
    fi

    # Add the alias domains and email addresses for the optional alias FQDN's.
    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	if [ ! -z ${!ALIAS_FQDN} ]; then
cat <<EOF >> /tmp/psql-config.sql
--  Alias domains.
INSERT INTO virtual_domains
  (domain_name)
VALUES
  ('${!ALIAS_FQDN}');

INSERT INTO virtual_aliases
  (domain_id, source, destination)
VALUES
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'root@${!ALIAS_FQDN}', 'root@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'abuse@${!ALIAS_FQDN}', 'abuse@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'postmaster@${!ALIAS_FQDN}', 'postmaster@${!FQDN}'),
  ((SELECT domain_id FROM virtual_domains WHERE domain_name = '${!FQDN}'), 'webmaster@${!ALIAS_FQDN}', 'webmaster@${!FQDN}');
EOF
	fi
    done

    # Read in the SQL commands now to set up the database.
    sudo -u postgres psql -U "$SYS_EMAIL_DB_USER_NAME" -d "$SYS_EMAIL_DB_SERVER_NAME" -f /tmp/psql-config.sql >> $LOG 2>&1

    if [ "$SYS_DEBUG" == "off" ]; then
	rm /tmp/psql-config.sql
    fi

    #########################
    # Lock down the database.
    echo "  [system_postgres_virtual_mail] Locking database access" >> $LOG

    sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf

    # Remove the trusted mail user, now that all users have to have md5 passwords.
    sed -i '/'"$SYS_EMAIL_DB_USER_NAME"'/d' /etc/postgresql/$PSQL_VERSION/main/pg_hba.conf

    systemctl reload postgresql

    # Add a PostgreSQL password to the email server user.
    echo "  [system_postgres_virtual_mail] Setting PostgreSQL password for $SYS_EMAIL_DB_USER_NAME" >> $LOG

    sudo -u postgres psql -U postgres >> $LOG 2>&1 <<EOF
ALTER USER $SYS_EMAIL_DB_USER_NAME WITH ENCRYPTED PASSWORD '$SYS_EMAIL_DB_USER_PASSWORD';
EOF
    # Add a PostgreSQL password to the postgres user.
    echo "  [system_postgres_virtual_mail] Setting PostgreSQL password for postgres user" >> $LOG

    sudo -u postgres psql -U postgres >> $LOG 2>&1 <<EOF
ALTER USER postgres WITH ENCRYPTED PASSWORD '$SYS_POSTGRES_DB_USER_PASSWORD';
EOF

    # Change the Linux postgres user password
    echo "postgres:$SYS_POSTGRES_USER_PASSWORD" | chpasswd

    mkdir -p /etc/postfix/postgres

    cat <<EOF > /etc/postfix/postgres/virtual-mailbox-domains.cf
user = $SYS_EMAIL_DB_USER_NAME
password = $SYS_EMAIL_DB_USER_PASSWORD
hosts = 127.0.0.1
dbname = $SYS_EMAIL_DB_SERVER_NAME
query = SELECT domain_name FROM virtual_domains WHERE domain_name='%s'
EOF

    cat <<EOF > /etc/postfix/postgres/virtual-mailbox-maps.cf
user = $SYS_EMAIL_DB_USER_NAME
password = $SYS_EMAIL_DB_USER_PASSWORD
hosts = 127.0.0.1
dbname = $SYS_EMAIL_DB_SERVER_NAME
query = SELECT email FROM virtual_users WHERE email='%s'
EOF

    cat <<EOF > /etc/postfix/postgres/virtual-alias-maps.cf
user = $SYS_EMAIL_DB_USER_NAME
password = $SYS_EMAIL_DB_USER_PASSWORD
hosts = 127.0.0.1
dbname = $SYS_EMAIL_DB_SERVER_NAME
query = SELECT destination FROM virtual_aliases WHERE source='%s'
EOF

    cat <<EOF > /etc/postfix/postgres/virtual-email2email.cf
user = $SYS_EMAIL_DB_USER_NAME
password = $SYS_EMAIL_DB_USER_PASSWORD
hosts = 127.0.0.1
dbname = $SYS_EMAIL_DB_SERVER_NAME
query = SELECT email FROM virtual_users WHERE email='%s'
EOF

    # Don't need this access anymore.
    #deluser postgres sudo
}

function postfix_dovecot {
    echo "[postfix_dovecot]" >> $LOG

    # Detemine encryption, try blowfish first.
    cp /etc/postfix/master.cf /etc/postfix/master.cf.orig
    cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

    if [ "$SYS_ENABLE_LETSENCRYPT" == "yes" ]; then
	/usr/sbin/postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$SYS_FQDN/fullchain.pem"
	/usr/sbin/postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$SYS_FQDN/privkey.pem"
    else
	LAST_DIR=`pwd`
	cd /usr/share/dovecot/
	echo "[Generating Dovecot keys]" >> $LOG
	cp dovecot-openssl.cnf dovecot-openssl.cnf.orig
	sed -i 's/organizationalUnitName = @commonName@/organizationalUnitName = test/' dovecot-openssl.cnf
	sed -i 's/commonName = @commonName@/commonName = test/' dovecot-openssl.cnf
	sed -i 's/emailAddress = @emailAddress@/emailAddress = '"$SYS_ADMIN_USER_NAME@$SYS_FQDN"'/' dovecot-openssl.cnf
	./mkcert.sh >> $LOG 2>&1
	cd $LAST_DIR
	unset LAST_DIR

	/usr/sbin/postconf -e "smtpd_tls_cert_file = /etc/dovecot/dovecot.pem"
	/usr/sbin/postconf -e "smtpd_tls_key_file = /etc/dovecot/private/dovecot.pem"
    fi

    /usr/sbin/postconf -e "smtpd_use_tls = yes"
    /usr/sbin/postconf -e "smtpd_tls_auth_only = yes"

    sed -i '/^smtpd_tls_session_cache_database/d' /etc/postfix/main.cf
    sed -i '/^smtp_tls_session_cache_database/d' /etc/postfix/main.cf

    /usr/sbin/postconf -e "mydestination = localhost.\$mydomain, localhost, mail.\$mydomain"
    #/usr/sbin/postconf -e "myorigin = /etc/mailname"
    /usr/sbin/postconf -e "myorigin = $SYS_FQDN"
    /usr/sbin/postconf -e "myhostname = mail.$SYS_FQDN"

    echo "mail.$SYS_FQDN" > /etc/mailname

    #Enabling SMTP for authenticated users, and handing off authentication to Dovecot
    /usr/sbin/postconf -e "smtpd_sasl_type = dovecot"
    /usr/sbin/postconf -e "smtpd_sasl_path = private/auth"
    /usr/sbin/postconf -e "smtpd_sasl_auth_enable = yes"

    #/usr/sbin/postconf -e "mydestination = localhost"
    /usr/sbin/postconf -e "inet_interfaces = all"

    #Handing off local delivery to Dovecot's LMTP, and telling it where to store mail
    /usr/sbin/postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

    /usr/sbin/postconf -e "virtual_mailbox_domains = pgsql:/etc/postfix/postgres/virtual-mailbox-domains.cf"
    /usr/sbin/postconf -e "virtual_mailbox_maps = pgsql:/etc/postfix/postgres/virtual-mailbox-maps.cf"
    /usr/sbin/postconf -e "virtual_alias_maps = pgsql:/etc/postfix/postgres/virtual-alias-maps.cf, pgsql:/etc/postfix/postgres/virtual-email2email.cf"

    # This line ensures that only people logged into the server can send email. See smtpd_sender_restrictions in master.cf
    /usr/sbin/postconf -e "smtpd_sender_login_maps = pgsql:/etc/postfix/postgres/virtual-mailbox-maps.cf"

    /usr/sbin/postconf -e "policyd-spf_time_limit = 3600"
    /usr/sbin/postconf -e "smtpd_recipient_restrictions = permit_sasl_authenticated, reject_unauth_destination, check_policy_service unix:private/policyd-spf"

    # Amavis - Additional option for (spam/virus) filtering
    /usr/sbin/postconf -e "content_filter = smtp-amavis:[127.0.0.1]:10024"

    touch /tmp/restart-postfix

    # Finish installing Dovecot
    cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
    cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
    cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
    cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
    cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
    cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig

    # Edit /etc/dovecot/dovecot.conf
    sed -i '/^\!include_try/ aprotocols = imap pop3 lmtp' /etc/dovecot/dovecot.conf

    # Edit /etc/dovecot/conf.d/10-mail.conf
    sed -i 's/^mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/mail_location = maildir:\/var\/mail\/vhosts\/%d\/%n/' /etc/dovecot/conf.d/10-mail.conf
    sed -i 's/^#mail_privileged_group =/mail_privileged_group = mail/' /etc/dovecot/conf.d/10-mail.conf

    # Create the maildirs
    mkdir -p "/var/mail/vhosts"

    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
    	FQDN="SYS_FQDN_$i"

    	if [ ! -z ${!FQDN} ]; then
    	    mkdir -p "/var/mail/vhosts/${!FQDN}"
    	fi
    done

    # Create the mail user.
    groupadd -g 5000 vmail
    useradd -g vmail -u 5000 vmail -d /var/mail/vhosts -c "virtual mail user"
    chown -R vmail:vmail /var/mail

    # Edit /etc/dovecot/conf.d/10-auth.conf
    sed -i 's/^#disable_plaintext_auth = yes/disable_plaintext_auth = yes/' /etc/dovecot/conf.d/10-auth.conf
    sed -i 's/^auth_mechanisms = plain/auth_mechanisms = plain login/' /etc/dovecot/conf.d/10-auth.conf
    sed -i 's/^!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf
    sed -i 's/^#!include auth-sql.conf.ext/!include auth-sql.conf.ext/' /etc/dovecot/conf.d/10-auth.conf

    # Create new /etc/dovecot/conf.d/auth-sql.conf.ext
    cat <<EOF > /etc/dovecot/conf.d/auth-sql.conf.ext
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
EOF

    # Edit /etc/postfix/master.cf
    #sed -i '/submission/,+10 s/#//' /etc/postfix/master.cf
    #sed -i '/smtps/,+10 s/#//' /etc/postfix/master.cf

    cat <<EOF > /etc/postfix/master.cf
#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master" or
# on-line: http://www.postfix.org/master.5.html).
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (no)    (never) (100)
# ==========================================================================
smtp      inet  n       -       y       -       -       smtpd
#smtp      inet  n       -       y       -       1       postscreen
#smtpd     pass  -       -       y       -       -       smtpd
#dnsblog   unix  -       -       y       -       0       dnsblog
#tlsproxy  unix  -       -       y       -       0       tlsproxy
#submission inet n       -       y       -       -       smtpd
#  -o syslog_name=postfix/submission
#  -o smtpd_tls_security_level=encrypt
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=permit_mynetworks,reject_unknown_sender_domain,reject_sender_login_mismatch,reject_unauth_pipelining,reject_non_fqdn_sender,permit
  -o milter_macro_daemon_name=ORIGINATING
#smtps     inet  n       -       y       -       -       smtpd
#  -o syslog_name=postfix/smtps
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_reject_unlisted_recipient=no
#  -o smtpd_client_restrictions=$mua_client_restrictions
#  -o smtpd_helo_restrictions=$mua_helo_restrictions
#  -o smtpd_sender_restrictions=$mua_sender_restrictions
#  -o smtpd_recipient_restrictions=
#  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=permit_mynetworks,reject_unknown_sender_domain,reject_sender_login_mismatch,reject_unauth_pipelining,reject_non_fqdn_sender,permit
  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       y       -       -       qmqpd
pickup    fifo  n       -       -       60      1       pickup
         -o content_filter=
         -o receive_override_options=no_header_body_checks
#pickup    unix  n       -       y       60      1       pickup
#         -o content_filter=
#         -o receive_override_options=no_header_body_checks
cleanup   unix  n       -       y       -       0       cleanup
qmgr      unix  n       -       n       300     1       qmgr
#qmgr     unix  n       -       n       300     1       oqmgr
tlsmgr    unix  -       -       y       1000?   1       tlsmgr
rewrite   unix  -       -       y       -       -       trivial-rewrite
bounce    unix  -       -       y       -       0       bounce
defer     unix  -       -       y       -       0       bounce
trace     unix  -       -       y       -       0       bounce
verify    unix  -       -       y       -       1       verify
flush     unix  n       -       y       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       y       -       -       smtp
relay     unix  -       -       y       -       -       smtp
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       y       -       -       showq
error     unix  -       -       y       -       -       error
retry     unix  -       -       y       -       -       error
discard   unix  -       -       y       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       y       -       -       lmtp
anvil     unix  -       -       y       -       1       anvil
scache    unix  -       -       y       -       1       scache
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about ${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  user=cyrus argv=/cyrus/bin/deliver -e -r ${sender} -m ${extension} ${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m ${extension} ${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix  -       n       n       -       2       pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  ${nexthop} ${user}

# SPF policy
policyd-spf  unix  -       n       n       -       0       spawn
    user=policyd-spf argv=/usr/bin/policyd-spf

# Options for the filter
smtp-amavis     unix    -       -       -       -       2       smtp
        -o smtp_data_done_timeout=1200
        -o smtp_send_xforward_command=yes
        -o disable_dns_lookups=yes
        -o max_use=20

# Listener for filtered mail
127.0.0.1:10025 inet    n       -       -       -       -       smtpd
        -o content_filter=
        -o local_recipient_maps=
        -o relay_recipient_maps=
        -o smtpd_restriction_classes=
        -o smtpd_delay_reject=no
        -o smtpd_client_restrictions=permit_mynetworks,reject
        -o smtpd_helo_restrictions=
        -o smtpd_sender_restrictions=
        -o smtpd_recipient_restrictions=permit_mynetworks,reject
        -o smtpd_data_restrictions=reject_unauth_pipelining
        -o smtpd_end_of_data_restrictions=
        -o mynetworks=127.0.0.0/8
        -o smtpd_error_sleep_time=0
        -o smtpd_soft_error_limit=1001
        -o smtpd_hard_error_limit=1000
        -o smtpd_client_connection_count_limit=0
        -o smtpd_client_connection_rate_limit=0
        -o receive_override_options=no_header_body_checks,no_unknown_recipient_checks
EOF

    chmod -R o-rwx /etc/postfix

    service postfix restart

    # Edit /etc/dovecot/dovecot-sql.conf.ext
    cat <<EOF > /etc/dovecot/dovecot-sql.conf.ext
driver = pgsql
connect = host=127.0.0.1 dbname=$SYS_EMAIL_DB_SERVER_NAME user=$SYS_EMAIL_DB_USER_NAME password=$SYS_EMAIL_DB_USER_PASSWORD
#default_pass_scheme = BLF-CRYPT
default_pass_scheme = SSHA512
password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
EOF
    # sed -i 's/^#driver =/driver = pgsql/' /etc/dovecot/dovecot-sql.conf.ext
    # sed -i 's/^#connect =/connect = host=127.0.0.1 dbname='"$SYS_EMAIL_DB_SERVER_NAME"' user='"$SYS_EMAIL_DB_USER_NAME"' password='"$SYS_EMAIL_DB_USER_PASSWORD"'/' /etc/dovecot/dovecot-sql.conf.ext
    # sed -i 's/^#default_pass_scheme = MD5/default_pass_scheme = BLF-CRYPT/' /etc/dovecot/dovecot-sql.conf.ext
    # sed -i '/^#password_query = \\/ ipassword_query = SELECT email as user, password FROM virtual_users WHERE email='\''%u'\'';' /etc/dovecot/dovecot-sql.conf.ext

    # Fix permissions
    chown -R vmail:dovecot /etc/dovecot
    chmod -R o-rwx /etc/dovecot

    # Disable unencrypted IMAP and POP3
    # IMAP
    sed -i 's/#port = 143/port = 0  # 143/' /etc/dovecot/conf.d/10-master.conf
    sed -i '/#port = 993/ a    ssl = yes' /etc/dovecot/conf.d/10-master.conf
    sed -i 's/#port = 993/port = 993/' /etc/dovecot/conf.d/10-master.conf

    # POP3
    sed -i 's/#port = 110/port = 0   # 110/' /etc/dovecot/conf.d/10-master.conf
    sed -i '/#port = 995/ a    ssl = yes' /etc/dovecot/conf.d/10-master.conf
    sed -i 's/#port = 995/port = 995/' /etc/dovecot/conf.d/10-master.conf

    # LMTP
    sed -i 's/unix_listener lmtp/unix_listener \/var\/spool\/postfix\/private\/dovecot-lmtp/' /etc/dovecot/conf.d/10-master.conf
    sed -i '/\/var\/spool\/postfix\/private\/dovecot-lmtp {/ a\ \ \ \ mode = 0600\n    user = postfix\n    group = postfix' /etc/dovecot/conf.d/10-master.conf

    # Auth
    sed -i '/unix_listener auth-userdb/ i\ \ unix_listener \/var\/spool\/postfix\/private\/auth {\n    mode = 0666\n    user = postfix\n    group = postfix\n  }\n' /etc/dovecot/conf.d/10-master.conf
    sed -i '/unix_listener auth-userdb/ a\ \ \ \ mode = 0600\n    user = vmail' /etc/dovecot/conf.d/10-master.conf
    sed -i '/# Postfix smtp-auth/ i\ \ # Auth process is run as this user.\n  user = dovecot\n' /etc/dovecot/conf.d/10-master.conf
    sed -i '/^service auth-worker/ a\ \ user = vmail' /etc/dovecot/conf.d/10-master.conf

    # Use Lets Encrypt SSL certs.
    sed -i 's/^ssl = no/ssl = yes/' /etc/dovecot/conf.d/10-ssl.conf

    if [ "$SYS_ENABLE_LETSENCRYPT" == "yes" ]; then
	sed -i 's/^#ssl_cert = <\/etc\/dovecot\/dovecot.pem/ssl_cert = <\/etc\/letsencrypt\/live\/'"$SYS_FQDN"'\/fullchain.pem/' /etc/dovecot/conf.d/10-ssl.conf
	sed -i 's/^#ssl_key = <\/etc\/dovecot\/private\/dovecot.pem/ssl_key = <\/etc\/letsencrypt\/live\/'"$SYS_FQDN"'\/privkey.pem/' /etc/dovecot/conf.d/10-ssl.conf
    else
	sed -i 's/^#ssl_cert = <\/etc\/dovecot\/dovecot.pem/ssl_cert = <\/etc\/dovecot\/dovecot.pem/' /etc/dovecot/conf.d/10-ssl.conf
	sed -i 's/^#ssl_key = <\/etc\/dovecot\/private\/dovecot.pem/ssl_key = <\/etc\/dovecot\/private\/dovecot.pem/' /etc/dovecot/conf.d/10-ssl.conf
    fi

    # Protect against POODLE attack.
    sed -i 's/^#ssl_protocols = !SSLv2/ssl_protocols = !SSLv3 !SSLv2/' /etc/dovecot/conf.d/10-ssl.conf

    service dovecot restart
}

# $1 - FQDN
# $2 - Selector - Data YYYYMM
function generate_dkim_key_and_add_dns {
    echo "  [generate_dkim_key_and_add_dns] Generating DKIM key for domain $1 with date $2" >> $LOG

    opendkim-genkey -b 4096 -h rsa-sha256 -r -s $2 -d $1 -v >> $LOG

    sed -i 's/h=rsa-sha/h=sha/' $2.txt

    local DNS_KEY=`cat $2.txt | cut -d '"' -f2 | tr -d '\n'`
    local DNS_SELECTOR=`awk {'print $1,$2'} $2.txt | sed 's/\s.*$//' | head -n1`

    if [ "$SYS_ADD_DNS" == "yes" ]; then
	echo "  [generate_dkim_key_and_add_dns] Adding DKIM DNS records for domain $1 with date $2" >> $LOG

	linode domain record-create $1 TXT "$DNS_SELECTOR" "$DNS_KEY" --ttl 300 >> $LOG

	if [ "$SYS_DEBUG" == "on" ]; then
	    echo "linode domain record-delete \"$1\" TXT \"$DNS_SELECTOR\"" >> /root/remove-all-dns-entries.sh
	fi
    fi
}

# $1 - FQDN
# $2 - Selector - Data YYYYMM
# $3 - Selector next month - Data YYYYMM
function generate_dkim_key {
    echo "  [generate_dkim_key] Generating DKIM key for domain $1 with date $2" >> $LOG

    pushd /etc/opendkim/keys/$1

    generate_dkim_key_and_add_dns $1 $2
    generate_dkim_key_and_add_dns $1 $3

    # Rename the keys.
    mv $2.private default.private
    mv $2.txt default.txt

    popd
}

# $1 - FQDN
function system_dkim_append_trusted_hosts {
    echo "  [system_dkim_append_trusted_hosts] Adding domain, $1, to /etc/opendkim/trusted.hosts" >> $LOG

    cat <<EOF >> /etc/opendkim/trusted.hosts
*.$1
EOF
}

# $1 - FQDN
# $2 - Selector
function system_dkim_append_tables {
    echo "  [system_dkim_append_tables] Adding domain, $1, to SigningTable" >> $LOG

    echo -e "*@$1\t$1" >> /etc/opendkim/signing.table

    echo "  [system_dkim] Adding domain, $1, to KeyTable" >> $LOG

    echo -e "$1\t$1:$2:/etc/opendkim/keys/$1/default.private" >> /etc/opendkim/key.table
}

function system_dkim {
    echo "[system_dkim]" >> $LOG

    mv /etc/opendkim.conf /etc/opendkim.conf.orig

    mkdir /var/spool/postfix/opendkim
    chown opendkim:postfix /var/spool/postfix/opendkim

#     cat <<EOF > /etc/default/opendkim
# # Command-line options specified here will override the contents of
# # /etc/opendkim.conf. See opendkim(8) for a complete list of options.
# #DAEMON_OPTS=""
# #
# # Uncomment to specify an alternate socket
# # Note that setting this will override any Socket value in opendkim.conf
# SOCKET="local:/var/spool/postfix/opendkim/opendkim.sock"
# #SOCKET="inet:54321" # listen on all interfaces on port 54321
# #SOCKET="inet:12345@localhost" # listen on loopback on port 12345
# #SOCKET="inet:12345@192.0.2.1" # listen on 192.0.2.1 on port 12345
# EOF

    cat <<EOF > /etc/opendkim.conf
# This is a basic configuration that can easily be adapted to suit a standard
# installation. For more advanced options, see opendkim.conf(5) and/or
# /usr/share/doc/opendkim/examples/opendkim.conf.sample.

# Log to syslog
Syslog          yes
# Required to use local socket with MTAs that access the socket as a non-
# privileged user (e.g. Postfix)
UMask           002
# OpenDKIM user
# Remember to add user postfix to group opendkim
UserID          opendkim

Socket          local:/var/spool/postfix/opendkim/opendkim.sock

# Map domains in From addresses to keys used to sign messages
KeyTable        /etc/opendkim/key.table
SigningTable        refile:/etc/opendkim/signing.table

# Hosts to ignore when verifying signatures
ExternalIgnoreList  /etc/opendkim/trusted.hosts
InternalHosts       /etc/opendkim/trusted.hosts

# Commonly-used options; the commented-out versions show the defaults.
Canonicalization    relaxed/simple
Mode            sv
SubDomains      no
#ADSPAction     continue
AutoRestart     yes
AutoRestartRate     10/1h
Background      yes
DNSTimeout      5
SignatureAlgorithm  rsa-sha256

# Always oversign From (sign using actual From and a null From to prevent
# malicious signatures header fields (From and/or others) between the signer
# and the verifier.  From is oversigned by default in the Debian package
# because it is often the identity key used by reputation systems and thus
# somewhat security sensitive.
OversignHeaders     From
EOF

    chmod u=rw,go=r /etc/opendkim.conf

    # Configure Postfix
    /usr/sbin/postconf -e "milter_default_action = accept"
    /usr/sbin/postconf -e "milter_protocol = 6"
    # /usr/sbin/postconf -e "smtpd_milters = local:/opendkim/opendkim.sock"
    # /usr/sbin/postconf -e "non_smtpd_milters = local:/opendkim/opendkim.sock"
    # /usr/sbin/postconf -e "smtpd_milters = local:/var/run/opendkim/opendkim.sock"
    # /usr/sbin/postconf -e "non_smtpd_milters = local:/var/run/opendkim/opendkim.sock"
    /usr/sbin/postconf -e "smtpd_milters = local:var/run/opendkim/opendkim.sock"
    /usr/sbin/postconf -e "non_smtpd_milters = local:var/run/opendkim/opendkim.sock"

    # Fix bug - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=853769#38
    #sed -i 's/ExecStart=.*/ExecStart=\/usr\/sbin\/opendkim -x \/etc\/opendkim.conf -P \/var\/spool\/postfix\/var\/run\/opendkim\/opendkim.pid -p unix:\/var\/spool\/postfix\/var\/run\/opendkim\/opendkim.sock/' /lib/systemd/system/opendkim.service
    sed -i 's/ExecStart=.*/ExecStart=\/usr\/sbin\/opendkim -x \/etc\/opendkim.conf -P \/var\/run\/opendkim\/opendkim.pid -p unix:\/var\/spool\/postfix\/var\/run\/opendkim\/opendkim.sock/' /lib/systemd/system/opendkim.service
    systemctl daemon-reload

    # Make sure we have the correct directory in the chroot set up for the opendkim.sock file!
    mkdir -p /var/spool/postfix/var/run/opendkim
    chown -R opendkim:opendkim /var/spool/postfix/var

    # Make the key directories.
    mkdir -p /etc/opendkim/keys/$SYS_FQDN

    if [ ! -z $SYS_ALIAS_FQDN ]; then
	mkdir -p /etc/opendkim/keys/$SYS_ALIAS_FQDN
    fi

    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	if [ ! -z ${!FQDN} ]; then
	    mkdir -p /etc/opendkim/keys/${!FQDN}
	fi

	if [ ! -z ${!ALIAS_FQDN} ]; then
	    mkdir -p /etc/opendkim/keys/${!ALIAS_FQDN}
	fi
    done

    # Add to trusted.hosts.
    echo "  [system_dkim] Adding main domain, $SYS_FQDN, to /etc/opendkim/trusted.hosts" >> $LOG

    cat <<EOF > /etc/opendkim/trusted.hosts
127.0.0.1
::1
localhost

*.$SYS_FQDN
EOF

    if [ ! -z $SYS_ALIAS_FQDN ]; then
	system_dkim_append_trusted_hosts $SYS_ALIAS_FQDN
    fi

    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	if [ ! -z ${!FQDN} ]; then
	    system_dkim_append_trusted_hosts ${!FQDN}
	fi

	if [ ! -z ${!ALIAS_FQDN} ]; then
	    system_dkim_append_trusted_hosts ${!ALIAS_FQDN}
	fi
    done

    # Then add to signing.table and generate the keys.
    system_dkim_append_tables $SYS_FQDN $DKIM_DATE

    generate_dkim_key $SYS_FQDN $DKIM_DATE $DKIM_DATE_NEXT_MONTH

    # Add the first domain's alias domain.
    if [ ! -z $SYS_ALIAS_FQDN ]; then
	system_dkim_append_tables $SYS_ALIAS_FQDN $DKIM_DATE

	generate_dkim_key $SYS_ALIAS_FQDN $DKIM_DATE $DKIM_DATE_NEXT_MONTH
    fi

    for i in `seq 1 $SYS_TOTAL_FQDNS`;
    do
	FQDN="SYS_FQDN_$i"
	ALIAS_FQDN="SYS_ALIAS_FQDN_$i"
	# DOMAIN_ALIAS=`echo ${!FQDN} | awk -F \. {'print $1'}`

	##############################################################################################
	# Now do the same for additional FQDN's
	if [ ! -z ${!FQDN} ]; then
	    system_dkim_append_tables ${!FQDN} $DKIM_DATE

	    generate_dkim_key ${!FQDN} $DKIM_DATE $DKIM_DATE_NEXT_MONTH

	    # Add the first domain's alias domain.
	    if [ ! -z ${!ALIAS_FQDN} ]; then
		system_dkim_append_tables ${!ALIAS_FQDN} $DKIM_DATE

		generate_dkim_key ${!ALIAS_FQDN} $DKIM_DATE $DKIM_DATE_NEXT_MONTH
	    fi
	fi
    done

    chown -R opendkim:opendkim /etc/opendkim
    chmod -R go-rwx /etc/opendkim/keys

    service opendkim restart
    service postfix restart

    # echo "  Enable DKIM" >> $LOG
    # echo "    Edit the above files" >> $LOG
    # echo "    Follow: https://www.linode.com/docs/email/postfix/configure-spf-and-dkim-in-postfix-on-debian-8" >> $LOG
    # echo "    opendkim-genkey -b 2048 -h rsa-sha256 -r -s YYYYMM -d example.com -v" >> $LOG
}

# Scripts need to be executed to handle the updating of the DKIM keys. This StackScript installs 2 keys for each
# domain, the current and next month's keys.
#
# 1) On the first day of every month, update the /etc/opendkim/key.table file to change the selector for each domain,
#    which would be the current month.
# 2) Generate the next month's key and add a DNS record for each domain with that selector.
# 3) Delete last month's DNS entry and key files.
# 4) Rename the new keys from YYYYMM.* to default.*
function system_dkim_cron_jobs {
    echo "[system_dkim_cron_jobs]" >> $LOG

    mkdir -p /opt/opendkim
    mkdir -p /etc/opendkim/crondata

    # chmod -R go-rwx /etc/opendkim/crondata

    # Set the selector to delete, this will be updated by the cron script.
    # echo $DKIM_DATE > /etc/opendkim/crondata/remove.txt

#`date +%Y%m --date='+1 month'`
    cat <<EOF > /opt/opendkim/cronjob.sh
#!/bin/sh

LOG=/var/log/opendkim-cronjob.sh

export LINODE_API_KEY=$SYS_API_KEY

LAST_MONTH=\`date +%Y%m --date='-1 month'\`
THIS_MONTH=\`date +%Y%m\`
NEXT_MONTH=\`date +%Y%m --date='+1 month'\`

SELECTOR_TO_REMOVE=\`awk -F\: '{ print \$2 }' /etc/opendkim/key.table |uniq\`
DOMAINS=\`awk '{ print \$1 }' /etc/opendkim/key.table\`

if [ "\$SELECTOR_TO_REMOVE" -ne "\$LAST_MONTH" ]; then
    echo "[/opt/opendkim/cronjob.sh] Failed, selector is incorrect!" >&2

    exit 1;
fi

# \$1 - FQDN to generate a key for
# \$2 - Last month's selector
# \$3 - This month's selector
# \$4 - Next month's selector
function update_dkim_key {
    echo "[update_dkim_keys] Replacing DKIM key for domain \$1 selector \$2 with selector \$3" >> \$LOG

    pushd /etc/opendkim/keys/\$1

    # Remove the last month's key.
    mv default.private \$2.private
    mv default.txt \$2.txt

    local DNS_SELECTOR_TO_REMOVE=\`awk {'print \$1,\$2'} \$2.txt | sed 's/\s.*$//' | head -n1\`

    linode domain record-delete \$1 "\$DNS_SELECTOR_TO_REMOVE" >> \$LOG

    # Rename this month's keys.
    mv \$3.private default.private
    mv \$3.txt default.txt

    # Generate the new key for next month
    opendkim-genkey -b 4096 -h rsa-sha256 -r -s \$4 -d \$1 -v >> $LOG

    sed -i 's/h=rsa-sha/h=sha/' \$4.txt

    local DNS_KEY=\`cat \$4.txt | cut -d '"' -f2 | tr -d '\n'\`
    local DNS_SELECTOR=\`awk {'print \$1,\$2'} \$4.txt | sed 's/\s.*$//' | head -n1\`

    linode domain record-create \$1 TXT "\$DNS_SELECTOR" "\$DNS_KEY" --ttl 300 >> \$LOG

    popd
}

for domain in \$DOMS; do
    update_dkim_key \$domain \$SELECTOR_TO_REMOVE \$THIS_MONTH \$NEXT_MONTH
done

# Replace the selector in the key table entries.
sed -i 's/:'"\$SELECTOR_TO_REMOVE"':/:'"\$THIS_MONTH"':/' /etc/opendkim/key.table

# Set the selector to remove on the next run of cron, i.e. next month.
echo \$NEXT_MONTH > /etc/opendkim/crondata/remove.txt
EOF

    chmod u=rx,go= /opt/opendkim/cronjob.sh

    echo -e '0 0\t1 * *\troot\tcronic /opt/opendkim/cronjob.sh' | sudo tee --append /etc/crontab
}

####################################################################
# Author Domain Signing Practices (ADSP)
#
# $1 - FQDN
####################################################################
function system_adsp_add_record {
    echo "  [system_adsp_add_record] Adding ADSP DNS record for domain $1" >> $LOG

    linode domain record-create "$1" TXT "_adsp._domainkey" "dkim=all" --ttl 300 >> $LOG

    if [ "$SYS_DEBUG" == "on" ]; then
	echo "linode domain record-delete \"$1\" TXT \"_adsp._domainkey\"" >> /root/remove-all-dns-entries.sh
    fi
}

function system_adsp {
    echo "[system_adsp]" >> $LOG

    if [ "$SYS_ADD_DNS" == "yes" ]; then
	system_adsp_add_record $SYS_FQDN

	if [ ! -z $SYS_ALIAS_FQDN ]; then
	    system_adsp_add_record $SYS_ALIAS_FQDN
	fi

	# Do any extra domains.
	for i in `seq 1 $SYS_TOTAL_FQDNS`;
	do
	    FQDN="SYS_FQDN_$i"
	    ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	    if [ ! -z ${!FQDN} ]; then
		system_adsp_add_record ${!FQDN}
	    fi

	    if [ ! -z ${!ALIAS_FQDN} ]; then
		system_adsp_add_record ${!ALIAS_FQDN}
	    fi
	done
    fi
}

####################################################################
# Domain Message Authentication, Reporting & Conformance (DMARC)
#
# $1 - FQDN
####################################################################
function system_dmarc_add_record {
    echo "  [system_dmarc_add_record] Adding DMARC DNS record for domain $1" >> $LOG

    linode domain record-create "$1" TXT "_dmarc" "v=DMARC1;p=quarantine;sp=quarantine;adkim=r;aspf=r" --ttl 300 >> $LOG

    if [ "$SYS_DEBUG" == "on" ]; then
	echo "linode domain record-delete \"$1\" TXT \"_dmarc\"" >> /root/remove-all-dns-entries.sh
    fi
}

function system_dmarc {
    echo "[system_dmarc]" >> $LOG

    if [ "$SYS_ADD_DNS" == "yes" ]; then
	system_dmarc_add_record $SYS_FQDN

	if [ ! -z $SYS_ALIAS_FQDN ]; then
	    system_dmarc_add_record $SYS_ALIAS_FQDN
	fi

	# Do any extra domains.
	for i in `seq 1 $SYS_TOTAL_FQDNS`;
	do
	    FQDN="SYS_FQDN_$i"
	    ALIAS_FQDN="SYS_ALIAS_FQDN_$i"

	    if [ ! -z ${!FQDN} ]; then
		system_dmarc_add_record ${!FQDN}
	    fi

	    if [ ! -z ${!ALIAS_FQDN} ]; then
		system_dmarc_add_record ${!ALIAS_FQDN}
	    fi
	done
    fi
}

function system_install_nginx {
    if [ "$SYS_ENABLE_NGINX" == "yes" ]; then
	apt-get -y install nginx

	cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig

	sed -i 's/^worker_processes auto/worker_processes 2/' /etc/nginx/nginx.conf
	sed -i  '/worker_connections/ a\\tuse epoll;' /etc/nginx/nginx.conf
	sed -i 's/\# multi_accept on/multi_accept on/' /etc/nginx/nginx.conf
	sed -i  '/keepalive_timeout/ a\\tkeepalive_requests 100000;' /etc/nginx/nginx.conf
	sed -i '/server_tokens/ a\\tclient_body_buffer_size\t\t128k;\n\tclient_max_body_size\t\t10m;\n\tclient_header_buffer_size\t1k;\n\tlarge_client_header_buffers\t4 4k;\n\toutput_buffers\t\t\t1 32k;\n\tpostpone_output\t\t\t1460;' /etc/nginx/nginx.conf
	sed -i '/postpone_output/ a\\tclient_header_timeout\t\t3m;\n\tclient_body_timeout\t\t3m;\n\tsend_timeout\t\t\t3m;' /etc/nginx/nginx.conf

	service nginx reload
    fi
}

####################################################################
# Install base system.
####################################################################

system_update

system_set_hostname "$SYS_HOSTNAME"

system_set_host_info

system_set_timezone

system_rsyslog

system_set_linode_key

####################################################################
# Secure the server.
####################################################################

echo "user_add_sudo $SYS_ADMIN_USER_NAME" >> $LOG
user_add_sudo "$SYS_ADMIN_USER_NAME" "$SYS_ADMIN_USER_PASSWORD"

user_add_pubkey "$SYS_ADMIN_USER_NAME" "$SYS_ADMIN_USER_SSHKEY"

system_sshd_lockdown

####################################################################
# Add firewall.
####################################################################
system_security_fail2ban
system_security_ufw_configure_basic

system_lets_encrypt

system_linode_cli

####################################################################
# Mail: PostgreSQL, Postfix, Dovecot.
####################################################################
postfix_install_loopback_only

system_mail_install_packages
system_postgres_virtual_mail
postfix_dovecot

system_dkim

system_dkim_cron_jobs

system_adsp

system_dmarc


if [ "$SYS_DEBUG" == "on" ]; then
    chmod +x /root/remove-all-dns-entries.sh
fi

####################################################################
# Web server
####################################################################
system_install_nginx

####################################################################
# Ada
####################################################################

echo "Completed" >> $LOG