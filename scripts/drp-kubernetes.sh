# linode/drp-kubernetes.sh by zehicle
# id: 548249
# description: Installs Digital Rebar Provision (DRP) Server with Kubernetes installation steps included
# defined fields: name-drp_version-label-version-to-install-default-tip-example-tip-stable-v313-name-drp_password-label-admin-password-default-r0cketsk8ts-example-password
# images: ['linode/centos8', 'linode/centos7']
# stats: Used By: 0 + AllTime: 19
#!/bin/bash

# <UDF name="drp_version" Label="Version to Install" default="tip" example="tip, stable, v3.13, ..." />
# <UDF name="drp_password" Label="Admin Password" default="r0cketsk8ts" example="password" />

firewall-cmd --permanent --add-port=8092/tcp
firewall-cmd --permanent --add-port=8091/tcp
firewall-cmd --reload

### Install DRP from Tip
curl -fsSL get.rebar.digital/tip | bash -s -- install --systemd --version=$DRP_VERSION --drp-password=$DRP_PASSWORD

### Install Content and Configure Discovery
drpcli catalog item install task-library --version=$DRP_VERSION
drpcli catalog item install drp-community-content --version=$DRP_VERSION
drpcli workflows create '{"Name": "discover-linode", "Stages":
  ["discover", "runner-service", "complete"]
}'
drpcli prefs set defaultWorkflow discover-linode unknownBootEnv discovery

### Capture Node Info 
drpcli profiles create '{"Name":"linode"}'
drpcli profiles set linode param cloud/provider to "LINODE"
drpcli profiles set linode param cloud/instance-id to "\"${LINODE_ID}\""
drpcli profiles set linode param cloud/username to "${LINODE_LISHUSERNAME}"
drpcli profiles set linode param cloud/instance-type to "\"${LINODE_RAM}\""
drpcli profiles set linode param cloud/placement/availability-zone to "\"${LINODE_DATACENTERID}\""

drpcli catalog item install certs --version=$DRP_VERSION
drpcli catalog item install krib --version=$DRP_VERSION
drpcli profiles create '{"Name":"krib", "Meta": {
  "render": "krib", "reset-keeps": "krib/cluster-profile,etcd/cluster-profile",
}}'
drpcli profiles set krib param "etcd/cluster-profile" to "krib"
drpcli profiles set krib param "krib/cluster-profile" to "krib"
drpcli profiles set global param "network/firewalld-ports" to '[
  "6443/tcp", "8379/tcp",  "8380/tcp", "10250/tcp"
]'
drpcli workflows create '{"Name":"k3s-linode", "Stages": [
    "ssh-access", "network-firewalld","k3s-config","krib-live-wait"
  ]
}'
drpcli workflows create '{"Name":"krib-linode", "Stages": [
    "ssh-access", "network-firewalld", "docker-install", "kubernetes-install","etcd-config","krib-config","krib-helm","krib-live-wait"
  ]
}'
