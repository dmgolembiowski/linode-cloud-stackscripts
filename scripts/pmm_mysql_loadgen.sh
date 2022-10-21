# linode/pmm_mysql_loadgen.sh by perconalab
# id: 572208
# description: [PUBLIC] Install Specified version of MySQL (or Alternative) and run Benchmark, while connecting to specified PMM Server  
# defined fields: name-hostname-label-the-hostname-for-the-new-linode-name-pmmserver-label-the-iphost-name-of-pmm-server-to-use-name-pmmpassword-label-admin-user-password-for-pmm-server-name-mysql-label-mysql-to-install-ps8-ps57-ps56-default-ps8-name-benchmark-label-benchmark-to-run-sysbenc-tpcc-etc-default-tpcc-name-tables-label-tables-for-benchmark-default-1-name-tpccscale-label-scale-for-each-table-in-tpcc-benchmark-distinct-queries-for-stq-default-1-name-sysbenchrows-label-number-of-rows-per-table-for-sysbench-default-1000000-name-threads-label-number-of-threads-for-benchmark-schemas-for-stq-default-1-name-rate-label-injection-rate-for-benchmark-default-10-name-testtime-label-time-to-run-test-between-database-resets-default-86400-name-querysource-label-pmm-data-source-slowlog-or-perfschema-default-slowlog
# images: ['linode/ubuntu18.04']
# stats: Used By: 0 + AllTime: 81
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
#<UDF name="mysql" label="MySQL To Install  ps8, ps57, ps56" default="ps8">
# MYSQL=
#<UDF name="benchmark" label="Benchmark To Run  sysbenc, tpcc, etc" default="tpcc">
# BENCHMARK=
#<UDF name="tables" label="Tables for Benchmark" default="1">
# TABLES=
#<UDF name="tpccscale" label="Scale for Each Table in TPCC Benchmark  (Distinct Queries for STQ) " default="1">
# TPCCSCALE=
#<UDF name="sysbenchrows" label="Number of Rows Per Table for Sysbench" default="1000000">
# SYSBENCHROWS=
#<UDF name="threads" label="Number of Threads for Benchmark (Schemas for STQ)" default="1">
# THREADS=
#<UDF name="rate" label="Injection Rate for Benchmark" default="10">
# RATE=
#<UDF name="testtime" label="Time to run test between Database Resets " default="86400">
# TESTTIME=
#<UDF name="querysource" label="PMM Data Source (slowlog or perfschema) " default="slowlog">
# QUERYSOURCE=


# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

#Set Defaults
if [ -z "$MYSQL" ]; then MYSQL="ps8"; fi
if [ -z "$BENCHMARK" ]; then BENCHMARK="tpcc"; fi
if [ -z "$TABLES" ]; then TABLES="1"; fi
if [ -z "$TPCCSCALE" ]; then TPCCSCALE="1"; fi
if [ -z "$SYSBENCHROWS" ]; then SYSBENCHROWS="1000000"; fi
if [ -z "$THREADS" ]; then THREADS="1"; fi
if [ -z "$RATE" ]; then RATE="10"; fi
if [ -z "$TESTTIME" ]; then TESTTIME="86400"; fi
if [ -z "$QUERYSOURCE" ]; then QUERYSOURCE="slowlog"; fi

echo  Installation Configuration Details
echo  MySQL=$MYSQL
echo  PMMSERVER=$PMMSERVER
echo  BENCHMARK=$BENCHMARK
echo  TABLES=$TABLES
echo  TPCCSCALE=$TPCCSCALE
echo  SYSBENCHROWS=$SYSBENCHROWS
echo  THREADS=$THREADS
echo  RATE=$RATE
echo  TESTTIME=$TESTTIME
echo  QUERYSOURCE=$QUERYSOURCE

echo "Linode Variable Values:  LINODE_ID: $LINODE_ID,  LINODE_LISHUSERNAME: $LINODE_LISHUSERNAME,  LINODE_RAM: $LINODE_RAM,  LINODE_DATACENTERID:$LINODE_DATACENTERID"

# Kernel Tune
echo 1 > /proc/sys/vm/swappiness

# Create SWAP File as 
fallocate -l $LINODE_RAM\M /swapfile
let BLOCK_COUNT=$LINODE_RAM*1024
dd if=/dev/zero of=/swapfile bs=1024 count=$BLOCK_COUNT
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# This section sets the hostname.
echo $HOSTNAME > /etc/hostname
hostname -F /etc/hostname

# Extra dependency
apt -y install gnupg2

# Install Percona Repository Which will be at least used for PMM 
cd /tmp/
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb


#INSTALL MYSQL VERSION

#PERCONA


if [ "$MYSQL" == "ps8" ]; then
percona-release setup ps80
DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server sysbench sysbench-tpcc bc screen 
cat > /etc/mysql/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size=256M
innodb_buffer_pool_instances=1
innodb_log_file_size=1G
innodb_flush_method=O_DIRECT
innodb_numa_interleave=1
innodb_flush_neighbors=0
log_bin
server_id=1
binlog_expire_logs_seconds=600
log_output=file
slow_query_log=ON
long_query_time=0
log_slow_rate_limit=1
log_slow_rate_type=query
log_slow_verbosity=full
log_slow_admin_statements=ON
log_slow_slave_statements=ON
slow_query_log_always_write_time=1
slow_query_log_use_global_control=all
innodb_monitor_enable=all
userstat=1
EOF
fi

if [ "$MYSQL" == "ps57" ]; then
percona-release setup ps57
DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server-5.7 sysbench sysbench-tpcc bc screen 
cat > /etc/mysql/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size=256M
innodb_buffer_pool_instances=1
innodb_log_file_size=1G
innodb_flush_method=O_DIRECT
innodb_numa_interleave=1
innodb_flush_neighbors=0
log_bin
server_id=1
expire_logs_days=1
log_output=file
slow_query_log=ON
long_query_time=0
log_slow_rate_limit=1
log_slow_rate_type=query
log_slow_verbosity=full
log_slow_admin_statements=ON
log_slow_slave_statements=ON
slow_query_log_always_write_time=1
slow_query_log_use_global_control=all
innodb_monitor_enable=all
userstat=1
EOF
fi

if [ "$MYSQL" == "ps56" ]; then
percona-release setup ps56
DEBIAN_FRONTEND=noninteractive apt-get -y install percona-server-server-5.6 sysbench sysbench-tpcc bc screen 
cat > /etc/mysql/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size=256M
innodb_buffer_pool_instances=1
innodb_log_file_size=1G
innodb_flush_method=O_DIRECT
innodb_numa_interleave=1
innodb_flush_neighbors=0
log_bin
server_id=1
expire_logs_days=1
log_output=file
slow_query_log=ON
long_query_time=0
log_slow_rate_limit=1
log_slow_rate_type=query
log_slow_verbosity=full
log_slow_admin_statements=ON
log_slow_slave_statements=ON
slow_query_log_always_write_time=1
slow_query_log_use_global_control=all
innodb_monitor_enable=all
userstat=1
EOF
fi

# MARIADB 


if [ "$MYSQL" == "mdb104" ]; then
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
apt update
DEBIAN_FRONTEND=noninteractive  apt -y install mariadb-server mariadb-client

cat > /etc/mysql/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size=256M
innodb_buffer_pool_instances=1
innodb_log_file_size=1G
innodb_flush_method=O_DIRECT
# innodb_numa_interleave=1
innodb_flush_neighbors=0
log_bin
server_id=1
expire_logs_days=1
log_output=file
slow_query_log=ON
long_query_time=0
log_slow_rate_limit=1
# log_slow_rate_type=query
# log_slow_verbosity=full
log_slow_verbosity=query_plan
log_slow_admin_statements=ON
log_slow_slave_statements=ON
# slow_query_log_always_write_time=1
# slow_query_log_use_global_control=all
innodb_monitor_enable=all
userstat=1
EOF
fi


# Restart installed MySQL Server to apply new config 
service mysql restart 

# PMM Will only Rotate logs if It uses log as data source. We may use performance schema in which case enabled log will cause out of space condition
# Set up Poor Man's log rotate 
cat > /etc/cron.d/pmm-rotate  << EOF
*/11 * * * *  root  rm /var/lib/mysql/*-slow.log;  mysql -e "flush slow logs"
EOF


#Install PMM-Client 
sudo percona-release enable original 
apt-get update
apt-get install pmm2-client

# Configure Add MySQL to PMM 
pmm-admin config --force --server-insecure-tls --server-url=https://admin:$PMMPASSWORD@$PMMSERVER --node-model=linode$LINODE_RAM --region=datacenter$LINODE_DATACENTERID --az=myaz    
mysql -e "create user pmm@localhost identified by \"pmm\""
mysql -e "grant all on *.* to pmm@localhost"
pmm-admin add mysql --query-source=$QUERYSOURCE --username=pmm --password=pmm --environment=versions


#TPCC BENCHMARK

if [ "$BENCHMARK" == "tpcc" ]; then
while true
do
mysqladmin create tpcc
/usr/share/sysbench/tpcc.lua   --db-driver=mysql --db-ps-mode=disable  --mysql-user=root --mysql-db=tpcc --percentile=99 --time=0 --threads=1 --report-interval=10 --tables=$TABLES --scale=$TPCCSCALE  --use_fk=0 prepare   
sleep 300
sysbench /usr/share/sysbench/tpcc.lua --rate=$RATE  --db-driver=mysql  --db-ps-mode=disable --mysql-user=root --mysql-password=  --mysql-db=tpcc --percentile=99 --time=$TESTTIME --threads=$THREADS --report-interval=10 --tables=$TABLES --scale=$TPCCSCALE --use_fk=0 run
/usr/share/sysbench/tpcc.lua   --db-driver=mysql --db-ps-mode=disable --mysql-user=root --mysql-db=tpcc --percentile=99 --time=0 --threads=1 --report-interval=10 --tables=$TABLES --scale=$TPCCSCALE  --use_fk=0 cleanup
mysql -e "DROP DATABASE tpcc"
sleep 600
done
fi

# Schema-Table-Query script
if [ "$BENCHMARK" == "stq" ]; then
apt -y install  git php php-mysql
git clone https://github.com/Percona-Lab/pmm-workloads

#reuse some values but make sure defaults do not become insane
export TEST_TABLES=$TABLES
export TEST_TARGET_QPS=$RATE
export TEST_QUERIES=$TPCCSCALE
export TEST_SCHEMAS=$THREADS

cd pmm-workloads/mysql

#if errors happen do it again

while true
do
php schema_table_query.php
sleep 60
done

fi

echo Stackscript Finished!