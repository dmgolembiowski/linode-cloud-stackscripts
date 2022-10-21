# linode/proservices-centos-7-deployment.sh by professional
# id: 13409
# description: ** DO NOT USE **
Basic setup for a proservices deployed CentOS 7 instance and grants access to the proservices team
# defined fields: 
# images: ['linode/centos7']
# stats: Used By: 11 + AllTime: 104
#!/bin/bash
# Tarq's CentOS 7 Deployment Script
# By Christopher Tarquini (http://tarq.io)
#
# <udf name="DISABLE_NM_DNS" label="Prevent NM resolv.conf clobbering?" oneOf="Yes,No", default="Yes" />
# <udf name="NEW_HOSTNAME" label="What is my hostname?" default="" example="db1.example.com" />
# <udf name="ADMIN_USER" label="Admin Username" default="admin" example="User to be added with sudo rights" />
# <udf name="INSTALL_EPEL" label="Add EPEL Repos?" oneOf="Yes,No", default="Yes" />
# <udf name="INSTALL_NODESOURCE" label="Install NodeJS?" oneOf="No,7.x,6.x,0.10", default="No" />
# <udf name="INSTALL_PERCONA_REPO" label="Add Percona Repos?" oneOf="Yes,No", default="No" />
# <udf name="INSTALL_PACKAGES" label="Which packages do we need?" manyOf="httpd,Percona-XtraDB-Cluster-56 Percona-XtraDB-Cluster-shared-56,Percona-Server-server-56,mariadb,percona-toolkit,percona-xtrabackup,keepalived,pacemaker pcs resource-agents,nginx,php,php-fpm,php-mysql,varnish,haproxy,postgresql,redis" default=""/>
# <udf name="PUBLIC_SERVICES" default="http" label="Firewall Whitelist" manyOf="http,https,amanda-client,bacula,bacula-client,dhcp,dhcpv6,dhcpv6-client,dns,freeipa-ldap,freeipa-ldaps,freeipa-replication,ftp,high-availability,imaps,ipp,ipp-client,ipsec,iscsi-target,kerberos,kpasswd,ldap,ldaps,libvirt,libvirt-tls,mdns,mountd,ms-wbt,mysql,nfs,ntp,openvpn,pmcd,pmproxy,pmwebapi,pmwebapis,pop3s,postgresql,proxy-dhcp,radius,RH-Satellite-6,rpc-bind,rsyncd,samba,samba-client,smtp,ssh,telnet,tftp,tftp-client,transmission-client,vdsm,vnc-server,wbem-https"

useradd "$ADMIN_USER"
#(cd "/home/$ADMIN_USER" && umask 077 && mkdir -p .ssh && curl --silent "https://github.com/$GITHUB_NAME.keys" >> .ssh/authorized_keys && chown -R "$ADMIN_USER:$ADMIN_USER" .ssh)
curl -Ls https://git.io/viCcQ | sudo -u "$ADMIN_USER" -- bash -

usermod -a -G wheel "$ADMIN_USER"
echo "%wheel        ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/wheel
chmod 600 /etc/sudoers.d/wheel

if [ "$INSTALL_EPEL" == "Yes" ]; then
  yum -y install epel-release
fi 

if [ "$INSTALL_PERCONA_REPO" == "Yes" ]; then
  yum -y remove mysql-libs
  yum -y install https://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-4.noarch.rpm
fi

if [ "$DISABLE_NM_DNS" == "Yes" ]; then
  NM_CONF="/etc/NetworkManager/conf.d/10-dns-no-clobber.conf"
  echo "[main]" > $NM_CONF
  echo "dns=none" >> $NM_CONF
  systemctl restart NetworkManager

fi

[  -z "$NEW_HOSTNAME" ] || hostnamectl set-hostname "$NEW_HOSTNAME"

yum -y update
PACKAGES=${INSTALL_PACKAGES//,/ }
yum -y install $PACKAGES

if [ "$INSTALL_NODESOURCE" != "No" ]; then
   nodeversion="_$INSTALL_NODESOURCE"
   if [ "$nodeversion" == "_0.10" ]; then nodeversion=""; fi;
   curl --silent --location https://rpm.nodesource.com/setup$nodeversion | bash -
   yum install -y gcc-c++ make nodejs
fi

curl -Ls https://git.io/viCcQ | bash

systemctl enable firewalld
systemctl start firewalld



services=${PUBLIC_SERVICES//,/ }
for service in $services; do firewall-cmd --zone=public --add-service="$service" --permanent; done;
firewall-cmd --reload