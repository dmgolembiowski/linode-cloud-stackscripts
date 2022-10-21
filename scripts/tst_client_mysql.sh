# linode/tst_client_mysql.sh by perconalab
# id: 427130
# description: [PUBLIC] Client for Standard MySQL Only Test
# defined fields: name-hostname-label-the-hostname-for-the-new-linode-name-pmmserver-label-the-iphost-name-of-pmm-server-to-use-name-pmmpassword-label-admin-user-password-for-pmm-server-name-db1-label-the-iphost-name-of-db1-to-use-name-db2-label-the-iphost-name-of-db2-to-use-name-db3-label-the-iphost-name-of-db3to-use-name-db4-label-the-iphost-name-of-db4-to-use
# images: ['linode/ubuntu18.04', 'linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 119
#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
#
#<UDF name="hostname" label="The hostname for the new Linode.">
# HOSTNAME=
#<UDF name="pmmserver" label="The IP/Host Name of PMM Server to use.">
# PMMSERVER=
#<UDF name="pmmpassword" label="Admin User Password for PMM Server">
# PMMPASSWORD=
#<UDF name="db1" label="The IP/Host Name of DB1 to use ">
# DB1=
#<UDF name="db2" label="The IP/Host Name of DB2 to use ">
# DB2=
#<UDF name="db3" label="The IP/Host Name of DB3to use ">
# DB3=
#<UDF name="db4" label="The IP/Host Name of DB4 to use ">
# DB4=
#

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)
# This section sets the hostname.
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname

# Extra dependency
apt -y install gnupg2

#Percona 
cd /tmp/
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
percona-release setup ps80
DEBIAN_FRONTEND=noninteractive apt-get -y install sysbench sysbench-tpcc bc screen 

#Install PMM-Client 
percona-release enable original
apt-get update
apt-get install pmm2-client

# Add Node to PMM Server
pmm-admin config --force --server-insecure-tls --server-url=https://admin:$PMMPASSWORD@$PMMSERVER --node-model=linode$LINODE_RAM --region=datacenter$LINODE_DATACENTERID --az=myaz    

# Set up process exporter 
wget https://github.com/ncabatoff/process-exporter/releases/download/v0.7.5/process-exporter_0.7.5_linux_amd64.deb
dpkg -i process-exporter_0.7.5_linux_amd64.deb
service process-exporter start
pmm-admin add external --group=processes  --listen-port=9256

#client3 is special we make it so send more queries to DB1 and DB2 (as others are already loaded and may not be able to parse log)

RATE=100
if [ "$HOSTNAME" == "client3" ]; then
 RATE=300
fi


# Clients for DB1

for i in `seq 1 5`;
do
  j=1
  if [ $(( $i % 2)) -eq 0 ]; then j=2 ; fi
  while true; do sysbench /usr/share/sysbench/tpcc.lua --rate=1 --db-driver=mysql --mysql-host=$DB1 --mysql-user=app$j --mysql-password=passwd$j --mysql-db=tpcc$i --percentile=99 --time=0 --threads=4 --report-interval=10 --tables=1 --scale=1 --enable_purge=yes --use_fk=0 run >> DB1_tpcc$i ;  sleep 60; done  &
done


while true; do /usr/share/sysbench/oltp_point_select.lua  --rate=$RATE --db-driver=mysql  --mysql-host=$DB1 --mysql-user=app3 --mysql-password=passwd3 --mysql-db=sbtest --percentile=99 --time=0 --threads=10 --report-interval=10 --tables=1 --table_size=1000000 --rand-type=uniform run  >> DB1_sysbench ;  sleep 60; done  &


# Clients for DB2 

for i in `seq 1 5`;
do
  j=1
  if [ $(( $i % 2)) -eq 0 ]; then j=2 ; fi
  while true; do sysbench /usr/share/sysbench/tpcc.lua --rate=1 --db-driver=mysql --mysql-host=$DB2 --mysql-user=app$j --mysql-password=passwd$j --mysql-db=tpcc$i --percentile=99 --time=0 --threads=4 --report-interval=10 --tables=1 --scale=1 --enable_purge=yes --use_fk=0 run >> DB2_tpcc$i ;  sleep 60; done  &
done

while true; do /usr/share/sysbench/oltp_point_select.lua  --rate=$RATE --db-driver=mysql  --mysql-host=$DB2 --mysql-user=app3 --mysql-password=passwd3 --mysql-db=sbtest --percentile=99 --time=0 --threads=10 --report-interval=10 --tables=1 --table_size=1000000 --rand-type=uniform run  >> DB2_sysbench ;  sleep 60; done  &

# Clients for DB3 

for i in `seq 1 5`;
do
  j=1
  if [ $(( $i % 2)) -eq 0 ]; then j=2 ; fi
  while true; do sysbench /usr/share/sysbench/tpcc.lua --rate=1 --db-driver=mysql --mysql-host=$DB3 --mysql-user=app$j --mysql-password=passwd$j --mysql-db=tpcc$i --percentile=99 --time=0 --threads=4 --report-interval=10 --tables=1 --scale=1 --enable_purge=yes --use_fk=0 run >> DB3_tpcc$i ;  sleep 60; done  &
done

# Do not Do Sysbench
# while true; do /usr/share/sysbench/oltp_point_select.lua  --rate=100 --db-driver=mysql  --mysql-host=$DB3 --mysql-user=app3 --mysql-password=passwd3 --mysql-db=sbtest --percentile=99 --time=0 --threads=10 --report-interval=10 --tables=1 --table_size=1000000 --rand-type=uniform run  >> DB3_sysbench ;  sleep 60; done  &

# Clients for DB4 

for i in `seq 1 5`;
do
  j=1
  if [ $(( $i % 2)) -eq 0 ]; then j=2 ; fi
  while true; do sysbench /usr/share/sysbench/tpcc.lua --rate=1 --db-driver=mysql --mysql-host=$DB4 --mysql-user=app$j --mysql-password=passwd$j --mysql-db=tpcc$i --percentile=99 --time=0 --threads=4 --report-interval=10 --tables=1 --scale=1 --enable_purge=yes --use_fk=0 run >> DB4_tpcc$i ;  sleep 60; done  &
done

# Do not do Sysbench
# while true; do /usr/share/sysbench/oltp_point_select.lua  --rate=100 --db-driver=mysql  --mysql-host=$DB4 --mysql-user=app3 --mysql-password=passwd3 --mysql-db=sbtest --percentile=99 --time=0 --threads=10 --report-interval=10 --tables=1 --table_size=1000000 --rand-type=uniform run  >> DB4_sysbench ;  sleep 60; done  &
