# linode/secure-your-server-one-click.sh by linode
# id: 692092
# description: Secure Your Server One-Click
# defined fields: name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-name-password-label-the-password-for-the-limited-sudo-user-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-name-disable_root-label-would-you-like-to-disable-root-login-over-ssh-oneof-yesno-name-token_password-label-your-linode-api-token-this-is-required-for-creating-dns-records-default-name-domain-label-the-domain-for-the-linodes-dns-record-requires-api-token-default-name-subdomain-label-the-subdomain-for-the-linodes-dns-record-requires-api-token-and-domain-default-name-soa_email_address-label-your-email-address-this-is-used-for-creating-dns-records-and-website-virtualhost-configuration-default-name-send_email-label-would-you-like-to-be-able-to-send-email-from-this-domain-requires-domain-oneof-yesno-default-no-name-volume-label-to-use-a-block-storage-volume-enter-its-name-here-default-name-volume_size-label-if-creating-a-new-block-storage-volume-enter-its-size-in-gb-note-this-creates-a-billable-resource-at-010month-per-gb-default
# images: ['linode/debian10', 'linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 373 + AllTime: 2424
#!/usr/bin/env bash

## User and SSH Security
#<UDF name="username" label="The limited sudo user to be created for the Linode">
#<UDF name="password" label="The password for the limited sudo user">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" >
#<UDF name="disable_root" label="Would you like to disable root login over SSH?" oneOf="Yes,No">

## Domain
#<UDF name="token_password" label="Your Linode API token - This is required for creating DNS records" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token and domain)" default="">
#<UDF name="soa_email_address" label="Your email address. This is used for creating DNS records and website VirtualHost configuration." default="">
#<UDF name="send_email" label="Would you like to be able to send email from this domain? (Requires domain)" oneOf="Yes,No" default="No">

## Block Storage
#<UDF name="volume" label="To use a Block Storage volume, enter its name here." default="">
#<UDF name="volume_size" label="If creating a new Block Storage volume, enter its size in GB (NOTE: This creates a billable resource at $0.10/month per GB)." default="">


# Enable logging for the StackScript
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Source Linode Helpers
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=666912>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Cleanup
stackscript_cleanup