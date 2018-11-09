#!/bin/bash

## thanks to: https://gist.github.com/innovia/fbba8259042f71db98ea8d4ad19bd708

namespace=$1

sudo useradd $namespace
sudo mkdir -p /home/$namespace/.ssh/
sudo mkdir -p /home/$namespace/.kube/
sudo cp ~/tmp/id_rsa.pub /home/$namespace/.ssh/authorized_keys

kubecfg="k8s-cicd-conf"

secret_sa=$(kubectl -n $namespace get sa cicd -o json | jq -r .secrets[]."name")

token=$(kubectl -n $namespace get secret $secret_sa -o jsonpath={.data.token} | base64 -d)

kubectl get secret "${secret_sa}" --namespace "${namespace}" -o json | jq  -r '.data["ca.crt"]' | base64 -d > "ca.crt"

context=$(kubectl config current-context)
echo -e "Setting current context to: $context"

CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
echo "Cluster name: ${CLUSTER_NAME}"

ENDPOINT=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
echo "Endpoint: ${ENDPOINT}"

echo -n "Setting a cluster entry in kubeconfig..."
kubectl config set-cluster "${CLUSTER_NAME}" \
    --kubeconfig="$kubecfg" \
    --server="${ENDPOINT}" \
    --certificate-authority="ca.crt" \
    --embed-certs=true

echo -n "Setting token credentials entry in kubeconfig..."
kubectl config set-credentials \
    "cicd-$namespace-${CLUSTER_NAME}" \
    --kubeconfig="$kubecfg" \
    --token="$token"

echo -n "Setting a context entry in kubeconfig..."
kubectl config set-context \
    "cicd-$namespace-${CLUSTER_NAME}" \
    --kubeconfig="$kubecfg" \
    --cluster="${CLUSTER_NAME}" \
    --user="cicd-$namespace-${CLUSTER_NAME}" \
    --namespace="$namespace"

echo -n "Setting the current-context in the kubeconfig file..."
kubectl config use-context "cicd-$namespace-${CLUSTER_NAME}" \
    --kubeconfig="${kubecfg}"

sudo cp ${kubecfg} /home/$namespace/.kube/config

ENDPOINT="${ENDPOINT//\//\\/}"
sed -i.bak "s/${ENDPOINT}/${ENDPOINT}:6443/g" ${kubecfg}

sudo chown -R $namespace:$namespace /home/$namespace/.ssh/
sudo chmod 700 /home/$namespace/.ssh/
sudo chmod 400 /home/$namespace/.ssh/authorized_keys
sudo chown -R $namespace:$namespace /home/$namespace/.kube/

