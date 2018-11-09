#!/bin/bash

cd ../layer-base
private_dns_zone=$(terraform output private_dns_zone)
export ES_HOST=$(terraform output es_host)
cd ../layer-bastion


if [[ -z "${BUCKET_TFSTATES}" ]]; then
  export BUCKET_TFSTATES="wescale-slavayssiere-terraform"
fi

if [[ -z "${KOPS_STATE_STORE}" ]]; then
  export KOPS_STATE_STORE=s3://wescale-slavayssiere-kops
fi

if [[ -z "${NAME_CLUSTER}" ]]; then
  export NAME=test.$private_dns_zone
else
  export NAME=$NAME_CLUSTER.$private_dns_zone
fi

if [[ -z "${PUBLIC_DNS_ZONE}" ]]; then
  export PUBLIC_DNS_ZONE="aws-wescale.slavayssiere.fr."
fi

export CLOUD=aws
export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account | tr -d \")

jinja2 install-bastion-template.sh > install-bastion.sh

terraform apply \
    -var "bucket_layer_base=$BUCKET_TFSTATES" \
    -var "public_dns=$PUBLIC_DNS_ZONE" \
    -auto-approve
