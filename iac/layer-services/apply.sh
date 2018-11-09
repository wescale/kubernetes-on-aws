#!/bin/bash

cd ../layer-bastion
bastion_hostname=$(terraform output bastion_public_dns)
cd ../layer-base
private_dns_zone=$(terraform output private_dns_zone)
export ES_HOST=$(terraform output es_host)
cd ../layer-services

if [[ -z "${NAME_CLUSTER}" ]]; then
  export NAME=test.$private_dns_zone
else
  export NAME=$NAME_CLUSTER.$private_dns_zone
fi

if [[ -z "${PUBLIC_DNS_ZONE}" ]]; then
  export PUBLIC_DNS_ZONE="aws-wescale.slavayssiere.fr"
fi

if [[ -z "${PRIVATE_DNS_ZONE}" ]]; then
  export PRIVATE_DNS_ZONE="slavayssiere.wescale"
fi



FILE="./cm-adapter-serving-certs.yaml"
if [ ! -e "$FILE" ]; then
   echo "File $FILE does not exist."
   ./gencerts.sh
   rm apiserver-key.pem
   rm apiserver.pem
   rm apiserver.csr
   rm metrics-ca.crt
   rm metrics-ca.key
   rm metrics-ca-config.json
fi

cd kiam
FILE="./ca-key.pem"
if [ ! -e "$FILE" ]; then
  cfssl gencert -initca ca.json | cfssljson -bare ca
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem server.json | cfssljson -bare server
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem agent.json | cfssljson -bare agent
fi
cd -

export ACCOUNT_ID=$(aws sts get-caller-identity | jq .Account | tr -d \")

jinja2 ./templates/cluster-autoscaler.yaml > ./manifests/cluster-autoscaler.yaml
jinja2 ./templates/kube2iam.yaml > ./manifests/kube2iam.yaml
jinja2 ./templates/fluentd-to-es.yaml > ./manifests/fluentd-to-es.yaml
jinja2 ./templates/alert-manager-sns-forwarder.yaml > ./manifests/alert-manager-sns-forwarder.yaml
jinja2 ./templates/route53-externalDNS.yaml > ./manifests/route53-externalDNS.yaml
jinja2 ./templates/traefik-svc-private.yaml > ./traefik-admin/traefik-svc.yaml
jinja2 ./templates/traefik-svc-public.yaml > ./traefik-app/traefik-svc.yaml
jinja2 ./aws-service-catalog/aws-service-operator.yaml > ./manifests/aws-service-operator.yaml

cp ./templates/alertmanager.yaml ./kube-prometheus/alertmanager.yaml
sed -i.bak "s/%NAME%/$NAME/g" ./kube-prometheus/alertmanager.yaml

scp -r -oStrictHostKeyChecking=no . ec2-user@$bastion_hostname:~
ssh -oStrictHostKeyChecking=no ec2-user@$bastion_hostname "./install.sh"

rm ./manifests/kube2iam.yaml
rm ./manifests/fluentd-to-es.yaml
rm ./manifests/cluster-autoscaler.yaml
rm ./manifests/alert-manager-sns-forwarder.yaml
rm ./manifests/route53-externalDNS.yaml
rm ./traefik-admin/traefik-svc.yaml
rm ./traefik-app/traefik-svc.yaml
rm ./manifests/aws-service-operator.yaml
rm ./kube-prometheus/alertmanager.yaml
