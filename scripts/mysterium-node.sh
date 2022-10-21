# linode/mysterium-node.sh by mysterium
# id: 327439
# description: This scripts does initial server setup such as updating all packages, configures the firewall to allow Mysterium though, then pulls and creates the mysterium-node container.

This allows for automated creation of a Mysterium Node

#This is a community made script and was not produced by the official Mysterium Project
# defined fields: 
# images: ['linode/ubuntu16.04lts']
# stats: Used By: 0 + AllTime: 82
#!/bin/bash

# Initial updates
apt update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

# Create mysterium-node firewall rules
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT

# Install Docker
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update
apt-cache policy docker-ce
apt install docker-ce -y

# Pull mysterium-node image and create mysterium-node container
docker pull mysteriumnetwork/mysterium-node 
docker run --cap-add NET_ADMIN --net host --publish "1194:1194" --name mysterium-node -d mysteriumnetwork/mysterium-node --agreed-terms-and-conditions


# Final update of packages
apt upgrade -y