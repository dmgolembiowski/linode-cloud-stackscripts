# linode/benchmark-and-thrash-test.sh by displague
# id: 37497
# description: Have you ever wanted to burn your Linode into the ground?  This Stackscript asks for your GitHub username (to configure SSH auth) and then configures your Debian based Linode for self-destruct.

Watch the screen session in glish, that's where the magic happens.

This StackScript is guaranteed to trigger a system error or get Linode Support on your tail for a Terms of Service violation.

Use at your own risk.

See Also: 

* https://www.linode.com/stackscripts/view/10079-displague-Rootless+and+GitHub+User+has+sudo
# defined fields: name-gh_username-label-github-username-example-github-user-account-to-create-with-sudo-access
# images: ['linode/debian8', 'linode/debian9', 'linode/ubuntu16.04lts', 'linode/ubuntu17.04', 'linode/debian7', 'linode/ubuntu14.04lts']
# stats: Used By: 0 + AllTime: 95
#!/bin/bash
# <UDF name="gh_username" Label="GitHub Username" example="GitHub User account to create with sudo access" />
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=10079>

export MYSQL_PW=$(mktemp tmp.XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)
cat > ~/.screenrc <<EOF
shell "/bin/bash"
startup_message off

screen -t htop
select $((++i))
stuff "htop ^M"

screen -t iotop
select $((++i))
stuff "iotop ^M"

screen -t iostat
select $((++i))
stuff "iostat 1 ^M"

screen -t disk
select $((++i))
stuff "while sleep 10; do sysbench --test=oltp --oltp-table-size=1000000 --mysql-db=test --mysql-user=root --mysql-password=$MYSQL_PW --max-time=60 --oltp-read-only=on --max-requests=0 --num-threads=24 prepare; sysbench --test=oltp --oltp-table-size=1000000 --mysql-db=test --mysql-user=root --mysql-password=$MYSQL_PW --max-time=60 --oltp-read-only=on --max-requests=0 --num-threads=24 run; sysbench --test=oltp --oltp-table-size=1000000 --mysql-db=test --mysql-user=root --mysql-password=$MYSQL_PW --max-time=60 --oltp-read-only=on --max-requests=0 --num-threads=24 stop; done^M"

screen -t cpu
select $((++i))
stuff "while sleep 10; do sysbench --test=cpu --cpu-max-prime=200000 run; done^M"

screen -t disk
select $((++i))
stuff "while sleep 10; do sysbench --test=fileio --file-total-size=10G prepare; sysbench --test=fileio --file-total-size=10G --file-test-mode=rndrw --init-rng=on --max-time=300 --max-requests=0 run; sysbench --test=fileio --file-total-size=10G cleanup; done^M"

screen -t mem
select $((++i))
stuff "while sleep 10; do sysbench --test=memory --num-threads=48 --max-requests=20000 run; done^M"

screen -t mutex
select $((++i))
stuff "while sleep 10; do sysbench --test=mutex --num-threads=1000 run; done^M"

screen -t threads
select $((++i))
stuff "while sleep 10; do sysbench --test=threads --num-threads=1000 --thread-locks=1 --max-time=60s run; done^M"

select 0
altscreen on
term screen-256color
bind ',' prev
bind '.' next
EOF

debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_PW"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_PW"

export DEBIAN_FRONTEND=noninteractive
echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
apt-get update
apt-get install --reinstall -y sysbench mysql-server kbd htop sysstat iotop
mysql --password="$MYSQL_PW" -e 'create schema if not exists test;'
echo "You'll want to look in glish now"
openvt -s screen -- -q