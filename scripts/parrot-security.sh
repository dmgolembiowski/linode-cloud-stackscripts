# linode/parrot-security.sh by palinuro
# id: 636642
# description: Official Parrot OS headless machine with pentest tools
# defined fields: 
# images: ['linode/debian10']
# stats: Used By: 2 + AllTime: 76
#!/bin/bash

apt update && apt -y full-upgrade

apt -y install gnupg 

wget https://nest.parrot.sh/build/alternate-install/-/raw/master/parrot-install.sh

chmod +x parrot-install.sh

echo 3 | ./parrot-install.sh