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

cd terraform
terraform destroy \
    -var "cluster_name=$NAME" \
    -var "account_id=$ACCOUNT_ID" \
    -var "bucket_layer_base=$BUCKET_TFSTATES" \
    -auto-approve
cd ..

kops delete cluster $NAME --yes

hosted_zone_id=$(aws route53 list-hosted-zones | jq -r '.HostedZones[] | select(.Name | contains("slavayssiere.wescale.")).Id' | cut -d '/' -f3)

aws route53 list-resource-record-sets \
  --hosted-zone-id $hosted_zone_id |
jq -c '.ResourceRecordSets[]' |
while read -r resourcerecordset; do
  read -r name type <<<$(echo $(jq -r '.Name,.Type' <<<"$resourcerecordset"))
  if [ $type != "NS" -a $type != "SOA" ]; then
    aws route53 change-resource-record-sets \
      --hosted-zone-id $hosted_zone_id \
      --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":
          '"$resourcerecordset"'
        }]}' \
      --output text --query 'ChangeInfo.Id'
  fi
done