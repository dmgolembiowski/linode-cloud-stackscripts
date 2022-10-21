# linode/hashicorp-vault-one-click.sh by linode
# id: 1037038
# description: HashiCorp Vault One Click App
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no
# images: ['linode/debian11', 'linode/ubuntu22.04']
# stats: Used By: 4 + AllTime: 27
#!/usr/bin/env bash

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

export IP=$(hostname -I | awk '{print$1}')
export VAULT_ADDR="http://${IP}:8200"

## install gpg
apt install -y gpg

## add hashicorp gpg key and repo
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

## install vault
apt update && apt install -y vault

## basic vault configs
mkdir -p /vault/data
chown -R vault:vault /vault
cat << EOF > /etc/vault.d/vault.hcl
storage "raft" {
  path    = "/vault/data"
  node_id = "node1"
}

listener "tcp" {
  address     = "${IP}:8200"
  tls_disable = "true"
}

disable_mlock = true

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true
EOF

## systemd for vault
systemctl enable vault.service

## Start vault server and stash the tokens
systemctl start vault.service
touch /root/.vault_tokens.txt
sleep 20
vault operator init | grep 'Token\|Unseal' >> /root/.vault_tokens.txt

## firewall
ufw allow 22
ufw allow 8200

## config info and recommendations
cat << EOF > /etc/motd
#####################################
 The Vault server GUI is now available at ${VAULT_ADDR}
 The randomly generate Unseal Tokens and Initial Root Token are listed in /root/.vault_tokens.txt
 ** STORE THESE VALUES SOMEWHERE SAFE AND SECURE **

 This is a minimal installation with limited configurations.
 Please review configurations before using this application in production.

 Information on Vault configurations at https://www.vaultproject.io/docs/configuration
######################################
EOF

sleep 20
stackscript_cleanup