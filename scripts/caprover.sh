# linode/caprover.sh by germanllop
# id: 792296
# description: CapRover is an extremely easy to use app/database deployment & web server manager for your NodeJS, Python, PHP, ASP.NET, Ruby, MySQL, MongoDB, Postgres, WordPress (and etc...) applications!

It's blazingly fast and very robust as it uses Docker, nginx, LetsEncrypt and NetData under the hood behind its simple-to-use interface.

Once the CapRover is initialized, you can visit http://[IP_OF_YOUR_SERVER]:3000 in your browser and login to CapRover using the default password captain42.
# defined fields: 
# images: ['linode/debian10', 'linode/ubuntu18.04', 'linode/ubuntu20.04', 'linode/debian9']
# stats: Used By: 4 + AllTime: 76
#!/bin/bash
set -x

apt-get update
apt-get -y upgrade

apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io ufw

ufw allow 80,443,3000,996,7946,4789,2377/tcp; ufw allow 7946,4789,2377/udp;

docker run -p 80:80 -p 443:443 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover

ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1) | cut -d " " -f 1

echo -e "You can access your CapRover Dashboard at http://${ip4}:3000, remember to change the default password captain42"