#!/bin/bash


export ACCOUNT_ID="549637939820"
export PRIVATE_DNS_ZONE="slavayssiere.wescale"
export PUBLIC_DNS_ZONE="aws-wescale.slavayssiere.fr."
export KOPS_STATE_STORE=s3://wescale-slavayssiere-kops
export NAME_CLUSTER=test

cd layer-base
terraform apply \
    -var "account_id=$ACCOUNT_ID" \
    -var "region=eu-west-1" \
    -var "private_dns_zone=$PRIVATE_DNS_ZONE" \
    -auto-approve
cd ..

cd layer-bastion
./apply.sh
cd - 

cd layer-kubernetes
./apply.sh
cd - 

cd layer-services
./apply.sh
cd -
