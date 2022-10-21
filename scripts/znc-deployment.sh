# linode/znc-deployment.sh by mbeach
# id: 46425
# description: Install and set up ZNC on a Linode.

This StackScript sets up a hardened CentOS 7 deployment using the steps in the "Securing your Server" guide here:
https://www.linode.com/docs/security/securing-your-server

Then sets up ZNC using the steps here:
http://wiki.znc.in/Installation#Fedora.2FCentOS.2FRed_Hat_Enterprise_Linux

Because of the differences in maintenance of the ZNC package across distributions, CentOS 7 is used in this StackScript for the latest-and-greatest. See http://wiki.znc.in/Installation for more info on why this is the case.

ZNC will be configured to start automatically on boot but will remain unconfigured after installation. The Linode will automatically reboot once the StackScript completes. After rebooting, you will need to run the following steps to complete installation and open the firewall port:

sudo -u znc znc --makeconf
sudo firewall-cmd --zone=public --add-port=####/tcp
sudo firewall-cmd --zone=public --add-port=####/tcp --permanent

# defined fields: name-ssuser-label-sudo-user-username-example-username-name-sspassword-label-sudo-user-password-example-strongpassword-name-sspubkey-label-ssh-pubkey-installed-for-root-and-sudo-user-example-ssh-rsa
# images: ['linode/centos7']
# stats: Used By: 4 + AllTime: 78
#!/bin/bash
##
#<UDF name="ssuser" Label="Sudo user username?" example="username" />
#<UDF name="sspassword" Label="Sudo user password?" example="strongPassword" />
#<UDF name="sspubkey" Label="SSH pubkey (installed for root and sudo user)?" example="ssh-rsa ..." />
#
# Works for CentOS 7

# 
if [[ ! $SSUSER ]]; then read -p "Sudo user username?" SSUSER; fi
if [[ ! $SSPASSWORD ]]; then read -p "Sudo user password?" SSPASSWORD; fi
if [[ ! $SSPUBKEY ]]; then read -p "SSH pubkey (installed for root and sudo user)?" SSPUBKEY; fi

### Make it secure

# set up sudo user
useradd $SSUSER && echo $SSPASSWORD | passwd $SSUSER --stdin
usermod -aG wheel $SSUSER
# sudo user complete

# set up ssh pubkey
mkdir -p /root/.ssh
mkdir -p /home/$SSUSER/.ssh
echo "$SSPUBKEY" > /root/.ssh/authorized_keys
echo "$SSPUBKEY" > /home/$SSUSER/.ssh/authorized_keys
chmod -R 700 /root/.ssh
chmod -R 700 /home/${SSUSER}/.ssh
chown -R ${SSUSER}:${SSUSER} /home/${SSUSER}/.ssh

# disable password and root over ssh
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sed -i -e "s/#PasswordAuthentication no/PasswordAuthentication no/" /etc/ssh/sshd_config
systemctl restart sshd

#remove unneeded services
yum remove -y avahi chrony

# Initial needfuls
yum update -y
yum upgrade -y
yum install -y epel-release
yum upgrade -y

# Set up automatic updates
yum install -y yum-cron
sed -i -e "s/apply_updates = no/apply_updates = yes/" /etc/yum/yum-cron.conf
# auto-updates complete

#set up fail2ban
yum install -y fail2ban
cd /etc/fail2ban
cp fail2ban.conf fail2ban.local
cp jail.conf jail.local
sed -i -e "s/backend = auto/backend = systemd/" /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban

# set up firewalld
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --set-default-zone=public
firewall-cmd --zone=public --add-interface=eth0
firewall-cmd --reload

# ensure ntp is installed and running
yum install -y ntp
systemctl enable ntpd
systemctl start ntpd

# install ZNC
yum install -y znc znc-devel
systemctl enable znc
# done install ZNC
# set up clientbuffer module
cd /root/
# # # this clientbuffer fork originally fixed the duplicate query message issue, but is no longer available:
# # # curl -o clientbuffer.cpp https://raw.githubusercontent.com/blole/znc-clientbuffer/master/clientbuffer.cpp
# # this is now the official plugin repo:
# # curl -o clientbuffer.cpp -L https://raw.githubusercontent.com/CyberShadow/znc-clientbuffer/master/clientbuffer.cpp
# updated temporary repo to make this module compatible with ZNC 1.7.2:
curl -o clientbuffer.cpp -L https://raw.githubusercontent.com/wireframeskull/znc-clientbuffer/master/clientbuffer.cpp
yum install -y gcc-c++ redhat-rpm-config
/bin/znc-buildmod clientbuffer.cpp
mv clientbuffer.so /usr/lib64/znc/
# done

# reboot.
echo Rebooting in 10 seconds...
(sleep 10; reboot) &