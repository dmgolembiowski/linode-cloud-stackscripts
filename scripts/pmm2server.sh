# linode/pmm2server.sh by perconalab
# id: 625153
# description: PMM2 Server Deployment [PUBLIC]
# defined fields: name-hostname-label-the-hostname-for-the-new-linode-name-pmmimage-label-docker-image-for-pmm-server-to-use-name-pmmpassword-label-admin-user-password-for-pmm-server
# images: ['linode/ubuntu18.04', 'linode/ubuntu20.04']
# stats: Used By: 1 + AllTime: 85
#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
#
#<UDF name="hostname" label="The hostname for the new Linode.">
# HOSTNAME=
#<UDF name="pmmimage" label="Docker Image for PMM Server to use ">
# PMMIMAGE=
#<UDF name="pmmpassword" label="Admin User Password for PMM Server">
# PMMPASSWORD=

# Added logging for debug purposes
exec >  >(tee -a /root/stackscript.log)
exec 2> >(tee -a /root/stackscript.log >&2)

# Kernel Tune
# Leaving it at Default for Now.  As Prometheus uses mmap() it works very poorly when file cache is aggressively shrunk.
# echo 1 > /proc/sys/vm/swappiness

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

# Docker
apt update
apt -y install docker.io
systemctl enable docker.service

#PMM 
echo will deploy PMM Server  from $PMMIMAGE

docker create -v /srv --name pmm2-data $PMMIMAGE /bin/true
docker run -d -p 80:80 -p 443:443 --volumes-from pmm2-data --name pmm2-server  --restart always $PMMIMAGE

echo "Waiting for PMM to initialize to set password..."

until [ "`docker inspect -f {{.State.Health.Status}} pmm2-server`" = "healthy" ]; do sleep 1; done

echo Setting PMM Admin Password to $PMMPASSWORD

docker exec -t pmm2-server bash -c "grafana-cli --homepath /usr/share/grafana --configOverrides cfg:default.paths.data=/srv/grafana admin reset-admin-password $PMMPASSWORD"

echo "StackScript Finished!"

#