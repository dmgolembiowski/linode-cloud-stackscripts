# linode/docker-one-click.sh by linode
# id: 607433
# description: Docker One Click App
# defined fields: name-dockerfile-label-resource-to-download-example-url-to-dockerfile-or-docker-composeyml-default-name-runcmd-label-command-to-run-example-docker-run-name-spigot-restart-unless-stopped-e-jvm_opts-xmx4096m-p-2556525565-itd-exampledocker-spigot-default-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-required-if-filling-out-any-of-the-domain-related-fields-default-name-subdomain-label-the-subdomain-for-your-server-default-name-domain-label-your-domain-default-name-soa_email_address-label-admin-email-for-the-server-default-name-mx-label-do-you-need-an-mx-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no-name-spf-label-do-you-need-an-spf-record-for-this-domain-yes-if-sending-mail-from-this-linode-oneof-yesno-default-no
# images: ['linode/debian10', 'linode/debian11', 'linode/ubuntu20.04']
# stats: Used By: 1742 + AllTime: 22010
#!/usr/bin/env bash

### UDF Variables

## Docker Settings
#<UDF name="dockerfile"  Label="Resource to download?" example="URL to Dockerfile or docker-compose.yml" default="">
#<UDF name="runcmd" Label="Command to run?" example="docker run --name spigot --restart unless-stopped -e JVM_OPTS=-Xmx4096M -p 25565:25565 -itd example/docker-spigot" default="">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required if filling out any of the domain-related fields." default="">
#<UDF name="subdomain" label="The subdomain for your server" default="">
#<UDF name="domain" label="Your domain" default="">
#<UDF name="soa_email_address" label="Admin Email for the server" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">

### Logging and other debugging helpers

## Enable logging for the StackScript
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

## Local functions used by this script

function docker_ce_install {
    # Install the dependencies & add Docker to the APT repository
    system_install_package apt-transport-https ca-certificates curl software-properties-common gnupg2
    curl -fsSL https://download.docker.com/linux/"${detected_distro[distro]}"/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/"${detected_distro[distro]}" $(lsb_release -cs) stable"

    # Update & install Docker-CE
    apt_setup_update 
    system_install_package docker-ce
}

function docker_compose_install {
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    docker-compose up
}

# Remove any existing Docker installations
system_remove_package docker docker-engine docker.io

# Download the Dockerfile, if specified
[ "$DOCKERFILE" ] && curl -LO "$DOCKERFILE"

# Install Docker CE and Docker Compose
docker_ce_install
docker_compose_install

# Configure the firewall
## code will go here

# Wait 2 seconds, then run the container
sleep 2
[ "$RUNCMD" ] && $RUNCMD &