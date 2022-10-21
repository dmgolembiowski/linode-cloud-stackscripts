# linode/percona-pmm-one-click.sh by linode
# id: 644908
# description: Percona One-Click
# defined fields: name-pmmpassword-label-admin-password-example-admin-user-password-for-pmm-server
# images: ['linode/debian10']
# stats: Used By: 14 + AllTime: 134
#!/bin/bash
# <UDF name="pmmpassword" label="Admin Password" example="Admin User Password for PMM Server"/>

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Docker
apt -y install docker.io
systemctl enable docker.service

#PMM 
docker pull percona/pmm-server:2
docker create -v /srv --name pmm2-data percona/pmm-server:2 /bin/true
docker run -d -p 80:80 -p 443:443 \
   --volumes-from pmm2-data \
   --name pmm2-server \
   --restart always percona/pmm-server:2

echo "Waiting for PMM to initialize to set password..."

until [ "`docker inspect -f {{.State.Health.Status}} pmm2-server`" = "healthy" ]; do sleep 1; done

docker exec -t pmm2-server bash -c  "ln -s /srv/grafana /usr/share/grafana/data; grafana-cli --homepath /usr/share/grafana admin reset-admin-password $PMMPASSWORD"

# Cleanup
stackscript_cleanup