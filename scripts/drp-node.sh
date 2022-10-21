# linode/drp-node.sh by zehicle
# id: 548252
# description: Adds node to a running Digital Rebar Provision endpoint
# defined fields: name-drp_ip-label-ip-address-of-the-drp-endpoint-default-example-1921681100-name-drp_port-label-provisioning-port-of-the-drp-endpoint-not-api-port-default-8091-example-8091-name-open_ports-label-ports-to-open-on-the-machine-default-22-2379-2380-6443-10250-example-22-6443-10250-name-rs_uuid-label-map-uuid-if-machine-already-exists-default-no_uuid-example-b7029cf8-a034-48f4-99e3-b51245c05042
# images: ['linode/centos7', 'linode/ubuntu18.04', 'linode/debian10', 'linode/containerlinux', 'linode/ubuntu19.04', 'linode/ubuntu18.10', 'linode/centos8', 'linode/ubuntu20.04']
# stats: Used By: 0 + AllTime: 580
#!/bin/bash
# <UDF name="drp_ip" Label="IP Address of the DRP Endpoint" default="" example="192.168.1.100" />
# <UDF name="drp_port" Label="Provisioning Port of the DRP Endpoint (not API port)" default="8091" example="8091" />
# <UDF name="open_ports" Label="Ports to open on the machine" default="22 2379 2380 6443 10250" example="22 6443 10250" />
# <UDF name="rs_uuid" Label="Map UUID if machine already exists" default="no_uuid" example="b7029cf8-a034-48f4-99e3-b51245c05042" />

for PORT in ${OPEN_PORTS}; do
   firewall-cmd --permanent --add-port=${PORT}/tcp
done 
firewall-cmd --reload

reg_uuid="(.{8})-(.{4})-(.{4})-(.{4})-(.{12})"
if [[ $RS_UUID =~ $reg_uuid ]]; then
    echo "${RS_UUID}" > /etc/rs-uuid
fi

timeout 300 bash -c 'while [[ "$(curl -fsSL -o /dev/null -w %{http_code} ${DRP_IP}:${DRP_PORT}/machines/join-up.sh)" != "200" ]]; do sleep 5; done' || false

curl -fsSL ${DRP_IP}:${DRP_PORT}/machines/join-up.sh | sudo bash --
