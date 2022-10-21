# linode/woocommerce-one-click.sh by linode
# id: 401708
# description: WooCommerce One-Click
# defined fields: name-site_title-label-website-title-default-my-wordpress-site-example-my-blog-name-soa_email_address-label-e-mail-address-example-your-email-address-name-wp_admin-label-admin-username-example-username-for-your-wordpress-admin-panel-name-wp_password-label-admin-password-example-an0th3r_s3cure_p4ssw0rd-name-dbroot_password-label-mysql-root-password-example-an0th3r_s3cure_p4ssw0rd-name-db_password-label-wordpress-database-password-example-an0th3r_s3cure_p4ssw0rd-name-username-label-the-limited-sudo-user-to-be-created-for-the-linode-default-name-password-label-the-password-for-the-limited-sudo-user-example-an0th3r_s3cure_p4ssw0rd-default-name-pubkey-label-the-ssh-public-key-that-will-be-used-to-access-the-linode-default-name-disable_root-label-disable-root-access-over-ssh-oneof-yesno-default-no-name-token_password-label-your-linode-api-token-this-is-needed-to-create-your-wordpress-servers-dns-records-default-name-subdomain-label-subdomain-example-the-subdomain-for-the-dns-record-www-requires-domain-default-name-domain-label-domain-example-the-domain-for-the-dns-record-examplecom-requires-api-token-default-name-send_email-label-would-you-like-to-be-able-to-send-password-reset-emails-for-wordpress-requires-domain-oneof-yesno-default-yes-name-ssl-label-would-you-like-to-use-a-free-lets-encrypt-ssl-certificate-uses-the-linodes-default-rdns-if-no-domain-is-specified-above-oneof-yesno-default-no
# images: ['linode/debian10']
# stats: Used By: 243 + AllTime: 3425
#!/usr/bin/env bash

### Installs WordPress and creates first site.

## WordPress Settings
# <UDF name="site_title" label="Website Title" default="My WordPress Site" example="My Blog">
# <UDF name="soa_email_address" label="E-Mail Address" example="Your email address">
# <UDF name="wp_admin" label="Admin Username" example="Username for your WordPress admin panel">
# <UDF name="wp_password" label="Admin Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="dbroot_password" label="MySQL root Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="db_password" label="WordPress Database Password" example="an0th3r_s3cure_p4ssw0rd">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your WordPress server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="send_email" label="Would you like to be able to send password reset emails for WordPress? (Requires domain)" oneOf="Yes,No" default="Yes">

## Let's Encrypt SSL
#<UDF name="ssl" label="Would you like to use a free Let's Encrypt SSL certificate? (Uses the Linode's default rDNS if no domain is specified above)" oneOf="Yes,No" default="No">

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

# Wordpress install
source <ssinclude StackScriptID=401697> 

# Add WooCommerce to WordPress
wp plugin install --allow-root woocommerce
wp plugin activate --allow-root woocommerce
 
# Update Ownership
chown -R www-data:www-data /var/www/wordpress/

# Restart services
systemctl restart mysql
systemctl restart apache2

# Cleanup
stackscript_cleanup