# linode/drp-advanced.sh by zehicle
# id: 626699
# description: Installs a Digital Rebar Platform Server
with the Bootstrapping Agent Enabled

Installs drp-community-content, task-library by default.

This is very helpful for using as part of a larger automation effort.
# defined fields: name-drp_version-label-version-to-install-default-tip-example-tip-stable-v313-name-drp_id-label-specialized-endpoint-id-optional-default-default-example-linode1-name-drp_password-label-admin-password-default-r0cketsk8ts-example-r0cketsk8ts-name-initial_workflow-label-initial-workflow-default-discover-advanced-example-discover-advanced-name-initial_contents-label-initial-contents-default-drp-community-content-task-library-example-drp-community-content-task-library-edge-lab
# images: ['linode/centos8', 'linode/centos7']
# stats: Used By: 0 + AllTime: 150
#!/bin/bash

# <UDF name="drp_version" Label="Version to Install" default="tip" example="tip, stable, v3.13, ..." />
# <UDF name="drp_id" Label="Specialized Endpoint ID (optional)" default="default" example="linode1" />
# <UDF name="drp_password" Label="Admin Password" default="r0cketsk8ts" example="r0cketsk8ts" />
# <UDF name="initial_workflow" Label="Initial Workflow" default="discover-advanced" example="discover-advanced" />
# <UDF name="initial_contents" Label="Initial Contents" default="drp-community-content, task-library" example="drp-community-content, task-library. edge-lab" />

### Now open the right firewall ports for DRP
firewall-cmd --permanent --add-port=8092/tcp
firewall-cmd --permanent --add-port=8091/tcp
### Now open the right firewall ports for NFS
firewall-cmd --permanent --add-port=2049/tcp
firewall-cmd --permanent --add-port=2049/udp
firewall-cmd --reload

# Test Download
timeout 30 bash -c 'while [[ "$(curl -fsSL -o /dev/null -w %{http_code} get.rebar.digital/tip)" != "200" ]]; do sleep 2; done' || false

### Install DRP from Tip
if [[ "$DRP_ID" == "default" ]]; then
    curl -fsSL get.rebar.digital/tip | bash -s -- install --start-runner --systemd --startup --bootstrap --version=$DRP_VERSION --drp-password=$DRP_PASSWORD --initial-contents="$INITIAL_CONTENTS" --initial-workflow=$INITIAL_WORKFLOW
else
    curl -fsSL get.rebar.digital/tip | bash -s -- install --start-runner --systemd --startup --bootstrap --drp-id=$DRP_ID --version=$DRP_VERSION --drp-password=$DRP_PASSWORD --initial-contents="$INITIAL_CONTENTS" --initial-workflow=$INITIAL_WORKFLOW
fi

### For cloud, use joinup process by default
drpcli prefs set defaultWorkflow discover-joinup

### Capture Node Info 
drpcli profiles create '{"Name":"linode"}'
drpcli profiles set linode param cloud/provider to "LINODE"
drpcli profiles set linode param cloud/instance-id to "\"${LINODE_ID}\""
drpcli profiles set linode param cloud/username to "${LINODE_LISHUSERNAME}"
drpcli profiles set linode param cloud/instance-type to "\"${LINODE_RAM}\""
drpcli profiles set linode param cloud/placement/availability-zone to "\"${LINODE_DATACENTERID}\""
