# linode/kali-linux-one-click.sh by linode
# id: 1017300
# description: Kali Linux One-Click
# defined fields: name-everything-label-would-you-like-to-install-the-kali-everything-package-oneof-yesno-default-yes-name-headless-label-would-you-like-to-install-the-kali-headless-package-oneof-yesno-default-no-name-vnc-label-would-you-like-to-setup-vnc-to-access-kali-xfce-desktop-oneof-yesno-default-yes-name-username-label-the-vnc-user-to-be-created-for-the-linode-the-username-accepts-only-lowercase-letters-numbers-dashes-and-underscores-_-name-password-label-the-password-for-the-limited-vnc-user-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-required-for-creating-dns-records-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-soa_email_address-label-email-address-for-soa-records-requires-api-token-default
# images: ['linode/kali']
# stats: Used By: 826 + AllTime: 6690
#!/bin/bash
## Kali
#<UDF name="everything" label="Would you like to Install the Kali Everything Package?" oneOf="Yes,No" default="Yes">
#<UDF name="headless" label="Would you like to Install the Kali Headless Package?" oneOf="Yes,No" default="No">
#<UDF name="vnc" label="Would you like to setup VNC to access Kali XFCE Desktop" oneOf="Yes,No" default="Yes">
#<UDF name="username" label="The VNC user to be created for the Linode. The username accepts only lowercase letters, numbers, dashes (-) and underscores (_)">
#<UDF name="password" label="The password for the limited VNC user">

## Linode/SSH Security Settings
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required for creating DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="soa_email_address" label="Email address for SOA records (Requires API token)" default="" >

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
set -o pipefail

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

function headlessoreverything {
    if [ $HEADLESS == "Yes" ] && [ $EVERYTHING == "Yes" ]; then 
        DEBIAN_FRONTEND=noninteractive apt-get install kali-linux-everything -y -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    elif [ $EVERYTHING == "Yes" ] && [ $HEADLESS == "No" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install kali-linux-everything -y -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    elif [ $HEADLESS == "Yes" ] && [ $EVERYTHING == "No" ]; then 
        DEBIAN_FRONTEND=noninteractive apt-get install kali-linux-headless -y -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    elif [ $HEADLESS == "No" ] && [ $EVERYTHING == "No" ]; then 
         echo "No Package Selected"
     fi
}

function vncsetup {
    if [ $VNC == "Yes" ]; then 
    ## XFCE & VNC Config
    apt-get install xfce4 xfce4-goodies dbus-x11 tigervnc-standalone-server expect -y -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

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
    sleep 2
    killvncprocess=$(ps aux | grep "/usr/bin/Xtigervnc :1 -localhost=1 -desktop" | head -n 1 | awk '{ print $2; }')
    kill $killvncprocess
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
    systemctl daemon-reload
    systemctl start vncserver@1.service
    systemctl enable vncserver@1.service

    cat <<EOF > /etc/motd
###################################
#   VNC SSH Tunnel Instructions   #
###################################

* Ensure you have a VNC Client installed on your local machine
* Run the command below to start the SSH tunnel for VNC 

    ssh -L 61000:localhost:5901 -N -l $USERNAME $FQDN

* For more Detailed documentation please visit the offical Documentation below

    https://www.linode.com/docs/products/tools/marketplace/guides/kalilinux

### To remove this message, you can edit the /etc/motd file ###
EOF
    fi
}

function main {
    headlessoreverything
    vncsetup
    stackscript_cleanup
}

main