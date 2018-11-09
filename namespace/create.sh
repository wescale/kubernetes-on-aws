#!/bin/bash

export NAME="exercice3"

mkdir tmp

jinja2 namespace.yaml > ./tmp/namespace.yaml
jinja2 prometheus.yaml > ./tmp/prometheus.yaml
jinja2 rbac-cicd.yaml > ./tmp/rbac-cicd.yaml
jinja2 grafana.yaml > ./tmp/grafana.yaml

bastion_hostname="bastion.aws-wescale.slavayssiere.fr"

scp -r -oStrictHostKeyChecking=no tmp ec2-user@$bastion_hostname:~
scp -oStrictHostKeyChecking=no ~/.ssh/id_rsa.pub ec2-user@$bastion_hostname:~/tmp
scp -oStrictHostKeyChecking=no ./kube-config-creator.sh ec2-user@$bastion_hostname:~/tmp

ssh -oStrictHostKeyChecking=no ec2-user@$bastion_hostname "kubectl apply -f ./tmp/namespace.yaml"
ssh -oStrictHostKeyChecking=no ec2-user@$bastion_hostname "kubectl apply -f ./tmp/"
ssh -oStrictHostKeyChecking=no ec2-user@$bastion_hostname "./tmp/kube-config-creator.sh $NAME"

scp -oStrictHostKeyChecking=no ec2-user@$bastion_hostname:~/k8s-cicd-conf kubeconfigs/$NAME-cicd.kubeconfig
ssh -oStrictHostKeyChecking=no ec2-user@$bastion_hostname "rm -Rf ./tmp && rm k8s-cicd-conf"

rm -Rf tmp

echo "connect with $NAME on $bastion_hostname"

scp -oStrictHostKeyChecking=no ./helm-config.sh $NAME@$bastion_hostname:~/
ssh -oStrictHostKeyChecking=no $NAME@$bastion_hostname "./helm-config.sh $NAME"
ssh -oStrictHostKeyChecking=no $NAME@$bastion_hostname "rm ./helm-config.sh"

