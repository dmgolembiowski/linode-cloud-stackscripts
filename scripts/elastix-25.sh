# linode/elastix-25.sh by rmaliza
# id: 12396
# description: Installs a fully functioning, ready to go Elastix 2.5 stack that will allow you to have your favorite unified communications server in the cloud.

Remember that after the first automatic reboot, you need to launch Lish Ajax Console to set MySQL and FreePBX password.
# defined fields: 
# images: ['linode/centos5.6']
# stats: Used By: 0 + AllTime: 104
#!/bin/bash

if [ -f /etc/yum.repos.d/elastix.repo ]; then
   echo "You already have installed Eastix 2.5"
   rm -f /root/StackScript
   exit
else
   wget --no-check-certificate https://codeload.github.com/ronaldmaliza/parachutes/zip/master
   unzip master
   chmod +x parachutes-master/install.sh
   ./parachutes-master/install.sh
fi