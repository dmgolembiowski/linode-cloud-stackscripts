# linode/easy-k8s.sh by oscartbeaumont
# id: 936068
# description: Deploy a simple & secure Kubernetes cluster for personal use. This project can be found at https://github.com/oscartbeaumont/servers
# defined fields: name-node_hostname-label-hostname-example-localhost-default-name-cluster_name-label-cluster-name-example-cluster-default-name-cluster_domain-label-cluster-domain-example-clusterexamplecom-default-name-timezone-label-time-zone-example-australiaperth-default
# images: ['linode/debian10']
# stats: Used By: 1 + AllTime: 8
#!/bin/bash -e
# <UDF name="node_hostname" label="Hostname" example="localhost" default="">
# <UDF name="cluster_name" label="Cluster Name" example="cluster" default="">
# <UDF name="cluster_domain" label="Cluster Domain" example="cluster.example.com" default="">
# <UDF name="timezone" label="Time Zone" example="Australia/Perth" default="">

# Enable logging
exec 1> >(tee -a "/var/log/deploy-node.log") 2>&1
echo "=== Running K3s Kubernetes Cluster Deployment"

echo "=== Validate arguments"
CLUSTER_NAME=${CLUSTER_NAME:-kubernetes}

if [[ ! -z "$TIMEZONE" ]]; then
	echo "=== Configuring timezone to: $TIMEZONE"
	timedatectl set-timezone $TIMEZONE
fi

echo "=== Add Debian backports (required for Wireguard)"
if grep -q "mirrors.linode.com" "/etc/apt/sources.list"; then
	echo "Using Linode backports repository!"
	echo "deb http://mirrors.linode.com/debian buster-backports main" | sudo tee /etc/apt/sources.list.d/buster-backports.list
else
	echo "Using Debian backports repository!"
	echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee /etc/apt/sources.list.d/buster-backports.list
fi

echo "=== Update System"
export DEBIAN_FRONTEND=noninteractive
apt-get -qq update
apt-get -qq upgrade

echo "=== Ensure SSH is uninstalled"
apt-get -qq remove openssh-server dropbear

echo "=== Install Basic Tools"
apt-get -qq install git htop

echo "=== Configure Hostname/Networking"
if [[ ! -z "$NODE_HOSTNAME" ]]; then
	echo "=== Configuring Node Hostname to '$NODE_HOSTNAME'"
	hostnamectl set-hostname $NODE_HOSTNAME
	echo "" >>/etc/hosts
	echo "127.0.0.1 $NODE_HOSTNAME" >>/etc/hosts
fi
if [[ ! -z "$CLUSTER_DOMAIN" ]]; then
	echo "=== Configuring Cluster Domain '$CLUSTER_DOMAIN' in the hosts file"
	echo -e "\n# Kubernetes Cluster Domain\n127.0.0.1 $CLUSTER_DOMAIN" >>/etc/hosts
fi

echo "=== Configure Unattended Upgrades"
apt-get -qq install unattended-upgrades
cat <<EOT >/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOT
cat <<EOT >>/etc/apt/apt.conf.d/50unattended-upgrades

// Reboot your server automatically
Unattended-Upgrade::Automatic-Reboot "true";

// At 3am
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// Cleanup old packages
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOT

echo "=== Switch to legacy iptables"
apt-get -qq install iptables
iptables -F
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

echo "=== Firewall"
apt-get -qq install ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 6443/tcp
ufw allow in on cni0 from 10.42.0.0/16
ufw enable

echo "=== Disable SWAP"
swapoff --all
sed -i.bak '/swap/d' /etc/fstab

echo "=== Installing kubectl" # This is to fix: https://github.com/k3s-io/k3s/issues/1541
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get -qq update
apt-get -qq install kubectl

echo "=== Install k3s installer"
wget -O /usr/local/bin/k3s-installer https://get.k3s.io
chmod +x /usr/local/bin/k3s-installer

# Generate Kubernetes Cluster Exec Arguments
INSTALL_K3S_EXEC="--etcd-expose-metrics --secrets-encryption"

echo "=== Configure k3s (flannel) to use encrypted Wireguard backend"
apt-get -qq install wireguard
INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --flannel-backend=wireguard"

if [[ ! -z "$CLUSTER_DOMAIN " ]]; then
	echo "=== Configure cluster domain as: $CLUSTER_DOMAIN"
	INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --tls-san $CLUSTER_DOMAIN --cluster-domain $CLUSTER_DOMAIN"
fi

if [[ ! -z "$NODE_HOSTNAME" ]]; then
	echo "=== Configure node hostname as: $NODE_HOSTNAME"
	INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --node-name $NODE_HOSTNAME"
fi

echo "=== Initialise Kubernetes cluster with command: k3s-installer server $INSTALL_K3S_EXEC"
k3s-installer server

echo "=== Check k3s configuration"
k3s check-config

if [[ ! -z "$CLUSTER_DOMAIN" ]]; then
	echo "=== Update Kubeconfig server URL to use FQDN"
	kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml config set-cluster "default" --server=https://$CLUSTER_DOMAIN:6443
fi

echo "=== Initialise Kubernetes 'root' user account."
SERICEACCOUNT_USERNAME="${NODE_HOSTNAME:-$(hostname)}.root"
k3s kubectl -n kube-system create serviceaccount "$SERICEACCOUNT_USERNAME"
k3s kubectl create clusterrolebinding "$SERICEACCOUNT_USERNAME-binding" --serviceaccount="kube-system:$SERICEACCOUNT_USERNAME" --clusterrole=cluster-admin
SA_SECRET_NAME="$(k3s kubectl -n kube-system get serviceaccount "$SERICEACCOUNT_USERNAME" -o jsonpath='{.secrets[0].name}')"
SA_SECRET="$(k3s kubectl -n kube-system get secret "$SA_SECRET_NAME" -o jsonpath='{.data.token}' | base64 -d)"

mkdir -p /root/.kube/
kubectl --kubeconfig "/root/.kube/config" config set-cluster "$CLUSTER_NAME" --server "https://${CLUSTER_DOMAIN:-127.0.0.1}:6443" --embed-certs --certificate-authority="/var/lib/rancher/k3s/server/tls/server-ca.crt"
kubectl --kubeconfig "/root/.kube/config" config set-credentials "root" --token="$SA_SECRET"
kubectl --kubeconfig "/root/.kube/config" config set-context default --cluster "$CLUSTER_NAME" --user="root"
kubectl --kubeconfig "/root/.kube/config" config use-context default

chown -R root /root/.kube/config
chmod -R 0700 /root/.kube/config

echo "=== Prevent UFW outputing to console" # Refer to: https://www.linode.com/community/questions/17138/lish-console-consantly-prints-iptables-logging
echo "# Prevent UFW logs being printed to console!" >>/etc/sysctl.conf
echo "kernel.printk = 3 4 1 3" >>/etc/sysctl.conf

echo "=== Rebooting server"
reboot
