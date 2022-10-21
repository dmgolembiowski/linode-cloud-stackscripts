# linode/vpn.sh by qujinhui0614
# id: 13031
# description: L2TP
# defined fields: 
# images: ['linode/centos6.8']
# stats: Used By: 0 + AllTime: 116
#!/bin/bash
clear
bit=$(getconf LONG_BIT)
if [ "$bit" = "32" ];then
    LIBDIR="lib"
    PPTPD="http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.4.0-1.el6.i686.rpm"
elif [ "$bit" = "64" ];then
    LIBDIR="lib64"
    PPTPD="http://poptop.sourceforge.net/yum/stable/packages/pptpd-1.4.0-1.el6.x86_64.rpm"
else
    echo "Unknow system bit."
    exit 1
fi
echo -e "1. CentOS 6\n2. Ubuntu/Debian"
while [ "$SYSTEMVERSION" != "1" ] && [ "$SYSTEMVERSION" != "2" ] 
do
    read -p "Select your operating system(1 or 2):" SYSTEMVERSION
done
echo -e "Install selection\n=========="
echo -e "1. FreeRadius Server with FreeRadius Client,Poptop Server and L2TP Over IPSec(Require MySQL Server).\n2. FreeRadius Client,Poptop Server and L2TP Over IPSec(Require FreeRadius Server communication secret).\n3. FreeRadius Server Only(Require MySQL Server).\n4. Poptop Server Only\n5. L2TP Over IPSec Only\n=========="
read -p "Please choose a selection(1,2,3,4 or 5):" SELECTION
while [ "$SELECTION" != "1" ] && [ "$SELECTION" != "2" ] && [ "$SELECTION" != "3" ] && [ "$SELECTION" != "4" ] && [ "$SELECTION" != "5" ]
do
  echo "Wrong choice."
  read -p "Please choose a selection(1,2,3,4 or 5):" SELECTION
done
case $SELECTION in
  1)
    FREERADIUSSERVER=1
    FREERADIOUSCLIENT=1
    POPTOPSERVER=1
    xl2tp_ipsec=1
  ;;
  2)
    FREERADIOUSCLIENT=1
    POPTOPSERVER=1
    xl2tp_ipsec=1
  ;;
  3)
    FREERADIUSSERVER=1
  ;;
  4)
    POPTOPSERVER=1
  ;;
  5)
    xl2tp_ipsec=1
  ;;
  *)
    echo "Good bye."
  ;;
esac
INFORMATION_FREERADIUSSERVER() {
    while [ "$MYSQLROOTPASSWORD" = "" ]
    do
        read -p "Input the MySQL root password:" MYSQLROOTPASSWORD
        echo "show databases"| mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD > /dev/null || MYSQLROOTPASSWORD=""
    done
        echo "Create database radius" | mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD
    while [ "$RADIUSPASSWORD" = "" ]
    do
        read -p "Set the MySQL password of user radius(Leave blank to create automatically):" RADIUSPASSWORD
        if [ "$RADIUSPASSWORD" = "" ];then
            RADIUSPASSWORD=$(/usr/bin/md5sum /proc/meminfo | awk '{print $1}')
            echo "Set the MySQL password of user radius to $RADIUSPASSWORD"
        fi
    done
}
INFORMATION_POPTOPSERVER() {
    /sbin/ifconfig | grep "inet addr:" | cut -d ":" -f 2 | awk '{print $1}' | grep -v "127.0.0.1"
    read -p "Select your IP:" NETWORKIP
}
INFORMATION_xl2tp_ipsec() {
    if [ "${NETWORKIP}" == "" ];then
        /sbin/ifconfig | grep "inet addr:" | cut -d ":" -f 2 | awk '{print $1}' | grep -v "127.0.0.1"
        read -p "Select your IP:" NETWORKIP
    fi
    while [ "" = "" ]
    do
        read -p "Please input the IPSec PSK:" psk
        if [ "${psk}" == "" ];then
            echo "Invalid IPSec PSK."
        else
            break
        fi
    done
}

if [ "$SYSTEMVERSION" = "2" ];then
FREERADIUSSERVER() {
    apt-get update
    apt-get install -y freeradius-mysql mysql-client || exit 1
    sed -i "s/PASSWORD('radpass')/PASSWORD('$RADIUSPASSWORD')/g" /etc/freeradius/sql/mysql/admin.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/admin.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/cui.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/ippool.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/nas.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/schema.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/wimax.sql
    #sed -i "s/^#\tsql$/\tsql/g" /etc/freeradius/sites-enabled/default
    sed -i "s/password = \"radpass\"/password = \"$RADIUSPASSWORD\"/g" /etc/freeradius/sql.conf
    ln -sf /etc/freeradius/sql.conf /etc/freeradius/modules/sql
cat>/etc/freeradius/modules/huorlylytraffic<<EOF
sqlcounter hourlytrafficcounter {
    counter-name = Hourly-Traffic
    check-name = Hourly-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = 1h
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/modules/dailytraffic<<EOF
sqlcounter dailytrafficcounter {
    counter-name = Daily-Traffic
    check-name = Daily-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = daily
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/modules/monthlytraffic<<EOF
sqlcounter monthlytrafficcounter {
    counter-name = Monthly-Traffic
    check-name = Monthly-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = monthly
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/sites-enabled/default<<EOF
authorize {
    preprocess
    chap
    mschap
    digest
    suffix
    eap {
        ok = return
    }
    files
    sql
    expiration
    logintime
    pap
    hourlytrafficcounter
    dailytrafficcounter
    monthlytrafficcounter
}
authenticate {
    Auth-Type PAP {
        pap
    }
    Auth-Type CHAP {
        chap
    }
    Auth-Type MS-CHAP {
        mschap
    }
    digest
    unix
    eap
}
preacct {
    preprocess
    acct_unique
    suffix
    files
}
accounting {
    detail
    unix
    radutmp
    sql
    exec
    attr_filter.accounting_response
}
session {
    radutmp
    sql
}
post-auth {
    sql
    exec
    Post-Auth-Type REJECT {
        # log failed authentications in SQL, too.
        attr_filter.access_reject
    }
}
pre-proxy {
}
post-proxy {
    eap
}
EOF
    killall -9 freeradius
    service freeradius start
}
FREERADIOUSCLIENT() {
    apt-get update
    apt-get install -y radiusclient1 || exit 1
    test -f /etc/freeradius/clients.conf &&  FREERADIUSSECRET=testing123 && FREERADIUSHOST=localhost
    while [ "$FREERADIUSSECRET" = "" ] && [ "$FREERADIUSHOST" = "" ]
    do
        read -p "Input the FreeRadius Server host and port(example 192.168.0.1:1812):" FREERADIUSHOST
        read -p "Input the FreeRadius Server communication secret:" FREERADIUSSECRET
    done
    echo -e "$FREERADIUSHOST\t$FREERADIUSSECRET" >> /etc/radiusclient/servers
cat>/etc/radiusclient/dictionary.microsoft<<EOF
#
#       Microsoft's VSA's, from RFC 2548
#
#       \$Id: poptop_ads_howto_8.htm,v 1.8 2008/10/02 08:11:48 wskwok Exp \$
#
VENDOR          Microsoft       311     Microsoft
BEGIN VENDOR    Microsoft
ATTRIBUTE       MS-CHAP-Response        1       string  Microsoft
ATTRIBUTE       MS-CHAP-Error           2       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-1           3       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-2           4       string  Microsoft
ATTRIBUTE       MS-CHAP-LM-Enc-PW       5       string  Microsoft
ATTRIBUTE       MS-CHAP-NT-Enc-PW       6       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Policy 7     string  Microsoft
# This is referred to as both singular and plural in the RFC.
# Plural seems to make more sense.
ATTRIBUTE       MS-MPPE-Encryption-Type 8       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Types  8     string  Microsoft
ATTRIBUTE       MS-RAS-Vendor           9       integer Microsoft
ATTRIBUTE       MS-CHAP-Domain          10      string  Microsoft
ATTRIBUTE       MS-CHAP-Challenge       11      string  Microsoft
ATTRIBUTE       MS-CHAP-MPPE-Keys       12      string  Microsoft encrypt=1
ATTRIBUTE       MS-BAP-Usage            13      integer Microsoft
ATTRIBUTE       MS-Link-Utilization-Threshold 14 integer        Microsoft
ATTRIBUTE       MS-Link-Drop-Time-Limit 15      integer Microsoft
ATTRIBUTE       MS-MPPE-Send-Key        16      string  Microsoft
ATTRIBUTE       MS-MPPE-Recv-Key        17      string  Microsoft
ATTRIBUTE       MS-RAS-Version          18      string  Microsoft
ATTRIBUTE       MS-Old-ARAP-Password    19      string  Microsoft
ATTRIBUTE       MS-New-ARAP-Password    20      string  Microsoft
ATTRIBUTE       MS-ARAP-PW-Change-Reason 21     integer Microsoft
ATTRIBUTE       MS-Filter               22      string  Microsoft
ATTRIBUTE       MS-Acct-Auth-Type       23      integer Microsoft
ATTRIBUTE       MS-Acct-EAP-Type        24      integer Microsoft
ATTRIBUTE       MS-CHAP2-Response       25      string  Microsoft
ATTRIBUTE       MS-CHAP2-Success        26      string  Microsoft
ATTRIBUTE       MS-CHAP2-CPW            27      string  Microsoft
ATTRIBUTE       MS-Primary-DNS-Server   28      ipaddr
ATTRIBUTE       MS-Secondary-DNS-Server 29      ipaddr
ATTRIBUTE       MS-Primary-NBNS-Server  30      ipaddr Microsoft
ATTRIBUTE       MS-Secondary-NBNS-Server 31     ipaddr Microsoft
#ATTRIBUTE      MS-ARAP-Challenge       33      string  Microsoft
#
#       Integer Translations
#
#       MS-BAP-Usage Values
VALUE           MS-BAP-Usage            Not-Allowed     0
VALUE           MS-BAP-Usage            Allowed         1
VALUE           MS-BAP-Usage            Required        2
#       MS-ARAP-Password-Change-Reason Values
VALUE   MS-ARAP-PW-Change-Reason        Just-Change-Password            1
VALUE   MS-ARAP-PW-Change-Reason        Expired-Password                2
VALUE   MS-ARAP-PW-Change-Reason        Admin-Requires-Password-Change  3
VALUE   MS-ARAP-PW-Change-Reason        Password-Too-Short              4
#       MS-Acct-Auth-Type Values
VALUE           MS-Acct-Auth-Type       PAP             1
VALUE           MS-Acct-Auth-Type       CHAP            2
VALUE           MS-Acct-Auth-Type       MS-CHAP-1       3
VALUE           MS-Acct-Auth-Type       MS-CHAP-2       4
VALUE           MS-Acct-Auth-Type       EAP             5
#       MS-Acct-EAP-Type Values
VALUE           MS-Acct-EAP-Type        MD5             4
VALUE           MS-Acct-EAP-Type        OTP             5
VALUE           MS-Acct-EAP-Type        Generic-Token-Card      6
VALUE           MS-Acct-EAP-Type        TLS             13
END-VENDOR Microsoft
EOF
cat>/etc/radiusclient/dictionary.merit<<EOF
#
#       Experimental extensions, configuration only (for check-items)
#       Names/numbers as per the MERIT extensions (if possible).
#
ATTRIBUTE       NAS-Identifier          32      string
ATTRIBUTE       Proxy-State             33      string
ATTRIBUTE       Login-LAT-Service       34      string
ATTRIBUTE       Login-LAT-Node          35      string
ATTRIBUTE       Login-LAT-Group         36      string
ATTRIBUTE       Framed-AppleTalk-Link   37      integer
ATTRIBUTE       Framed-AppleTalk-Network 38     integer
ATTRIBUTE       Framed-AppleTalk-Zone   39      string
ATTRIBUTE       Acct-Input-Packets      47      integer
ATTRIBUTE       Acct-Output-Packets     48      integer
# 8 is a MERIT extension.
VALUE           Service-Type            Authenticate-Only       8
EOF
sed -i -e "/dictionary.merit/d" -e "/dictionary.microsoft/d" -e "/-Traffic/d" /etc/radiusclient/dictionary
cat>>/etc/radiusclient/dictionary<<EOF
INCLUDE /etc/radiusclient/dictionary.merit
INCLUDE /etc/radiusclient/dictionary.microsoft
ATTRIBUTE Hourly-Traffic 1000 integer
ATTRIBUTE Daily-Traffic 1001 integer
ATTRIBUTE Monthly-Traffic 1002 integer
EOF
}
POPTOPSERVER() {
    apt-get update
    apt-get install -y pptpd || exit 1
    sed -i -e "/^localip/d" -e "/^remoteip/d" /etc/pptpd.conf
cat>>/etc/pptpd.conf<<EOF
localip 1.2.3.1
remoteip 1.2.3.2-254
EOF
sed -i "/^ms-dns/d" /etc/ppp/pptpd-options
cat>>/etc/ppp/pptpd-options<<EOF
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF
    if [ "${FREERADIOUSCLIENT}" == "1" ];then
    sed -i -e "/radius.so/d" -e "/radattr.so/d" /etc/ppp/pptpd-options
cat>>/etc/ppp/pptpd-options<<EOF
plugin /usr/lib/pppd/2.4.5/radius.so
plugin /usr/lib/pppd/2.4.5/radattr.so
EOF
    fi
cat>/etc/iptables.rc<<EOF
iptables -t nat -I POSTROUTING -s 1.2.3.0/24 -j SNAT --to $NETWORKIP
iptables -t nat -I POSTROUTING -s 10.1.2.0/24 -j SNAT --to $NETWORKIP
EOF
sed -r -i "/net\.ipv4\.ip_forward|net\.ipv4\.conf\.default\.rp_filter|net\.ipv4\.conf\.default\.accept_source_route|net\.ipv4\.conf\.all\.send_redirects|net\.ipv4\.conf\.default\.send_redirects|net\.ipv4\.icmp_ignore_bogus_error_responses/d" /etc/sysctl.conf
cat>>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward = 1
EOF
    chmod +x /etc/iptables.rc
    /etc/iptables.rc
    sysctl -p
    sed -i "/iptables.rc/d" /etc/rc.local
    sed -i "1a/etc/iptables.rc" /etc/rc.local
    service pptpd restart
}
xl2tp_ipsec() {
    apt-get install -y openswan xl2tpd || exit 1
ip=${NETWORKIP}
while [ "${psk}" = "" ]
do
    read -p "Please input the IPSec PSK:" psk
    if [ "${psk}" == "" ];then
        echo "Invalid IPSec PSK."
        psk=""
    else
        break
    fi
done
cat>/etc/xl2tpd/xl2tpd.conf<<EOF
[global]
ipsec saref = yes

[lns default]
ip range = 10.1.2.2-10.1.2.255
local ip = 10.1.2.1
;require chap = yes
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

cat>/etc/ipsec.secrets<<EOF
# This file holds shared secrets or RSA private keys for inter-Pluto
# authentication.  See ipsec_pluto(8) manpage, and HTML documentation.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".

# this file is managed with debconf and will contain the automatically created RSA keys
include /var/lib/openswan/ipsec.secrets.inc
${ip} %any  0.0.0.0: PSK "${psk}"
EOF

cat>/etc/ipsec.conf<<EOF
version 2.0     # conforms to second version of ipsec.conf specification

config setup
        nat_traversal=yes
        virtual_private=%v4:192.168.0.0/16,%v4:10.0.0.0/8,%v4:172.16.0.0/12,%v4:25.0.0.0/8,%v4:!10.254.253.0/24
        protostack=netkey
        #protostack=mast  # used for SAref + MAST only
        interfaces="%defaultroute"
        oe=off

conn l2tp-psk
        authby=secret
        pfs=no
        auto=add
        rekey=no
        # overlapip=yes   # for SAref + MAST
        # sareftrack=yes  # for SAref + MAST
        type=transport
        left=${ip}
        leftprotoport=17/1701
        #
        # The remote user.
        #
        right=%any
        rightprotoport=17/%any
        rightsubnet=vhost:%priv,%no
EOF

cat>/etc/ppp/options.xl2tpd<<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1200
mru 1200
nodefaultroute
debug
lock
proxyarp
connect-delay 5000
EOF

sed -r -i "/net\.ipv4\.ip_forward|net\.ipv4\.conf\.default\.rp_filter|net\.ipv4\.conf\.default\.accept_source_route|net\.ipv4\.conf\.all\.send_redirects|net\.ipv4\.conf\.default\.send_redirects|net\.ipv4\.icmp_ignore_bogus_error_responses/d" /etc/sysctl.conf
cat>>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
    if [ "${FREERADIOUSCLIENT}" == "1" ];then
    sed -i -e "/radius.so/d" -e "/radattr.so/d" /etc/ppp/options.xl2tpd
cat>>/etc/ppp/options.xl2tpd<<EOF
plugin /usr/lib/pppd/2.4.5/radius.so
plugin /usr/lib/pppd/2.4.5/radattr.so
EOF
    fi
sysctl -p
cat>/etc/iptables.rc<<EOF
iptables -t nat -I POSTROUTING -s 1.2.3.0/24 -j SNAT --to $NETWORKIP
iptables -t nat -I POSTROUTING -s 10.1.2.0/24 -j SNAT --to $NETWORKIP
EOF
    chmod +x /etc/iptables.rc
    /etc/iptables.rc
    sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
    sed -i "/iptables.rc/d" /etc/rc.local
    sed -i "1a/etc/iptables.rc" /etc/rc.local
    service pptpd restart
}
elif [ "$SYSTEMVERSION" = "1" ];then
FREERADIUSSERVER() {
    yum install -y freeradius-mysql|| exit 1
    ln -sf /etc/init.d/radiusd /etc/init.d/freeradius
    chkconfig radiusd on
    ln -sf /etc/raddb /etc/freeradius
    #yum -y install mysql-devel openldap-devel gcc
    #wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-2.2.5.tar.gz -O- | tar zxvf - -C /usr/src/ || exit 1
    #cd /usr/src/freeradius-server-2.2.5/
    #./configure --bindir=/usr/bin/ --sbindir=/usr/sbin/ --libexecdir=/usr/libexec/ --sysconfdir=/etc/ --libdir=/${LIBDIR}/ --with-raddbdir=/etc/freeradius && make && make install || exit 1
    #cp -r /usr/src/freeradius-server-2.2.5/redhat/freeradius-radiusd-init /etc/init.d/freeradius && chmod 755 /etc/init.d/freeradius && chown root:root /etc/init.d/freeradius && chkconfig --add freeradius && chkconfig freeradius on
    #sed -i "s/allow_vulnerable_openssl = no/allow_vulnerable_openssl = yes/g" /etc/freeradius/radiusd.conf
    sed -i "s/PASSWORD('radpass')/PASSWORD('$RADIUSPASSWORD')/g" /etc/freeradius/sql/mysql/admin.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/admin.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/cui.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/ippool.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/nas.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/schema.sql
    mysql --protocol=tcp -h localhost -u root -p$MYSQLROOTPASSWORD radius < /etc/freeradius/sql/mysql/wimax.sql
    #sed -i "s/^#\tsql$/\tsql/g" /etc/freeradius/sites-enabled/default
    sed -i "s/password = \"radpass\"/password = \"$RADIUSPASSWORD\"/g" /etc/freeradius/sql.conf
    ln -sf /etc/freeradius/sql.conf /etc/freeradius/modules/sql
cat>/etc/freeradius/modules/huorlylytraffic<<EOF
sqlcounter hourlytrafficcounter {
    counter-name = Hourly-Traffic
    check-name = Hourly-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = 1h
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/modules/dailytraffic<<EOF
sqlcounter dailytrafficcounter {
    counter-name = Daily-Traffic
    check-name = Daily-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = daily
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/modules/monthlytraffic<<EOF
sqlcounter monthlytrafficcounter {
    counter-name = Monthly-Traffic
    check-name = Monthly-Traffic
    reply-name = Reply-Message
    sqlmod-inst = sql
    key = User-Name
    reset = monthly
    query = "SELECT SUM(acctinputoctets + acctoutputoctets) DIV 1048576 FROM radacct WHERE UserName='%{%k}' AND UNIX_TIMESTAMP(AcctStartTime) > '%b'"
}
EOF
cat>/etc/freeradius/sites-enabled/default<<EOF
authorize {
    preprocess
    chap
    mschap
    digest
    suffix
    eap {
        ok = return
    }
    files
    sql
    expiration
    logintime
    pap
    hourlytrafficcounter
    dailytrafficcounter
    monthlytrafficcounter
}
authenticate {
    Auth-Type PAP {
        pap
    }
    Auth-Type CHAP {
        chap
    }
    Auth-Type MS-CHAP {
        mschap
    }
    digest
    unix
    eap
}
preacct {
    preprocess
    acct_unique
    suffix
    files
}
accounting {
    detail
    unix
    radutmp
    sql
    exec
    attr_filter.accounting_response
}
session {
    radutmp
    sql
}
post-auth {
    sql
    exec
    Post-Auth-Type REJECT {
        # log failed authentications in SQL, too.
        attr_filter.access_reject
    }
}
pre-proxy {
}
post-proxy {
    eap
}
EOF
}
FREERADIOUSCLIENT() {
    rpm -Uvh http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-8.noarch.rpm
    #yum -y install gcc bzip2 || exit 1
    yum -y install radiusclient-ng
    ln -sf /etc/radiusclient-ng /etc/radiusclient
    #wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-client-1.1.6.tar.bz2 -O- | tar xjvf - -C /usr/src/ || exit 1
    #cd /usr/src/freeradius-client-1.1.6/
    #./configure --bindir=/usr/bin/ --sbindir=/usr/sbin/ --libexecdir=/usr/libexec/ --sysconfdir=/etc/ --libdir=/${LIBDIR}/ && make && make install
    test -f /etc/freeradius/clients.conf &&  FREERADIUSSECRET=testing123 && FREERADIUSHOST=localhost
    while [ "$FREERADIUSSECRET" = "" ] && [ "$FREERADIUSHOST" = "" ]
    do
        read -p "Input the FreeRadius Server host(example 192.168.0.1):" FREERADIUSHOST
        read -p "Input the FreeRadius Server communication secret:" FREERADIUSSECRET
    done
    if [ "${FREERADIUSHOST}" != "localhost" ];then
        sed -i "s/localhost/${FREERADIUSHOST}/g" /etc/radiusclient/radiusclient.conf
    fi
    sed -i -e "s/^radius_deadtime.*0$/#radius_deadtime 0/g" -e "s/^bindaddr \*$/#bindaddr */g" /etc/radiusclient/radiusclient.conf
    echo -e "$FREERADIUSHOST\t$FREERADIUSSECRET" >> /etc/radiusclient/servers
cat>/etc/radiusclient/dictionary.microsoft<<EOF
#
#       Microsoft's VSA's, from RFC 2548
#
#       \$Id: poptop_ads_howto_8.htm,v 1.8 2008/10/02 08:11:48 wskwok Exp \$
#
VENDOR          Microsoft       311     Microsoft
BEGIN VENDOR    Microsoft
ATTRIBUTE       MS-CHAP-Response        1       string  Microsoft
ATTRIBUTE       MS-CHAP-Error           2       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-1           3       string  Microsoft
ATTRIBUTE       MS-CHAP-CPW-2           4       string  Microsoft
ATTRIBUTE       MS-CHAP-LM-Enc-PW       5       string  Microsoft
ATTRIBUTE       MS-CHAP-NT-Enc-PW       6       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Policy 7     string  Microsoft
# This is referred to as both singular and plural in the RFC.
# Plural seems to make more sense.
ATTRIBUTE       MS-MPPE-Encryption-Type 8       string  Microsoft
ATTRIBUTE       MS-MPPE-Encryption-Types  8     string  Microsoft
ATTRIBUTE       MS-RAS-Vendor           9       integer Microsoft
ATTRIBUTE       MS-CHAP-Domain          10      string  Microsoft
ATTRIBUTE       MS-CHAP-Challenge       11      string  Microsoft
ATTRIBUTE       MS-CHAP-MPPE-Keys       12      string  Microsoft encrypt=1
ATTRIBUTE       MS-BAP-Usage            13      integer Microsoft
ATTRIBUTE       MS-Link-Utilization-Threshold 14 integer        Microsoft
ATTRIBUTE       MS-Link-Drop-Time-Limit 15      integer Microsoft
ATTRIBUTE       MS-MPPE-Send-Key        16      string  Microsoft
ATTRIBUTE       MS-MPPE-Recv-Key        17      string  Microsoft
ATTRIBUTE       MS-RAS-Version          18      string  Microsoft
ATTRIBUTE       MS-Old-ARAP-Password    19      string  Microsoft
ATTRIBUTE       MS-New-ARAP-Password    20      string  Microsoft
ATTRIBUTE       MS-ARAP-PW-Change-Reason 21     integer Microsoft
ATTRIBUTE       MS-Filter               22      string  Microsoft
ATTRIBUTE       MS-Acct-Auth-Type       23      integer Microsoft
ATTRIBUTE       MS-Acct-EAP-Type        24      integer Microsoft
ATTRIBUTE       MS-CHAP2-Response       25      string  Microsoft
ATTRIBUTE       MS-CHAP2-Success        26      string  Microsoft
ATTRIBUTE       MS-CHAP2-CPW            27      string  Microsoft
ATTRIBUTE       MS-Primary-DNS-Server   28      ipaddr
ATTRIBUTE       MS-Secondary-DNS-Server 29      ipaddr
ATTRIBUTE       MS-Primary-NBNS-Server  30      ipaddr Microsoft
ATTRIBUTE       MS-Secondary-NBNS-Server 31     ipaddr Microsoft
#ATTRIBUTE      MS-ARAP-Challenge       33      string  Microsoft
#
#       Integer Translations
#
#       MS-BAP-Usage Values
VALUE           MS-BAP-Usage            Not-Allowed     0
VALUE           MS-BAP-Usage            Allowed         1
VALUE           MS-BAP-Usage            Required        2
#       MS-ARAP-Password-Change-Reason Values
VALUE   MS-ARAP-PW-Change-Reason        Just-Change-Password            1
VALUE   MS-ARAP-PW-Change-Reason        Expired-Password                2
VALUE   MS-ARAP-PW-Change-Reason        Admin-Requires-Password-Change  3
VALUE   MS-ARAP-PW-Change-Reason        Password-Too-Short              4
#       MS-Acct-Auth-Type Values
VALUE           MS-Acct-Auth-Type       PAP             1
VALUE           MS-Acct-Auth-Type       CHAP            2
VALUE           MS-Acct-Auth-Type       MS-CHAP-1       3
VALUE           MS-Acct-Auth-Type       MS-CHAP-2       4
VALUE           MS-Acct-Auth-Type       EAP             5
#       MS-Acct-EAP-Type Values
VALUE           MS-Acct-EAP-Type        MD5             4
VALUE           MS-Acct-EAP-Type        OTP             5
VALUE           MS-Acct-EAP-Type        Generic-Token-Card      6
VALUE           MS-Acct-EAP-Type        TLS             13
END-VENDOR Microsoft
EOF
cat>/etc/radiusclient/dictionary.merit<<EOF
#
#       Experimental extensions, configuration only (for check-items)
#       Names/numbers as per the MERIT extensions (if possible).
#
ATTRIBUTE       NAS-Identifier          32      string
ATTRIBUTE       Proxy-State             33      string
ATTRIBUTE       Login-LAT-Service       34      string
ATTRIBUTE       Login-LAT-Node          35      string
ATTRIBUTE       Login-LAT-Group         36      string
ATTRIBUTE       Framed-AppleTalk-Link   37      integer
ATTRIBUTE       Framed-AppleTalk-Network 38     integer
ATTRIBUTE       Framed-AppleTalk-Zone   39      string
ATTRIBUTE       Acct-Input-Packets      47      integer
ATTRIBUTE       Acct-Output-Packets     48      integer
# 8 is a MERIT extension.
VALUE           Service-Type            Authenticate-Only       8
EOF
sed -i -e "/dictionary.merit/d" -e "/dictionary.microsoft/d" -e "/-Traffic/d" /usr/share/radiusclient-ng/dictionary
cat>>/usr/share/radiusclient-ng/dictionary<<EOF
INCLUDE /etc/radiusclient/dictionary.merit
INCLUDE /etc/radiusclient/dictionary.microsoft
ATTRIBUTE Hourly-Traffic 1000 integer
ATTRIBUTE Daily-Traffic 1001 integer
ATTRIBUTE Monthly-Traffic 1002 integer
EOF
}
POPTOPSERVER() {
    yum install -y ppp || exit 1
    wget $PPTPD -O /tmp/pptpd.rpm && rpm -ivh /tmp/pptpd.rpm || exit 1
    #ln -sf /etc/ppp/options.pptpd /etc/ppp/pptpd-options
    sed -i -e "/^localip/d" -e "/^remoteip/d" /etc/pptpd.conf
cat>>/etc/pptpd.conf<<EOF
localip 1.2.3.1
remoteip 1.2.3.2-254
EOF
sed -i "/^ms-dns/d" /etc/ppp/options.pptpd
cat>>/etc/ppp/options.pptpd<<EOF
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF
    if [ "${FREERADIOUSCLIENT}" == "1" ];then
    sed -i -e "/radius.so/d" -e "/radattr.so/d" /etc/ppp/options.pptpd
cat>>/etc/ppp/options.pptpd<<EOF
plugin /usr/${LIBDIR}/pppd/2.4.5/radius.so
plugin /usr/${LIBDIR}/pppd/2.4.5/radattr.so
EOF
    fi
cat>/etc/iptables.rc<<EOF
iptables -t nat -I POSTROUTING -s 1.2.3.0/24 -j SNAT --to $NETWORKIP
iptables -t nat -I POSTROUTING -s 10.1.2.0/24 -j SNAT --to $NETWORKIP
EOF
sed -i "/net\.ipv4\.ip_forward/d" /etc/sysctl.conf
cat>>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward = 1
EOF
    chmod +x /etc/iptables.rc
    /etc/iptables.rc
    sysctl -p
    sed -i "/iptables.rc/d" /etc/rc.local
    sed -i "1a/etc/iptables.rc" /etc/rc.local
    service pptpd restart
    chkconfig pptpd on
}
xl2tp_ipsec() {
    rpm -Uvh http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-8.noarch.rpm
    yum install -y openswan xl2tpd || exit 1
ip=${NETWORKIP}
while [ "${psk}" = "" ]
do
    read -p "Please input the IPSec PSK:" psk
    if [ "${psk}" == "" ];then
        echo "Invalid IPSec PSK."
    else
        break
    fi
done
cat>/etc/xl2tpd/xl2tpd.conf<<EOF
[global]
ipsec saref = yes

[lns default]
ip range = 10.1.2.2-10.1.2.255
local ip = 10.1.2.1
;require chap = yes
refuse chap = yes
refuse pap = yes
require authentication = yes
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

cat>/etc/ipsec.secrets<<EOF
include /etc/ipsec.d/*.secrets
${ip} %any  0.0.0.0: PSK "${psk}"
EOF

cat>/etc/ipsec.conf<<EOF
version 2.0     # conforms to second version of ipsec.conf specification

config setup
        nat_traversal=yes
        virtual_private=%v4:192.168.0.0/16,%v4:10.0.0.0/8,%v4:172.16.0.0/12,%v4:25.0.0.0/8,%v4:!10.254.253.0/24
        protostack=netkey
        #protostack=mast  # used for SAref + MAST only
        interfaces="%defaultroute"
        oe=off

conn l2tp-psk
        authby=secret
        pfs=no
        auto=add
        rekey=no
        # overlapip=yes   # for SAref + MAST
        # sareftrack=yes  # for SAref + MAST
        type=transport
        left=${ip}
        leftprotoport=17/1701
        #
        # The remote user.
        #
        right=%any
        rightprotoport=17/%any
        rightsubnet=vhost:%priv,%no
EOF

cat>/etc/ppp/options.xl2tpd<<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1200
mru 1200
nodefaultroute
debug
lock
proxyarp
connect-delay 5000
EOF

sed -r -i "/net\.ipv4\.ip_forward|net\.ipv4\.conf\.default\.rp_filter|net\.ipv4\.conf\.default\.accept_source_route|net\.ipv4\.conf\.all\.send_redirects|net\.ipv4\.conf\.default\.send_redirects|net\.ipv4\.icmp_ignore_bogus_error_responses/d" /etc/sysctl.conf
cat>>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
    if [ "${FREERADIOUSCLIENT}" == "1" ];then
    sed -i -e "/radius.so/d" -e "/radattr.so/d" /etc/ppp/options.xl2tpd
cat>>/etc/ppp/options.xl2tpd<<EOF
plugin /usr/${LIBDIR}/pppd/2.4.5/radius.so
plugin /usr/${LIBDIR}/pppd/2.4.5/radattr.so
EOF
    fi
sysctl -p
cat>/etc/iptables.rc<<EOF
iptables -t nat -I POSTROUTING -s 1.2.3.0/24 -j SNAT --to $NETWORKIP
iptables -t nat -I POSTROUTING -s 10.1.2.0/24 -j SNAT --to $NETWORKIP
EOF
    chmod +x /etc/iptables.rc
    /etc/iptables.rc
    sed -i "/iptables.rc/d" /etc/rc.local
    sed -i "1a/etc/iptables.rc" /etc/rc.local
    service ipsec restart
    service xl2tpd restart
    chkconfig ipsec on
    chkconfig xl2tpd on
}
fi

for VARNAME in FREERADIUSSERVER POPTOPSERVER xl2tp_ipsec
do
  if [ "$(echo $(eval echo \$$VARNAME))" = "1" ];then
    INFORMATION_$VARNAME
  fi
done

for VARNAME in FREERADIUSSERVER FREERADIOUSCLIENT POPTOPSERVER xl2tp_ipsec
do
  if [ "$(echo $(eval echo \$$VARNAME))" = "1" ];then
    $VARNAME
  fi
done

echo "Enjoy it now."