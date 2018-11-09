# sandbox-aws

This project is my AWS sandbox.

I'm using it to test Kubernetes on AWS.

Some layers folders in "IaC" are used to create:

- create VPC and networking
- create & configure k8s
- send logs to an AWS ESaaS
- monitoring by Prometheus
- IngressController by Traefik
- Custom Metrics

Another folder "namespace" are used to create some configurated namespace and get one kubeconfig file for CI/CD usage.

And the other one is an app test: "exercice3". It's just an webservice. See "app test" below.

## IaC

### Prerequisite

Connect to your aws account:

```language-bash
#!/usr/bin/env bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_STS AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SECURITY_TOKEN AWS_SESSION_TOKEN
export USERNAME=terraform
export AWS_DEFAULT_REGION=eu-west-1
export AWS_ACCESS_KEY_ID=***
export AWS_SECRET_ACCESS_KEY=***
export ROLE_NAME=EC2TerraformRole
export ACCOUNT_ARN=arn:aws:iam::***
export MFA_CODE=$1
AWS_STS=($(aws sts assume-role --role-arn $ACCOUNT_ARN:role/$ROLE_NAME --serial-number $ACCOUNT_ARN:mfa/$USERNAME --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken,Credentials.Expiration]' --output text --token-code $MFA_CODE --role-session-name $ROLE_NAME))
export AWS_ACCESS_KEY_ID=${AWS_STS[0]}
export AWS_SECRET_ACCESS_KEY=${AWS_STS[1]}
export AWS_SECURITY_TOKEN=${AWS_STS[2]}
export AWS_SESSION_TOKEN=${AWS_STS[2]}
```

To use this project you have to install these software:

- jinja2-cli
- jq
- terraform
- kops

You have to create:

- a S3 bucket for Terraform tfstates
- a S3 bucket for Kops states
- a S3 bucket for your private Helm chart

## Create infrastructure

Please change environment variables in "./iac/create-all.sh"

```language-yaml
export PRIVATE_DNS_ZONE="slavayssiere.wescale"
export PUBLIC_DNS_ZONE="aws-wescale.slavayssiere.fr."
export KOPS_STATE_STORE=s3://wescale-slavayssiere-kops
export NAME_CLUSTER=test
```

and launch:

```language-bash
cd iac
./create-all.sh
```

### Test infrastructure

Connect to your bastion with SSH Key propagation:

```language-bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
ssh -A ec2-user@bastion.aws-wescale.slavayssiere.fr \
    -L 8080:admin-tools.slavayssiere.wescale:8080 \
    -L 8081:admin-tools.slavayssiere.wescale:80 \
    -L 6443:api.test.slavayssiere.wescale:443
```

For admin apps:

- IngressController : [Traefik WebUI](http://localhost:8080)
- Ceph Dashboard : [localhost:8081/](http://localhost:8081/)
- Prometheus : [localhost:8081/prometheus](http://localhost:8081/prometheus)
- Grafana : [localhost:8081/grafana](http://localhost:8081/grafana)
- Kibana : [localhost:8081/_plugin/kibana](http://localhost:8081/_plugin/kibana)

## Create namespace

Please change environment variables in "./namespace/create.sh"

```language-yaml
export NAME="exercice3"
```

create namespace :

```language-bash
cd namespace
./create.sh
ssh exercice3@bastion.aws-wescale.slavayssiere.fr \
    -L 6443:api.test.slavayssiere.wescale:443
```

connect to bastion:

```language-bash
ssh exercice3@bastion.aws-wescale.slavayssiere.fr \
    -L 6443:api.test.slavayssiere.wescale:443
```

### Test namespace

For dev apps:

- Prometheus : [/prometheus-exercice3](https://test-kubernetes.aws-wescale.slavayssiere.fr/prometheus-exercice3)
- Grafana : [/grafana-exercice3](https://test-kubernetes.aws-wescale.slavayssiere.fr/grafana-exercice3)

If your connected to bastion by ssh, you can list pods in your application namespace

```language-bash
KUBECONFIG=./namespace/kubeconfigs/exercice3-cicd.kubeconfig kubectl get pods
```

## Deploy app

create Helm chart:

```language-bash
helm package --version 0.1.0 ./exercice3
```

push chart to S3:

```language-bash
helm s3 push ./exercice3-0.1.0.tgz my-charts
```

connect to bastion:

```language-bash
ssh exercice3@bastion.aws-wescale.slavayssiere.fr \
    -L 6443:api.test.slavayssiere.wescale:443
```

create a "values.yaml" file:

```language-yaml
replicaCount: 3

image:
  repository: 549637939820.dkr.ecr.eu-west-1.amazonaws.com/webservice-test
  tag: 0.0.2
  pullPolicy: IfNotPresent
  livenesspath: "/healthz"
  readynesspath: "/ready"
  containerport: 8080

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  annotations:
    traefik.ingress.kubernetes.io/rule-type: PathPrefixStrip
  path: /api
  hosts:
    - test-kubernetes.aws-wescale.slavayssiere.fr
  tls: []
  labels:
    traffic-type: external

resources:
  limits:
    memory: "40Mi"
    cpu: "20m"
  requests:
    memory: "40Mi"
    cpu: "20m"

nodeSelector: {}

tolerations: []

affinity: {}
```

and install chart:

```language-bash
helm repo update
helm install --name test my-charts/exercice3 -f values.yaml --version 0.1.0
```

### Test app

You can see the result of previous deployment with:

```language-bash
curl https://test-kubernetes.aws-wescale.slavayssiere.fr/api/facture
curl https://test-kubernetes.aws-wescale.slavayssiere.fr/api/client
curl https://test-kubernetes.aws-wescale.slavayssiere.fr/api/ips
...
```

or see your monitoring:

- Prometheus : [/prometheus-exercice3](https://test-kubernetes.aws-wescale.slavayssiere.fr/prometheus-exercice3)
- Grafana : [/grafana-exercice3](https://test-kubernetes.aws-wescale.slavayssiere.fr/grafana-exercice3)

## Delete infrastructure

```language-bash
cd iac
./delete-all.sh
```
