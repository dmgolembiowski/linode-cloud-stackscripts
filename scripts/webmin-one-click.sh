# linode/webmin-one-click.sh by linode
# id: 662116
# description: Webmin One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-pwless_sudo-label-enable-passwordless-sudo-access-for-the-limited-user-oneof-yesno-default-no-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-auto_updates-label-configure-automatic-security-updates-oneof-yesno-default-no-name-fail2ban-label-use-fail2ban-to-prevent-automated-instrusion-attempts-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-dns-records-default-name-subdomain-label-the-subdomain-for-your-server-default-name-domain-label-your-domain-default-name-soa_email_address-label-admin-email-for-the-server-default-name-mx-label-do-you-need-an-mx-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-spf-label-do-you-need-an-spf-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 34 + AllTime: 927
#!/usr/bin/env bash

### UDF Variables for the StackScript

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="pwless_sudo" label="Enable passwordless sudo access for the limited user?" oneOf="Yes,No" default="No">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="auto_updates" label="Configure automatic security updates?" oneOf="Yes,No" default="No">
#<UDF name="fail2ban" label="Use fail2ban to prevent automated instrusion attempts?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your DNS records" default="">
#<UDF name="subdomain" label="The subdomain for your server" default="">
#<UDF name="domain" label="Your domain" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">

#Check if the script is being sourced by another script
[[ $_ != $0 ]] && readonly SOURCED=1

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript and API/DNS Libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

function webmin_install {
    # Install webmin
    echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
    wget -q -O- http://www.webmin.com/jcameron-key.asc | sudo apt-key add
    system_update
    system_install_package "webmin"
}

function webmin_configure {
    local -r email_address="$1"
    local -r fqdn="$2"

    # Configure the Virtual Host
    cat <<EOF > /etc/apache2/sites-available/"${fqdn}.conf"
<VirtualHost *:80>
  ServerAdmin ${email_address}
  ServerName ${fqdn}
  ProxyPass / http://localhost:10000/
  ProxyPassReverse / http://localhost:10000/
</VirtualHost>
EOF
    # Disable SSL in Webmin so Apache can handle it instead
    sed -i 's/^ssl=1/ssl=0/g' /etc/webmin/miniserv.conf

    # Add FQDN to the list of allowed domains
    echo "referers=${fqdn}" >> /etc/webmin/config

    # Restart Webmin
    systemctl restart webmin

    # Enable proxy_http module
    a2enmod proxy_http
    systemctl restart apache2

    # Enable the Virtual Host
    a2ensite "${fqdn}"
    systemctl reload apache2
}


# Open the needed firewall ports
ufw_install
ufw allow http
ufw allow https
ufw allow 10000

# Make sure unzip is installed, or else the webmin install will fail
[ ! -x /usr/bin/unzip ] && system_install_package "unzip"

# "${package_list[@]}" contains a list of packages to be installed on the system
package_list=(
    "gnupg1" \
    "python" \
    "apt-show-versions" \
    "libapt-pkg-perl" \
    "libauthen-pam-perl" \
    "libio-pty-perl" \
    "libnet-ssleay-perl"
)

# Install all of the packages specified in ${package_list[@]}
system_install_package "${package_list[@]}"

# Intall Webmin
webmin_install
apache_install
webmin_configure "$SOA_EMAIL_ADDRESS" "$FQDN"

# Install SSL Certificate - NOT READY YET
#certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'

## Cleanup before exiting
if [ "$SOURCED" -ne 1 ]; then
    stackscript_cleanup
fi