# linode/lemp-stack.sh by joeswhite
# id: 8401
# description: LEMP Stack from webandblog (stack script 360) rebuilt with archived/salvaged copy of LEMP_lib (stack script 41)

LEMP Stack description from webandblog:

Installs LEMP + basic security + user security. No root acct. Use sudo -s to get root permissions. For PHP-FPM setup change nginx setting to access PHP via socket not port: 

location ~ \.php$ {
if (!-f $request_filename) {
return 404;
}
fastcgi_pass unix:/var/run/php-fpm.sock;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
fastcgi_param PATH_INFO $fastcgi_path_info;
fastcgi_intercept_errors on;
include /etc/nginx/fastcgi_params;
}
# defined fields: name-db_password-label-mysql-root-password-name-nginx_prefix-label-nginx-prefix-default-usrlocalnginx-name-nginx_sbin_path-label-nginx-sbin-path-default-usrlocalnginxsbinnginx-name-nginx_conf_path-label-nginx-conf-path-default-usrlocalnginxconfnginxconf-name-nginx_pid_path-label-nginx-pid-path-default-usrlocalnginxlogsnginxpid-example-can-be-specified-in-nginxconf-name-nginx_error_log_path-label-nginx-error-log-path-default-usrlocalnginxlogserrorlog-example-can-be-specified-in-nginxconf-name-nginx_http_log_path-label-nginx-http-log-path-default-usrlocalnginxlogsaccesslog-example-can-be-specified-in-nginxconf-name-nginx_user-label-nginx-user-default-www-data-example-can-be-specified-in-nginxconf-name-nginx_group-label-nginx-group-default-www-data-example-can-be-specified-in-nginxconf-name-logro_freq-label-nginx-log-rotation-frequency-default-monthly-name-logro_rota-label-nginx-number-of-log-rotations-to-keep-default-12-name-allow-label-allowed-services-example-punch-holes-in-the-firewall-for-these-services-ssh-is-already-open-see-restrict-ssh-default-manyof-ftp-server-tcp-21telnet-tcp-23smtp-tcp-25dns-server-tcpudp-53web-server-tcp-80pop3-mail-service-tcp-110ntp-service-udp-123imap-mail-service-tcp-143ssl-web-server-tcp-443mail-submission-tcp-587ssl-imap-server-tcp-993openvpn-server-udp-1194irc-server-tcp-6667-name-extrat-label-extra-tcp-holes-example-extra-holes-in-the-firewall-for-tcp-understands-service-names-kerberos-and-port-numbers-31337-separate-by-spaces-default-name-extrau-label-extra-udp-holes-example-extra-holes-in-the-firewall-for-udp-understands-service-names-daytime-and-port-numbers-1094-separate-by-spaces-default-name-sshrange-label-restrict-ssh-example-will-restrict-ssh-access-to-the-given-cidr-range-leave-empty-for-no-restrictions-default-00-name-icmplevel-label-icmp-paranoia-level-example-rules-for-icmp-you-should-leave-this-at-the-default-to-be-a-good-net-citizen-oneof-well-behavedonly-allow-pingsignore-all-icmp-default-none-name-loglevel-label-logging-level-example-how-much-to-log-this-can-generate-a-lot-of-output-oneof-nothingsome-stuffeverything-default-nothing-name-user_name-label-unprivileged-user-account-name-user_password-label-unprivileged-user-password-name-user_sshkey-label-public-key-for-user-default-name-sshd_port-label-ssh-port-default-22-name-sshd_protocol-label-ssh-protocol-oneof-121-and-2-default-2-name-sshd_permitroot-label-ssh-permit-root-login-oneof-noyes-default-no-name-sshd_passwordauth-label-ssh-password-authentication-oneof-noyes-default-yes-name-sshd_group-label-ssh-allowed-groups-default-sshusers-example-list-of-groups-seperated-by-spaces-name-sudo_usergroup-label-usergroup-to-use-for-admin-accounts-default-wheel-name-sudo_passwordless-label-passwordless-sudo-oneof-require-passworddo-not-require-password-default-require-password
# images: ['linode/ubuntu14.04lts', 'linode/ubuntu15.04']
# stats: Used By: 0 + AllTime: 72
#!/bin/bash
#yu di efs
# <UDF name="DB_PASSWORD"		Label="MySQL root Password" />
# <UDF name="NGINX_PREFIX"		Label="nginx: prefix" 		default="/usr/local/nginx" />
# <UDF name="NGINX_SBIN_PATH"		Label="nginx: sbin-path" 	default="/usr/local/nginx/sbin/nginx" />
# <UDF name="NGINX_CONF_PATH"		Label="nginx: conf-path" 	default="/usr/local/nginx/conf/nginx.conf" />
# <UDF name="NGINX_PID_PATH"		Label="nginx: pid-path" 	default="/usr/local/nginx/logs/nginx.pid"	example="Can be specified in nginx.conf" />
# <UDF name="NGINX_ERROR_LOG_PATH"	Label="nginx: error-log-path"	default="/usr/local/nginx/logs/error.log"	example="Can be specified in nginx.conf" />
# <UDF name="NGINX_HTTP_LOG_PATH"	Label="nginx: http-log-path" 	default="/usr/local/nginx/logs/access.log"	example="Can be specified in nginx.conf" />
# <UDF name="NGINX_USER"		Label="nginx: user" 		default="www-data"				example="Can be specified in nginx.conf" />
# <UDF name="NGINX_GROUP"		Label="nginx: group" 		default="www-data"				example="Can be specified in nginx.conf" />
# <UDF name="LOGRO_FREQ"		Label="nginx: log rotation frequency" default="monthly" />
# <UDF name="LOGRO_ROTA"		Label="nginx: number of log rotations to keep" default="12" />
# Basic Security StackScript
# By Jed Smith <jed@linode.com>
#
# <UDF name="allow" label="Allowed services" example="Punch holes in the firewall for these services. SSH is already open (see Restrict SSH)." default="" manyOf="FTP Server: TCP 21,Telnet: TCP 23,SMTP: TCP 25,DNS Server: TCP/UDP 53,Web Server: TCP 80,POP3 Mail Service: TCP 110,NTP Service: UDP 123,IMAP Mail Service: TCP 143,SSL Web Server: TCP 443,Mail Submission: TCP 587,SSL IMAP Server: TCP 993,OpenVPN Server: UDP 1194,IRC Server: TCP 6667">
# <UDF name="extraT" label="Extra TCP holes" example="Extra holes in the firewall for TCP. Understands service names ('kerberos') and port numbers ('31337'), separate by spaces." default="">
# <UDF name="extraU" label="Extra UDP holes" example="Extra holes in the firewall for UDP. Understands service names ('daytime') and port numbers ('1094'), separate by spaces." default="">
# <UDF name="sshrange" label="Restrict SSH" example="Will restrict SSH access to the given CIDR range. Leave empty for no restrictions." default="0/0">
# <UDF name="icmplevel" label="ICMP paranoia level" example="Rules for ICMP. You should leave this at the default to be a good net citizen." oneOf="Well-behaved,Only allow pings,Ignore all ICMP" default="None">
# <UDF name="loglevel" label="Logging level" example="How much to log. This can generate a lot of output." oneOf="Nothing,Some stuff,Everything" default="Nothing">
#

# Security StackScript
# By Donald von Stufft <donald.stufft@gmail.com>
#
# <udf name="user_name" label="Unprivileged User Account" />
# <udf name="user_password" label="Unprivileged User Password" />
# <udf name="user_sshkey" label="Public Key for User" default="" />
#
# <udf name="sshd_port" label="SSH Port" default="22" />
# <udf name="sshd_protocol" label="SSH Protocol" oneOf="1,2,1 and 2" default="2" />
# <udf name="sshd_permitroot" label="SSH Permit Root Login" oneof="No,Yes" default="No" />
# <udf name="sshd_passwordauth" label="SSH Password Authentication" oneOf="No,Yes" default="Yes" />
# <udf name="sshd_group" label="SSH Allowed Groups" default="sshusers" example="List of groups seperated by spaces" />
#
# <udf name="sudo_usergroup" label="Usergroup to use for Admin Accounts" default="wheel" />
# <udf name="sudo_passwordless" label="Passwordless Sudo" oneof="Require Password,Do Not Require Password", default="Require Password" />

#using postfix and restartServices stuff from Linode's StackScript Bash Library

#scripts used
source <ssinclude StackScriptID="1">		#StackScript Bash Library
source <ssinclude StackScriptID="8402">		#LEMP_lib
lemp_system_update_aptitude			#StackScriptID="8402"
lemp_mysql_install		 		#StackScriptID="8402"
postfix_install_loopback_only			#StackScriptID="1"
lemp_php-fpm					#StackScriptID="8402"
lemp_nginx					#StackScriptID="8402"
restartServices					#StackScriptID="1"

IFUP=/etc/network/if-up.d/iptables.sh
IFDOWN=/etc/network/if-down.d/iptables.sh
IPTABLES() {
    echo iptables $@ >&1 2>&1
    iptables $@
}

# Make sure we have iptables, and do this business while we're at it
echo Updating system and installing iptables.
aptitude -y install iptables

echo
echo ===========================================================================
echo Configuring iptables firewall.

# Set up scripts to load/unload the rules at ifup/ifdown
echo Generating store/restore scripts.
for i in $IFUP $IFDOWN; do
    echo $i
    touch $i && chmod 744 $i
    echo >$i "#!/bin/bash"
    echo >>$i "# Generated by iptables StackScript"
    echo >>$i
done
echo >>$IFUP "iptables-restore < /etc/firewall.conf"
echo >>$IFDOWN "iptables-save > /etc/firewall.conf"

# Fix sysctl so this will not log to console
# The distro-default kernel printk is commented out, so we cheat and add
echo Changing kernel.printk in the kernel.
echo "3 1 1 1" > /proc/sys/kernel/printk
echo Modifying /etc/sysctl.conf.
echo >>/etc/sysctl.conf
echo "# Added by iptables StackScript, to not log iptables information to console" >>/etc/sysctl.conf
echo 'kernel.printk = "3 1 1 1"' >>/etc/sysctl.conf

# Build iptables
echo Building iptables rules.
for i in INPUT OUTPUT; do IPTABLES -P $i ACCEPT && IPTABLES -F $i; done
IPTABLES -P FORWARD DROP && IPTABLES -F FORWARD
for i in DROP1 DROP2 TCP UDP; do
    IPTABLES -F $i >/dev/null 2>/dev/null
    IPTABLES -X $i >/dev/null 2>/dev/null
    IPTABLES -N $i
done

# Dropper rules based on selected loglevel
# Drop1 is logged if loglevel >= Some Stuff, Drop2 if loglevel = Everything
test "${LOGLEVEL}" == "Everything" && (for i in DROP1 DROP2; do IPTABLES -A $i -j LOG --log-level notice --log-prefix "iptables: "; done)
test "${LOGLEVEL}" == "Some stuff" && (IPTABLES -A DROP1 -j LOG --log-level notice --log-prefix "iptables: ")
for i in DROP1 DROP2; do IPTABLES -A $i -j DROP; done

# Preamble
IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
IPTABLES -A INPUT -m state --state INVALID -j DROP1
IPTABLES -A INPUT -i lo -j ACCEPT
IPTABLES -A INPUT -p tcp -j TCP
IPTABLES -A INPUT -p udp -j UDP

# ICMP
echo Configuring ICMP behavior.
test "${ICMPLEVEL}" == "Well-behaved" && (IPTABLES -A INPUT -p icmp -j ACCEPT)
test "${ICMPLEVEL}" == "Only allow pings" && (IPTABLES -A INPUT -p icmp --icmp-type echo-request -j ACCEPT)

# Bottom of the input chain -- log?
test "${LOGLEVEL}" == "Everything" && (IPTABLES -A INPUT -j LOG --log-level notice --log-prefix "iptables: ")

# SSH is open by default
if [ -z "$SSHRANGE" ]; then SSHRANGE="0/0"; fi
echo Allowing: SSH from $SSHRANGE
IPTABLES -A TCP -p tcp --dport ssh -s $SSHRANGE -j ACCEPT

# Allowed services
IFS=$','
for service in $ALLOW; do
    echo Allowing: $service
    interested=${service#*: }
    IFS=$' '
    set -- $interested
    for i in TCP UDP; do
        if [[ "$1" == *$i* ]]; then IPTABLES -A $i -p $i --dport $2 -j ACCEPT; fi
    done
done
unset IFS

# Extras
for i in $EXTRAU; do
    echo Allowing: UDP $i
    IPTABLES -A UDP -p UDP --dport $i -j ACCEPT
done
for i in $EXTRAT; do
    echo Allowing: TCP $i
    IPTABLES -A TCP -p TCP --dport $i -j ACCEPT
done

# Lock 'n save
echo Completing.
IPTABLES -P INPUT DROP
iptables-save > /etc/firewall.conf

echo Done.
source <ssinclude StackScriptID="1">

# Update the System
system_update

# Install and Configure Sudo
aptitude -y install sudo

cp /etc/sudoers /etc/sudoers.tmp
chmod 0640 /etc/sudoers.tmp
test "${SUDO_PASSWORDLESS}" == "Do Not Require Password" && (echo "%`echo ${SUDO_USERGROUP} | tr '[:upper:]' '[:lower:]'` ALL = NOPASSWD: ALL" >> /etc/sudoers.tmp)
test "${SUDO_PASSWORDLESS}" == "Require Password" && (echo "%`echo ${SUDO_USERGROUP} | tr '[:upper:]' '[:lower:]'` ALL = (ALL) ALL" >> /etc/sudoers.tmp)
chmod 0440 /etc/sudoers.tmp
mv /etc/sudoers.tmp /etc/sudoers

# Configure SSHD
echo "Port ${SSHD_PORT}" > /etc/ssh/sshd_config.tmp
echo "Protocol ${SSHD_PROTOCOL}" >> /etc/ssh/sshd_config.tmp

sed -n 's/\(HostKey .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(UsePrivilegeSeparation .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(KeyRegenerationInterval .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(ServerKeyBits .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(SyslogFacility .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(LogLevel .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(LoginGraceTime .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
echo "PermitRootLogin `echo ${SSHD_PERMITROOT} | tr '[:upper:]' '[:lower:]'`" >> /etc/ssh/sshd_config.tmp
sed -n 's/\(StrictModes .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(RSAAuthentication .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(PubkeyAuthentication .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(IgnoreRhosts .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(RhostsRSAAuthentication .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(HostbasedAuthentication .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(PermitEmptyPasswords .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(ChallengeResponseAuthentication .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

echo "PasswordAuthentication `echo ${SSHD_PASSWORDAUTH} | tr '[:upper:]' '[:lower:]'`" >> /etc/ssh/sshd_config.tmp

sed -n 's/\(X11Forwarding .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(X11DisplayOffset .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(PrintMotd .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(PrintLastLog .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp
sed -n 's/\(TCPKeepAlive .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(MaxStartups .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(AcceptEnv .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(Subsystem .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

sed -n 's/\(UsePAM .*\)/\1/p' < /etc/ssh/sshd_config >> /etc/ssh/sshd_config.tmp

echo "AllowGroups `echo ${SSHD_GROUP} | tr '[:upper:]' '[:lower:]'`" >> /etc/ssh/sshd_config.tmp

chmod 0600 /etc/ssh/sshd_config.tmp
mv /etc/ssh/sshd_config.tmp /etc/ssh/sshd_config
touch /tmp/restart-ssh

# Create Groups
groupadd ${SSHD_GROUP}
groupadd ${SUDO_USERGROUP}

# Create User & Add SSH Key
USER_NAME_LOWER=`echo ${USER_NAME} | tr '[:upper:]' '[:lower:]'`

useradd -m -s /bin/bash -G ${SSHD_GROUP},${SUDO_USERGROUP} ${USER_NAME_LOWER}
echo "${USER_NAME_LOWER}:${USER_PASSWORD}" | chpasswd

USER_HOME=`sed -n "s/${USER_NAME_LOWER}:x:[0-9]*:[0-9]*:[^:]*:\(.*\):.*/\1/p" < /etc/passwd`

sudo -u ${USER_NAME_LOWER} mkdir ${USER_HOME}/.ssh
echo "${USER_SSHKEY}" >> $USER_HOME/.ssh/authorized_keys
chmod 0600 $USER_HOME/.ssh/authorized_keys
chown ${USER_NAME_LOWER}:${USER_NAME_LOWER} $USER_HOME/.ssh/authorized_keys

# Setup Hostname
get_rdns_primary_ip > /etc/hostname
/etc/init.d/hostname.sh start

echo y|apt-get install zip	
# add eAccelerator to make php fly 
echo y| apt-get install php5-dev
aptitude -y install build-essential
cd /usr/src
wget http://downloads.sourceforge.net/project/eaccelerator/eaccelerator/eAccelerator%200.9.6.1/eaccelerator-0.9.6.1.zip
unzip eaccelerator-0.9.6.1.zip
cd eaccelerator-0.9.6.1
phpize
./configure
make
make install
mkdir /tmp/eaccelerator
chown -R ${USER_NAME_LOWER}:${USER_NAME_LOWER} /tmp/eaccelerator/
echo 'extension="eaccelerator.so"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.shm_size="16"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.cache_dir="/tmp/eaccelerator"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.enable="1"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.optimizer="1"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.check_mtime="1"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.debug="0"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.filter=""' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.shm_max="0"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.shm_ttl="0"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.shm_prune_period="0"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.shm_only="0"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.compress="1"' >> /etc/php5/fpm/php.ini
echo 'eaccelerator.compress_level="9"' >> /etc/php5/fpm/php.ini

# Restart Services
restartServices

#updated by Joseph White https://freicoin.us on March 18th, 2014