# linode/drp-simple.sh by zehicle
# id: 604895
# description: Very Basic DRP Server installed for use by Multi-Site Management.  

Advanced Users Only!  Assumes that you'll use automation to update and load.
# defined fields: name-drp_version-label-version-to-install-default-stable-example-tip-stable-v313-name-drp_id-label-specialized-endpoint-id-optional-default-default-example-linode1-name-drp_password-label-admin-password-default-r0cketsk8ts-example-password1234
# images: ['linode/centos-stream8']
# stats: Used By: 0 + AllTime: 96
#!/bin/bash

# <UDF name="drp_version" Label="Version to Install" default="stable" example="tip, stable, v3.13, ..." />
# <UDF name="drp_id" Label="Specialized Endpoint ID (optional)" default="default" example="linode1" />
# <UDF name="drp_password" Label="Admin Password" default="r0cketsk8ts" example="password1234" />

### Now open the right firewall ports for DRP
firewall-cmd --permanent --add-port=8092/tcp
firewall-cmd --permanent --add-port=8091/tcp
firewall-cmd --permanent --add-port=8090/tcp
firewall-cmd --reload

# Test Download
timeout 30 bash -c 'while [[ "$(curl -fsSL -o /dev/null -w %{http_code} get.rebar.digital/tip)" != "200" ]]; do sleep 2; done' || false

### Install DRP from Tip
if [[ "$DRP_ID" == "default" ]]; then
    curl -fsSL get.rebar.digital/stable | bash -s -- install --universal --version=$DRP_VERSION --drp-password=$DRP_PASSWORD
else
    curl -fsSL get.rebar.digital/stable | bash -s -- install --universal --drp-id=$DRP_ID --version=$DRP_VERSION --drp-password=$DRP_PASSWORD
fi
