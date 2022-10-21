# linode/drp.sh by zehicle
# id: 549453
# description: Install Digital Rebar Provision Endpoint
# defined fields: name-drp_version-label-version-to-install-default-stable-example-tip-stable-v313-name-drp_password-label-admin-password-default-r0cketsk8ts-example-password1234-name-drp_id-label-specialized-endpoint-id-optional-default-default-example-linode1-name-drp_bootstrap-label-bootstrap-machine-name-optional-default-do_not_create-example-bootstrap
# images: ['linode/centos8', 'linode/centos7']
# stats: Used By: 0 + AllTime: 43
#!/bin/bash

# <UDF name="drp_version" Label="Version to Install" default="stable" example="tip, stable, v3.13, ..." />
# <UDF name="drp_password" Label="Admin Password" default="r0cketsk8ts" example="password1234" />
# <UDF name="drp_id" Label="Specialized Endpoint ID (optional)" default="default" example="linode1" />
# <UDF name="drp_bootstrap" Label="Bootstrap Machine Name (optional)" default="do_not_create" example="bootstrap" />

# Test Download
timeout 30 bash -c 'while [[ "$(curl -fsSL -o /dev/null -w %{http_code} get.rebar.digital/tip)" != "200" ]]; do sleep 2; done' || false

### Install DRP from Tip
if [[ "$DRP_ID" == "default" ]]; then
    curl -fsSL get.rebar.digital/stable | bash -s -- install --systemd --version=$DRP_VERSION --drp-password=$DRP_PASSWORD
else
    curl -fsSL get.rebar.digital/stable | bash -s -- install --systemd --drp-id=$DRP_ID --version=$DRP_VERSION --drp-password=$DRP_PASSWORD
fi

### Now open the right firewall ports for DRP
firewall-cmd --permanent --add-port=8092/tcp
firewall-cmd --permanent --add-port=8091/tcp
firewall-cmd --reload

### Install Content and Configure Discovery
drpcli catalog item install task-library --version=$DRP_VERSION
drpcli catalog item install drp-community-content --version=$DRP_VERSION
drpcli workflows create '{"Name": "discover-linode", "Stages":
  ["discover", "network-firewalld", "runner-service", "complete-nobootenv"]
}'
drpcli profiles set global param "network/firewalld-ports" to '[
  "22/tcp", "6443/tcp", "8379/tcp",  "8380/tcp", "10250/tcp"
]'
drpcli prefs set defaultWorkflow discover-linode unknownBootEnv discovery

### Capture Node Info 
drpcli profiles create '{"Name":"linode"}'
drpcli profiles set linode param cloud/provider to "LINODE"
drpcli profiles set linode param cloud/instance-id to "\"${LINODE_ID}\""
drpcli profiles set linode param cloud/username to "${LINODE_LISHUSERNAME}"
drpcli profiles set linode param cloud/instance-type to "\"${LINODE_RAM}\""
drpcli profiles set linode param cloud/placement/availability-zone to "\"${LINODE_DATACENTERID}\""