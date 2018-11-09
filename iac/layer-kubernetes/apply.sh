#!/bin/bash

cd ../layer-base
private_dns_zone=$(terraform output private_dns_zone)
export ES_HOST=$(terraform output es_host)
cd ../layer-kubernetes


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

export CLOUD=aws
export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account | tr -d \")


jinja2 cluster-template.yaml ../data.yaml --format=yaml > ./cluster.yaml

kops create -f ./cluster.yaml
kops create secret --name $NAME sshpublickey admin -i ~/.ssh/id_rsa.pub
rm ./cluster.yaml

kops update cluster $NAME --yes

cd terraform
terraform apply \
    -var "cluster_name=$NAME" \
    -var "account_id=$ACCOUNT_ID" \
    -var "bucket_layer_base=$BUCKET_TFSTATES" \
    -auto-approve
cd ..