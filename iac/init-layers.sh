#!/bin/bash

export BUCKET_TFSTATES="wescale-slavayssiere-terraform"

cd layer-base
terraform init -backend-config="bucket=$BUCKET_TFSTATES"
cd ..

cd layer-bastion
terraform init -backend-config="bucket=$BUCKET_TFSTATES"
cd - 

cd layer-kubernetes/terraform
terraform init -backend-config="bucket=$BUCKET_TFSTATES"
cd - 
