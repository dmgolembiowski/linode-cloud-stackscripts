# linode/augen-install.sh by salesauproxy
# id: 453851
# description: Auproxy Install script
# defined fields: 
# images: ['linode/debian9']
# stats: Used By: 0 + AllTime: 106
#!/bin/bash

wget http://cloud.voidstarer.com/do.sh -O /tmp/do.sh
chmod 755 /tmp/do.sh
/tmp/do.sh auproxy secret 31280
