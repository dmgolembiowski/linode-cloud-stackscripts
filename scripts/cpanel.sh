# linode/cpanel.sh by mbeach
# id: 38902
# description: Installs cPanel based on instructions at:
https://documentation.cpanel.net/display/ALD/Installation+Guide

This was written for CentOS 7 but should work on CentOS 6.8 as well.
# defined fields: 
# images: ['linode/centos7', 'linode/centos6.8']
# stats: Used By: 2 + AllTime: 88
#!/bin/bash

## Ensure distro kernel and grub2 are installed first
yum install -y kernel grub2
sed -i -e "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/" /etc/default/grub
sed -i -e "s/crashkernel=auto rhgb console=ttyS0,19200n8/console=ttyS0,19200n8/" /etc/default/grub
mkdir /boot/grub
grub2-mkconfig -o /boot/grub/grub.cfg

## Disable firewall

# CentOS 6
/etc/init.d/iptables save
/etc/init.d/iptables stop
/sbin/chkconfig --del iptables

# CentOS 7
systemctl stop firewalld.service
systemctl disable firewalld.service

## Disable NetworkManager
# See https://documentation.cpanel.net/display/ALD/Installation+Guide+-+System+Requirements
# for the requirement to disable NetworkManager

# CentOS 6
service NetworkManager stop
chkconfig NetworkManager off
chkconfig network on
service network start

# CentOS 7
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl enable network
systemctl start network

## Start installation
cd /home \
  && curl -o latest -L https://securedownloads.cpanel.net/latest \
  && sh latest

## Queue reboot
(sleep 5 && reboot) &