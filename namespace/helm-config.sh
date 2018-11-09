#!/bin/bash

namespace=$1

aws configure set region eu-west-1 >> /dev/null 2>&1
helm init --tiller-namespace $namespace --service-account cicd >> /dev/null 2>&1
helm list --tiller-namespace $namespace >> /dev/null 2>&1
helm --tiller-namespace $namespace plugin install https://github.com/hypnoglow/helm-s3.git >> /dev/null 2>&1
helm --tiller-namespace $namespace repo add my-charts s3://wescale-slavayssiere-helm/ >> /dev/null 2>&1

echo "export TILLER_NAMESPACE=$namespace" >> ~/.bashrc
