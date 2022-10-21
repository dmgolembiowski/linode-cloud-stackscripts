# linode/gitlab-one-click.sh by linode
# id: 401707
# description: GitLab One-Click
# defined fields: name-soa_email_address-label-this-is-the-email-address-for-the-letsencrypt-ssl-certificate-example-userdomaintld-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-gitlab-servers-dns-records-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default
# images: ['linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 140 + AllTime: 2497
#!/usr/bin/env bash

## Gitlab Settings
#<UDF name="soa_email_address" label="This is the Email address for the LetsEncrypt SSL Certificate" example="user@domain.tld">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your Gitlab server's DNS records" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">

## Enable logging
set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

function gitlab {
    # Install dependencies
    apt-get install curl ca-certificates apt-transport-https gnupg2 -y

    curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
    apt-get update -y
    EXTERNAL_URL="https://$FQDN" apt-get install gitlab-ce -y

}

function sslgitlab {
    # Taking advantage of Gitlab's Let's Encrypt cert capabilities
    sed -i "s/# letsencrypt\['enable'\] = nil/letsencrypt\['enable'\] = true/g" /etc/gitlab/gitlab.rb
    sed -i -E "s/(# )(letsencrypt\['auto_renew*)/\2/g" /etc/gitlab/gitlab.rb
    sed -i "s/letsencrypt['auto_renew_minute'] = nil/letsencrypt['auto_renew_minute'] = 0/g" /etc/gitlab/gitlab.rb
    sed -i "s/# letsencrypt\['contact_emails'\] = \[\]/letsencrypt\['contact_emails'\] = \['$SOA_EMAIL_ADDRESS']/g" /etc/gitlab/gitlab.rb

    gitlab-ctl reconfigure
}

function firewallgitlab {
    ufw allow http
    ufw allow https
}

function main {
    gitlab
    firewallgitlab
    sslgitlab
}

# Execute Script
main
stackscript_cleanup