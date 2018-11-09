#!/bin/bash

if [[ -z "${BUCKET_TFSTATES}" ]]; then
  export BUCKET_TFSTATES="wescale-slavayssiere-terraform"
fi

touch install-bastion.sh
terraform destroy \
    -var "bucket_layer_base=$BUCKET_TFSTATES" \
    -auto-approve

rm install-bastion.sh
