# linode/test.sh by traiangabor897
# id: 840866
# description: 
# defined fields: 
# images: ['linode/ubuntu18.04']
# stats: Used By: 0 + AllTime: 75
#!/bin/bash
cd /root
apt-get update -y
apt install -y git
git clone http://git.fcfglobal.co/root/mt2gAmazon.git
    mv mt2gAmazon mt
cd mt
sudo chmod 777 *
sudo ./install.sh
cd ..
git clone http://git.fcfglobal.co/root/rt2.git
    mv rt2 newhet
cd newhet
echo token > token.txt
sudo chmod 777 *
sudo ./run.sh