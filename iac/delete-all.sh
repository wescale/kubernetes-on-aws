#!/bin/bash

cd layer-bastion/
./destroy.sh &
cd -

cd layer-kubernetes/
./destroy.sh
cd -

cd layer-base
terraform destroy \
 -auto-approve
cd -

