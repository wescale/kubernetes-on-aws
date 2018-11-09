#!/bin/bash

until kops validate cluster
do
    echo "Wait for cluster provisionning"
    sleep 10
done

kubectl annotate ns kube-system iam.amazonaws.com/permitted=".*"

cd rook
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
kubectl apply -f pool.yaml
cd ..

cd prometheus-operator
kubectl apply -f namespace-monitoring.yaml
kubectl apply -f prometheus-operator.yaml
kubectl apply -f .
cd ..

cd kube-prometheus
kubectl -n monitoring create secret generic alertmanager-main --from-file=alertmanager.yaml
kubectl apply -f .
cd ..

cd manifests
kubectl apply -f .
cd ..

cd traefik-consul
kubectl apply -f .
cd ..

cd traefik-admin
kubectl apply -f .
cd ..

cd traefik-app
kubectl apply -f .
cd ..

cd monitoring
kubectl apply -f .
cd ..

kubectl apply -f cm-adapter-serving-certs.yaml -n monitoring

cd custom-metric
kubectl apply -f .
cd ..

# cd kiam
# kubectl create secret generic kiam-server-tls -n kube-system \
#   --from-file=ca.pem \
#   --from-file=server.pem \
#   --from-file=server-key.pem

# kubectl create secret generic kiam-agent-tls -n kube-system \
#   --from-file=ca.pem \
#   --from-file=agent.pem \
#   --from-file=agent-key.pem

# kubectl apply -f .
# cd ..

helm init --service-account tiller
