# linode/drp_join_up.sh by zehicle
# id: 863588
# description: Simple DRP Join Up
# defined fields: name-rs_uuid-label-drp-machine-id-name-provision_url-label-drp-endpoint-url-name-drp_name-label-drp-machine-name
# images: ['linode/almalinux8', 'linode/centos8', 'linode/centos-stream8', 'linode/centos7', 'linode/rocky8', 'linode/ubuntu21.04', 'linode/ubuntu20.10', 'linode/debian10', 'linode/ubuntu20.04', 'linode/ubuntu18.04', 'linode/ubuntu16.04lts', 'linode/alpine3.14']
# stats: Used By: 0 + AllTime: 1
#!/bin/bash
# <UDF name="rs_uuid" label="DRP Machine ID" />
# <UDF name="provision_url" label="DRP Endpoint URL" />
# <UDF name="drp_name" label="DRP Machine Name" />

if [[ ! -z $RS_UUID ]] ; then
  echo "$RS_UUID" > /etc/rs-uuid
fi

if [[ ! -z $DRP_NAME ]] ; then
  export HOSTNAME=\$\${DRP_NAME}; curl -kfsSL $PROVISION_URL/machines/join-up.sh | sudo bash --
fi

# for whoami cloudinit
tee /run/cloud-init/instance-data.json >/dev/null << EOF
{
  "v1": {
    "region": "\$\${LINODE_DATACENTERID}",
    "cloud_name": "linode",
    "instance_id": "\$\${LINODE_ID}"
  },
    "meta_data": {
      "instance_id": "\$\${LINODE_ID}",
      "instance_type": "{{.Param "linode/instance-type"}}"
    },
    "instance_id": "\$\${LINODE_ID}",
    "cloud_name": "linode",
    "variant": "digitalrebar",
    "vendordata": "rackn"
}
EOF

# join-up
curl -kfsSL \$\${PROVISION_URL}/machines/join-up.sh | sudo bash --
