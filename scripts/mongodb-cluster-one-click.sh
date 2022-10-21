# linode/mongodb-cluster-one-click.sh by linode
# id: 1067004
# description: MongoDB replica set
# defined fields: name-cluster_name-label-domain-name-example-linodecom-default-linodecom-name-token_password-label-your-linode-api-token-name-add_ssh_keys-label-add-account-ssh-keys-to-all-nodes-oneof-yesno-default-yes-name-domain_name-label-details-for-self-signed-ssl-certificates-country-or-region-example-us-default-us-name-state_or_province_name-label-state-or-province-example-pennsylvania-default-pennsylvania-name-locality_name-label-locality-example-philadelphia-default-philadelphia-name-organization_name-label-organization-example-linode-llc-default-linode-llc-name-email_address-label-email-address-example-userlinodecom-default-userlinodecom-name-ca_common_name-label-ca-common-name-example-mongo-ca-default-mongo-ca-name-common_name-label-common-name-example-mongo-server-default-mongo-server-name-sudo_username-label-the-limited-sudo-user-to-be-created-in-the-cluster
# images: ['linode/debian11']
# stats: Used By: 0 + AllTime: 0
#!/bin/bash

# You found me! Soon this will be yours to deploy :) Patience ...
# Have an amazing, great, super and awesome day :D

## Deployment Variables
# <UDF name="cluster_name" label="Domain Name" example="linode.com" default="linode.com" />
# <UDF name="token_password" label="Your Linode API token" />
# <UDF name="add_ssh_keys" label="Add Account SSH Keys to All Nodes?" oneof="yes,no"  default="yes" />
# <UDF name="domain_name" label="Details for self-signed SSL certificates: Country or Region" example="US" default="US" />
# <UDF name="state_or_province_name" label="State or Province" example="Pennsylvania" default="Pennsylvania" />
# <UDF name="locality_name" label="Locality" example="Philadelphia" default="Philadelphia" />
# <UDF name="organization_name" label="Organization" example="Linode LLC" default="Linode LLC"  />
# <UDF name="email_address" label="Email Address" example="user@linode.com" default="user@linode.com"  />
# <UDF name="ca_common_name" label="CA Common Name" example="Mongo CA" default="Mongo CA"  />
# <UDF name="common_name" label="Common Name" example="Mongo Server" default="Mongo Server"  />

#<UDF name="sudo_username" label="The limited sudo user to be created in the cluster" />